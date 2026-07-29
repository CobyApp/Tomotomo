import 'package:flutter/material.dart';

import '../../core/locale/languages.dart';
import 'character_record.dart';

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

  /// The friend's language, one of [kSupportedLanguages].
  final String _friendLanguageRaw;

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
    required String friendLanguage,
    this.omitSecondaryDisplayName = false,
  }) : _friendLanguageRaw = friendLanguage;

  String get displayImageUrl => imageUrl;


  /// The language the friend speaks and replies in.
  ///
  /// Required at construction rather than defaulted: the old fallback silently
  /// answered 'ja' for anything it could not derive, and the legacy fields it
  /// derived from (koreanNationalPersona, tutorLocale) no longer had a single
  /// production caller.
  String get friendLanguage => normalizeLang(_friendLanguageRaw);

  /// True when the friend speaks Korean.
  bool get koreanNationalPersona => friendLanguage == 'ko';

  /// Notebook segment for vocabulary [+] saves: the friend language's script.
  String get defaultNotebookLangForVocabSave => friendLanguage;

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
  /// The friend speaks [CharacterRecord.language]; the language its study notes
  /// explain in is the learner's app language, decided by the prompt builder —
  /// not something this record knows.
  static Character fromRecord(CharacterRecord r) {
    final image = r.avatarUrl ?? '';
    final descParts = <String>[
      if (r.tagline != null && r.tagline!.trim().isNotEmpty) r.tagline!.trim(),
      if (r.speechStyle != null && r.speechStyle!.trim().isNotEmpty)
        r.speechStyle!.trim(),
    ];

    // A custom friend has one name, whatever language it is in, so every name
    // slot gets it — [omitSecondaryDisplayName] hides the bilingual subtitle.
    final displayName = r.name.trim();

    return Character(
      id: r.id,
      name: displayName,
      nameJp: displayName,
      nameKanji: displayName,
      level: r.level,
      tagline: r.tagline?.trim() ?? '',
      description: descParts.isEmpty ? '' : descParts.join('\n'),
      age: 0,
      schoolYear: '',
      // These three reach the model as "Role:", "Personality:" and "Interests:".
      // They used to assert which scripts to use ("말풍선 한국어, 단어 뜻 일본어"),
      // which contradicted the reply/explanation languages the prompt states
      // right below — and was simply false for an English or Chinese friend.
      // Left empty so the builder supplies its own neutral defaults.
      occupation: '',
      traits: const [],
      interests: const [],
      speechStyle: r.speechStyle ?? '',
      primaryColor: const Color(0xFF6A3EA1),
      secondaryColor: const Color(0xFFF0E6FF),
      hairStyle: '-',
      hairColor: '-',
      eyeColor: '-',
      outfit: '-',
      accessories: [],
      selfReference: displayName,
      commonPhrases: [],
      emotionalResponses: {},
      imageUrl: image,
      imagePath: image,
      friendLanguage: r.language,
      omitSecondaryDisplayName: true,
    );
  }


}
