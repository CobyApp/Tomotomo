import 'package:flutter/material.dart';

import '../../core/locale/languages.dart';
import 'character_record.dart';
import 'chat_message.dart';

class CharacterTrait {
  final String trait;
  final double weight;

  const CharacterTrait(this.trait, this.weight);
}

class CharacterInterest {
  final String category;
  final List<String> items;
  final double enthusiasm;

  const CharacterInterest({
    required this.category,
    required this.items,
    this.enthusiasm = 1.0,
  });
}

class Character {
  final String id;
  final String name;
  final String nameJp;
  final String nameKanji;
  final String level;

  /// Short one-line subtitle for character lists.
  final String tagline;
  final String description;
  final int age;
  final String schoolYear;
  final String occupation;
  final List<CharacterTrait> traits;
  final List<CharacterInterest> interests;
  final String speechStyle;
  final Color primaryColor;
  final Color secondaryColor;
  final String hairStyle;
  final String hairColor;
  final String eyeColor;
  final String outfit;
  final List<String> accessories;
  final String selfReference;
  final List<String> commonPhrases;
  final Map<String, List<String>> emotionalResponses;
  final String imageUrl;
  final String imagePath;

  /// Legacy immersion hint; retained for backward compat. Derived from friendLanguage.
  final String tutorLocale;

  /// Explicit friend language when known (`ko`|`ja`|`en`|`zh`); else null → derive.
  final String? _friendLanguageRaw;

  /// Legacy flag; retained for backward compat.
  final bool _koreanNationalPersonaRaw;

  /// When true, [displayNameSecondary] is always empty (packaged default tutors).
  final bool omitSecondaryDisplayName;

  const Character({
    required this.id,
    required this.name,
    required this.nameJp,
    required this.nameKanji,
    required this.level,
    this.tagline = '',
    required this.description,
    required this.age,
    required this.schoolYear,
    required this.occupation,
    required this.traits,
    required this.interests,
    required this.speechStyle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.hairStyle,
    required this.hairColor,
    required this.eyeColor,
    required this.outfit,
    required this.accessories,
    required this.selfReference,
    required this.commonPhrases,
    required this.emotionalResponses,
    required this.imageUrl,
    required this.imagePath,
    this.tutorLocale = 'ko',
    String? friendLanguage,
    bool koreanNationalPersona = false,
    this.omitSecondaryDisplayName = false,
  })  : _friendLanguageRaw = friendLanguage,
        _koreanNationalPersonaRaw = koreanNationalPersona;

  String get displayImageUrl => imageUrl;

  /// AI JSON: Korean vocabulary meanings (Japanese dialogue).
  bool get expectsKoreanStudyNotes =>
      !koreanNationalPersona && tutorLocale != 'ja';

  /// AI JSON: Japanese glosses (Korean dialogue or immersion).
  bool get expectsJapaneseStudyNotes =>
      koreanNationalPersona || tutorLocale == 'ja';

  /// Prefer Pretendard / Hangul-friendly font for [ChatMessage.content] in the expression sheet.
  bool get assistantMessagePrefersHangulFont => koreanNationalPersona;

  /// The language the friend speaks and replies in. Explicit when set;
  /// otherwise migrated from legacy fields.
  String get friendLanguage {
    final raw = _friendLanguageRaw;
    if (raw != null && kSupportedLanguages.contains(normalizeLang(raw))) {
      return normalizeLang(raw);
    }
    // Legacy migration: the only two historical personas were the Korean friend
    // (koreanNationalPersona == true) and the Japanese friend (everything else,
    // including tutorLocale == 'ja'). Default to Japanese for that legacy case.
    if (_koreanNationalPersonaRaw) return 'ko';
    return 'ja';
  }

  /// Backward-compatible: true when the friend speaks Korean.
  bool get koreanNationalPersona => friendLanguage == 'ko';

  /// Notebook segment for vocabulary [+] saves: the friend language's script.
  String get defaultNotebookLangForVocabSave => friendLanguage;

  /// How to read `vocabulary[].*` meaning fields from AI/DB JSON for this persona.
  VocabularyMeaningPickMode get vocabularyMeaningPickMode {
    if (tutorLocale == 'ja') return VocabularyMeaningPickMode.neutral;
    if (koreanNationalPersona) {
      return VocabularyMeaningPickMode.preferJapaneseGloss;
    }
    return VocabularyMeaningPickMode.preferKoreanGloss;
  }

  bool get hasAvatar => imagePath.isNotEmpty;

  /// Korean persona: large line is Korean. Japanese persona: large line is Japanese.
  bool get _showsKoreanNamePrimary => koreanNationalPersona;

  /// Primary name line for UI (chat header, list tiles, etc.).
  String get displayNamePrimary {
    return _showsKoreanNamePrimary ? name : nameJp;
  }

  /// Smaller bilingual subtitle; empty when there is no second script or it matches [displayNamePrimary].
  String get displayNameSecondary {
    if (omitSecondaryDisplayName) return '';
    final other = (_showsKoreanNamePrimary ? nameJp : name).trim();
    if (other.isEmpty || other == displayNamePrimary) return '';
    return other;
  }

  bool get isNetworkImage => imagePath.startsWith('http');

  ImageProvider get imageProvider => isNetworkImage
      ? NetworkImage(imagePath)
      : AssetImage(imagePath) as ImageProvider;

