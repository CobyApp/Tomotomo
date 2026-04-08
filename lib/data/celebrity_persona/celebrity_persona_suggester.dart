import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/x_profile/x_profile_reader.dart';
import '../repositories/gemini_retry.dart';

/// Suggested fields for a custom tutor from X / pasted profile text.
class CelebrityPersonaSuggestion {
  const CelebrityPersonaSuggestion({
    required this.name,
    this.nameSecondary,
    this.tagline,
    this.speechStyle,
    required this.language,
    this.avatarUrl,
  });

  /// Primary display name for [language] mode (JA tutor → Japanese line; KO tutor → Korean).
  final String name;
  final String? nameSecondary;
  /// ~20 characters for list subtitle under the name (DB `tagline`).
  final String? tagline;
  /// Bio + tone instructions for the AI (stored in DB `speech_style`).
  final String? speechStyle;
  /// `ja` or `ko`
  final String language;
  /// HTTPS avatar URL when safely extracted (e.g. pbs.twimg.com).
  final String? avatarUrl;
}

/// Uses Gemini to turn raw profile text into tutor fields (fictional learning persona template).
class CelebrityPersonaSuggester {
  CelebrityPersonaSuggester({String? apiKey, String? model}) : _apiKeyOverride = apiKey, _modelOverride = model;

  final String? _apiKeyOverride;
  final String? _modelOverride;

  final XProfileReader _reader = XProfileReader();

  static String? _env(String key) {
    if (!dotenv.isInitialized) return null;
    final v = dotenv.env[key];
    if (v == null || v.isEmpty) return null;
    return v;
  }

  String get _apiKey => (_apiKeyOverride ?? _env('GEMINI_API_KEY') ?? '').trim();
  String get _modelName => (_modelOverride ?? _env('GEMINI_MODEL') ?? 'gemini-2.5-flash-lite').trim();

  void _ensureApiKey() {
    if (_apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not set');
    }
  }

  static final Schema _personaJsonSchema = Schema.object(
    properties: {
      'name_ja': Schema.string(
        nullable: true,
        description:
            'Japanese-script display name (漢字・ひらがな・カタカナ). Null or empty if unknown.',
      ),
      'name_ko': Schema.string(
        nullable: true,
        description: 'Hangul name. Null or empty if unknown.',
      ),
      'language': Schema.enumString(
        enumValues: ['ja', 'ko'],
        description: 'ja if the persona mainly uses Japanese; ko if mainly Korean.',
      ),
      'bio': Schema.string(
        description:
            '2–5 short sentences: neutral intro for the tutor (paraphrase; do not paste long copyrighted text verbatim).',
      ),
      'tagline': Schema.string(
        description:
            'Single-line public self-intro for list UI under the name: about 18–24 characters (count characters in the persona language, ja or ko per language). Paraphrase from bio; warm and concise; no hashtags, no newlines, no @handles.',
      ),
      'speech_style': Schema.string(
        description:
            'Concise instructions for the AI: sentence endings (ですます/だね/반말), politeness, emoji habits, first-person (僕/俺/私/나), dialect, tone.',
      ),
      'profile_image_url': Schema.string(
        nullable: true,
        description:
            'If the input contains a clear https://pbs.twimg.com/profile_images/... URL, copy it exactly; else null.',
      ),
    },
    requiredProperties: ['language', 'bio', 'tagline', 'speech_style'],
  );

