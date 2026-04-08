import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/x_profile/x_profile_reader.dart';

/// Suggested fields for a custom tutor, from profile text (e.g. X reader output).
class CelebrityPersonaSuggestion {
  const CelebrityPersonaSuggestion({
    required this.name,
    this.nameSecondary,
    this.speechStyle,
    required this.language,
  });

  final String name;
  final String? nameSecondary;
  final String? speechStyle;
  /// `ja` or `ko`
  final String language;
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

  /// Normalize [xOrTwitterUrl], fetch readable text, then ask Gemini for JSON fields.
  Future<CelebrityPersonaSuggestion> suggestFromXProfileUrl(String xOrTwitterUrl) async {
    final canonical = XProfileReader.normalizeXUrl(xOrTwitterUrl);
    if (canonical == null) {
      throw FormatException('Invalid X (Twitter) URL');
    }
    final text = await _reader.fetchReadableText(canonical);
    return suggestFromProfileText(text, sourceHint: canonical);
  }

  /// When crawling fails, user can paste bio + sample posts as plain text.
  Future<CelebrityPersonaSuggestion> suggestFromProfileText(String rawText, {String? sourceHint}) async {
    final trimmed = rawText.trim();
    if (trimmed.length < 20) {
      throw Exception('Text too short. Paste more profile content.');
    }
    _ensureApiKey();
    final model = GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.35,
        maxOutputTokens: 1024,
        responseMimeType: 'application/json',
      ),
      systemInstruction: Content.system(
        'You help build a fictional language-tutor persona for a Japanese/Korean learning chat app. '
        'The user may paste public social profile text. Output JSON only with keys: '
        'name (string, primary display name for the tutor), '
        'name_secondary (string or null, other script e.g. Hangul reading), '
        'speech_style (string, memo for the AI: tone, slang, particles, emoji habits, sentence endings; '
        'this is a stylized template for educational roleplay, not factual claims about real people), '
        'language (string, exactly "ja" if the persona mainly uses Japanese, else "ko" for Korean). '
        'Never claim you verified real identity. If input is noisy, infer best-effort from handles and fragments.',
      ),
    );
    final hint = sourceHint != null ? '\nSource URL hint: $sourceHint\n' : '';
    final prompt = '$hint---\n$trimmed\n---';
    final res = await model.generateContent([Content.text(prompt)]);
    final t = res.text?.trim();
    if (t == null || t.isEmpty) {
      throw Exception('Empty AI response');
    }
    final map = jsonDecode(t) as Map<String, dynamic>;
    final name = (map['name'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      throw Exception('AI did not return a name');
    }
    final sec = map['name_secondary'] as String?;
    final speech = map['speech_style'] as String?;
    var lang = (map['language'] as String?)?.trim().toLowerCase() ?? 'ja';
    if (lang != 'ja' && lang != 'ko') {
      lang = 'ja';
    }
    return CelebrityPersonaSuggestion(
      name: name,
      nameSecondary: sec == null || sec.trim().isEmpty ? null : sec.trim(),
      speechStyle: speech == null || speech.trim().isEmpty ? null : speech.trim(),
      language: lang,
    );
  }
}