  /// Builds a chat character from a locally stored custom character record.
  ///
  /// [CharacterRecord.language]: `ja` → Japanese-speaking persona, Korean glosses on vocabulary in JSON.
  /// `ko` → Korean-speaking persona (friend), Japanese glosses on vocabulary in JSON.
  static Character fromRecord(CharacterRecord r) {
    final isJaPersona = r.language == 'ja';
    final image = r.avatarUrl ?? '';
    final descParts = <String>[
      if (r.tagline != null && r.tagline!.trim().isNotEmpty) r.tagline!.trim(),
      if (r.speechStyle != null && r.speechStyle!.trim().isNotEmpty)
        r.speechStyle!.trim(),
    ];

    // Align with built-in [Character] rows: [name] = Korean-line label, [nameJp] = Japanese script.
    // DB for `ja` characters: primary [name] is Japanese; [name_secondary] is Korean (optional).
    final String nameKoLine;
    final String nameJaLine;
    final String nameKanjiVal;
    final String selfRef;
    final displayName = r.name.trim();
    nameJaLine = displayName;
    nameKoLine = displayName;
    nameKanjiVal = displayName;
    selfRef = displayName;

    return Character(
      id: r.id,
      name: nameKoLine,
      nameJp: nameJaLine,
      nameKanji: nameKanjiVal,
      level: r.level,
      tagline: r.tagline?.trim() ?? '',
      description: descParts.isEmpty ? '' : descParts.join('\n'),
      age: 0,
      schoolYear: '',
      occupation: isJaPersona
          ? '일본어 튜터 · 말풍선 일본어, 단어 뜻 한국어'
          : '한국어 튜터 · 말풍선 한국어, 단어 뜻 일본어',
      traits: const [CharacterTrait('친절함', 0.8)],
      interests: const [
        CharacterInterest(category: '언어', items: ['대화']),
      ],
      speechStyle: r.speechStyle ?? '친근하게 대화합니다.',
      primaryColor: const Color(0xFF6A3EA1),
      secondaryColor: const Color(0xFFF0E6FF),
      hairStyle: '-',
      hairColor: '-',
      eyeColor: '-',
      outfit: '-',
      accessories: [],
      selfReference: selfRef,
      commonPhrases: [],
      emotionalResponses: {},
      imageUrl: image,
      imagePath: image,
      tutorLocale: 'ko',
      friendLanguage: r.language,
      omitSecondaryDisplayName: true,
    );
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as String,
      name: json['name'] as String,
      nameJp: json['nameJp'] as String,
      nameKanji: json['nameKanji'] as String,
      level: json['level'] as String,
      tagline: json['tagline'] as String? ?? '',
      description: json['description'] as String,
      age: json['age'] as int,
      schoolYear: json['schoolYear'] as String,
      occupation: json['occupation'] as String,
      traits: (json['traits'] as List)
          .map(
            (e) => CharacterTrait(e['trait'] as String, e['weight'] as double),
          )
          .toList(),
      interests: (json['interests'] as List)
          .map(
            (e) => CharacterInterest(
              category: e['category'] as String,
              items: e['items'] as List<String>,
            ),
          )
          .toList(),
      speechStyle: json['speechStyle'] as String,
      primaryColor: Color(int.parse(json['primaryColor'] as String)),
      secondaryColor: Color(int.parse(json['secondaryColor'] as String)),
      hairStyle: json['hairStyle'] as String,
      hairColor: json['hairColor'] as String,
      eyeColor: json['eyeColor'] as String,
      outfit: json['outfit'] as String,
      accessories: json['accessories'] as List<String>,
      selfReference: json['selfReference'] as String,
      commonPhrases: json['commonPhrases'] as List<String>,
      emotionalResponses:
          json['emotionalResponses'] as Map<String, List<String>>,
      imageUrl: json['imageUrl'] as String,
      imagePath: json['imagePath'] as String,
      tutorLocale: json['tutorLocale'] as String? ?? 'ko',
      friendLanguage: json['friendLanguage'] as String?,
      koreanNationalPersona: json['koreanNationalPersona'] as bool? ?? false,
      omitSecondaryDisplayName:
          json['omitSecondaryDisplayName'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameJp': nameJp,
      'nameKanji': nameKanji,
      'level': level,
      'tagline': tagline,
      'description': description,
      'age': age,
      'schoolYear': schoolYear,
      'occupation': occupation,
      'traits': traits
          .map((e) => {'trait': e.trait, 'weight': e.weight})
          .toList(),
      'interests': interests
          .map((e) => {'category': e.category, 'items': e.items})
          .toList(),
      'speechStyle': speechStyle,
      'primaryColor': primaryColor.toARGB32().toString(),
      'secondaryColor': secondaryColor.toARGB32().toString(),
      'hairStyle': hairStyle,
      'hairColor': hairColor,
      'eyeColor': eyeColor,
      'outfit': outfit,
      'accessories': accessories,
      'selfReference': selfReference,
      'commonPhrases': commonPhrases,
      'emotionalResponses': emotionalResponses,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'tutorLocale': tutorLocale,
      'friendLanguage': friendLanguage,
      'koreanNationalPersona': koreanNationalPersona,
      'omitSecondaryDisplayName': omitSecondaryDisplayName,
    };
  }
}
