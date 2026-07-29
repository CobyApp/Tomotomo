import 'dart:io';

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

  /// The friend's name, in the friend's own language. One name, not a
  /// Korean/Japanese pair: every screen showed the same single line, and the
  /// bilingual subtitle was switched off on every character that existed.
  final String name;
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

  const Character({
    required this.id,
    required this.name,
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
  }) : _friendLanguageRaw = friendLanguage;

  String get displayImageUrl => imageUrl;


  /// The language the friend speaks and replies in.
  ///
  /// Required at construction rather than defaulted: the old fallback silently
  /// answered 'ja' for anything it could not derive, and the legacy fields it
  /// derived from (koreanNationalPersona, tutorLocale) no longer had a single
  /// production caller.
  String get friendLanguage => normalizeLang(_friendLanguageRaw);

  /// Notebook segment for vocabulary [+] saves: the friend language's script.
  String get defaultNotebookLangForVocabSave => friendLanguage;

  bool get hasAvatar => imagePath.isNotEmpty;

  bool get isNetworkImage => imagePath.startsWith('http');

  /// True for a photo the user picked, which is stored as an absolute path under
  /// the app's Documents directory.
  bool get isFileImage => imagePath.startsWith('/');

  ImageProvider get imageProvider => isNetworkImage
      ? NetworkImage(imagePath)
      // A user-picked photo is a FILE, not a bundled asset. Without this branch
      // AssetImage was handed '/var/mobile/…/avatar_123.jpg' as a bundle key, so
      // every custom friend's photo was an empty frame in the chat header, in
      // every reply bubble and in the Chats row — and because hasAvatar is true
      // the person-glyph fallback never took over either. The Friends tab got it
      // right, which is why the photo appeared there and nowhere else.
      : isFileImage
      ? FileImage(File(imagePath))
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

    final displayName = r.name.trim();

    return Character(
      id: r.id,
      name: displayName,
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
    );
  }


}