  static String? _handleFromCanonicalUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final u = Uri.tryParse(url);
    final segs = u?.pathSegments.where((e) => e.isNotEmpty).toList() ?? [];
    if (segs.isEmpty) return null;
    final h = segs.first;
    if (h == 'i' || h == 'intent') return null;
    return h.startsWith('@') ? h.substring(1) : h;
  }

  static bool _isAllowedAvatarUrl(String url) {
    final u = Uri.tryParse(url.trim());
    if (u == null || u.scheme != 'https') return false;
    final h = u.host.toLowerCase();
    return h == 'pbs.twimg.com' || h == 'abs.twimg.com' || h.endsWith('.twimg.com');
  }

  static String? _pickAvatarUrl({
    required String? fromGemini,
    required String? fromPage,
    required String rawText,
  }) {
    final fromText = XProfileReader.extractProfileImageUrlFromText(rawText);
    for (final c in [fromGemini, fromPage, fromText]) {
      final s = c?.trim();
      if (s != null && s.isNotEmpty && _isAllowedAvatarUrl(s)) return s;
    }
    return null;
  }

  static String? _nonEmpty(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  /// Keeps list subtitle short (Unicode-safe).
  static String _clampTagline(String? raw, {int maxChars = 28}) {
    var t = raw?.trim().replaceAll(RegExp(r'[\r\n#]'), ' ') ?? '';
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isEmpty) return '';
    final runes = t.runes;
    if (runes.length <= maxChars) return t;
    return '${String.fromCharCodes(runes.take(maxChars - 1))}…';
  }

  static String _composeSpeechStyle({
    required String language,
    required String bio,
    required String speechStyle,
  }) {
    final b = bio.trim();
    final s = speechStyle.trim();
    final buf = StringBuffer();
    if (language == 'ko') {
      if (b.isNotEmpty) {
        buf.writeln('【프로필·소개】');
        buf.writeln(b);
        buf.writeln();
      }
      buf.writeln('【말투·말하는 방식 (AI가 따를 것)】');
      buf.writeln(s.isNotEmpty ? s : '친근하고 자연스럽게 대화합니다.');
    } else {
      if (b.isNotEmpty) {
        buf.writeln('【プロフィール・紹介】');
        buf.writeln(b);
        buf.writeln();
      }
      buf.writeln('【口調・話し方（AIが従うこと）】');
      buf.writeln(s.isNotEmpty ? s : '親しみやすく自然に話します。');
    }
    return buf.toString().trim();
  }

  /// Normalize [xOrTwitterUrl], fetch readable text, then ask Gemini for JSON fields.
  Future<CelebrityPersonaSuggestion> suggestFromXProfileUrl(String xOrTwitterUrl) async {
    final canonical = XProfileReader.normalizeXUrl(xOrTwitterUrl);
    if (canonical == null) {
      throw FormatException('Invalid X (Twitter) URL');
    }
    final page = await _reader.fetchReadablePage(canonical);
    return _suggestFromRaw(
      page.text,
      sourceHint: canonical,
      pageImageUrl: page.profileImageUrl,
    );
  }

  /// When crawling fails, user can paste bio + sample posts as plain text.
  Future<CelebrityPersonaSuggestion> suggestFromProfileText(String rawText, {String? sourceHint}) async {
    return _suggestFromRaw(rawText.trim(), sourceHint: sourceHint, pageImageUrl: null);
  }

  Future<CelebrityPersonaSuggestion> _suggestFromRaw(
    String trimmed, {
    required String? sourceHint,
    required String? pageImageUrl,
  }) async {
    if (trimmed.length < 20) {
      throw Exception('Text too short. Paste more profile content.');
    }
    _ensureApiKey();

    final model = GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 2048,
        responseMimeType: 'application/json',
        responseSchema: _personaJsonSchema,
      ),
      systemInstruction: Content.system(
        'You map public social profile text into a fictional Japanese/Korean language-tutor persona for an educational chat app. '
        'Output must follow the JSON schema. Rules:\n'
        '- name_ja: Japanese writing only for that field; name_ko: Hangul only. If only one script appears in the input, fill that field and leave the other null.\n'
        '- language: ja if the person mainly posts in Japanese; ko if mainly Korean; if mixed, pick the dominant language for tutoring bubbles.\n'
        '- bio: short paraphrased persona intro (role, vibe, topics). No long quotes.\n'
        '- tagline: one line ~20 characters for UI list under the name (same language as tutoring bubbles). Not the long memo.\n'
        '- speech_style: actionable directives for the model (語尾, 敬語/タメ口, 一人称, emoji, 方言, Korean 반말/존댓말, etc.).\n'
        '- profile_image_url: only if a literal https://pbs.twimg.com/profile_images/... URL appears in the input; else null. Never invent URLs.\n'
        '- Do not claim real-world verification; this is a stylized template.',
      ),
    );

    final hint = sourceHint != null ? 'Source URL: $sourceHint\n' : '';
    final prompt =
        '$hint'
        'Extract tutor fields from the following text (may be markdown).\n\n'
        '---\n'
        '$trimmed\n'
        '---';

    final res = await withGeminiRetry(
      () => model.generateContent([Content.text(prompt)]),
      perAttemptTimeout: const Duration(seconds: 120),
    );
    final t = res.text?.trim();
    if (t == null || t.isEmpty) {
      throw Exception('Empty AI response');
    }

    final map = jsonDecode(t) as Map<String, dynamic>;
    var lang = (map['language'] as String?)?.trim().toLowerCase() ?? 'ja';
    if (lang != 'ja' && lang != 'ko') {
      lang = 'ja';
    }

    final nameJa = _nonEmpty(map['name_ja'] as String?);
    final nameKo = _nonEmpty(map['name_ko'] as String?);

    final handle = _handleFromCanonicalUrl(sourceHint);
    final fallback = handle != null && handle.isNotEmpty ? handle : 'ユーザー';

    late final String primary;
    late final String? secondary;
    if (lang == 'ja') {
      // DB: name = Japanese display, name_secondary = Korean when both exist.
      if (nameJa != null) {
        primary = nameJa;
        secondary = (nameKo != null && nameKo != nameJa) ? nameKo : null;
      } else if (nameKo != null) {
        primary = nameKo;
        secondary = null;
      } else {
        primary = fallback;
        secondary = null;
      }
    } else {
      // DB: name = Korean, name_secondary = Japanese when both exist.
      if (nameKo != null) {
        primary = nameKo;
        secondary = (nameJa != null && nameJa != nameKo) ? nameJa : null;
      } else if (nameJa != null) {
        primary = nameJa;
        secondary = null;
      } else {
        primary = fallback;
        secondary = null;
      }
    }

    final bio = (map['bio'] as String?)?.trim() ?? '';
    final speech = (map['speech_style'] as String?)?.trim() ?? '';
    final combinedStyle = _composeSpeechStyle(language: lang, bio: bio, speechStyle: speech);
    var line = _clampTagline(map['tagline'] as String?);
    if (line.isEmpty) {
      line = _clampTagline(bio.split(RegExp(r'[。．.!?\n]')).first);
    }

    final geminiImg = (map['profile_image_url'] as String?)?.trim();
    final avatar = _pickAvatarUrl(fromGemini: geminiImg, fromPage: pageImageUrl, rawText: trimmed);

    return CelebrityPersonaSuggestion(
      name: primary,
      nameSecondary: secondary,
      tagline: line.isEmpty ? null : line,
      speechStyle: combinedStyle,
      language: lang,
      avatarUrl: avatar,
    );
  }
}
