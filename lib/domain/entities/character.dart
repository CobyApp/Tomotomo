import 'package:flutter/material.dart';

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
  /// Short one-line subtitle for lists (~20 chars); empty for DM.
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

  /// Human-to-human chat (no AI). When true, [directMessageRoomId] must be set.
  final bool isDirectMessage;
  final String? directMessageRoomId;

  /// `ko`: vocabulary meanings in Korean for Japanese dialogue. `ja`: full Japanese immersion (meanings in Japanese).
  final String tutorLocale;

  /// Korean-national friend: [ChatMessage.content] in Korean; vocabulary highlights **Korean** phrases (gloss in Japanese).
  final bool koreanNationalPersona;

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
    this.isDirectMessage = false,
    this.directMessageRoomId,
    this.tutorLocale = 'ko',
    this.koreanNationalPersona = false,
    this.omitSecondaryDisplayName = false,
  });

  String get displayImageUrl => imageUrl;

  /// AI JSON: Korean vocabulary meanings (Japanese dialogue).
  bool get expectsKoreanStudyNotes =>
      !isDirectMessage && !koreanNationalPersona && tutorLocale != 'ja';

  /// AI JSON: Japanese glosses (Korean dialogue or immersion).
  bool get expectsJapaneseStudyNotes =>
      !isDirectMessage && (koreanNationalPersona || tutorLocale == 'ja');

  /// Prefer Pretendard / Hangul-friendly font for [ChatMessage.content] in the expression sheet.
  bool get assistantMessagePrefersHangulFont => isDirectMessage || koreanNationalPersona;

  /// Notebook tab for vocabulary [+] saves: **script of the headword** — Korean words → `ko`, Japanese → `ja`.
  String get defaultNotebookLangForVocabSave {
    if (tutorLocale == 'ja') return 'ja';
    if (koreanNationalPersona) return 'ko';
    return 'ja';
  }

  /// How to read `vocabulary[].*` meaning fields from AI/DB JSON for this persona.
  VocabularyMeaningPickMode get vocabularyMeaningPickMode {
    if (isDirectMessage) return VocabularyMeaningPickMode.neutral;
    if (tutorLocale == 'ja') return VocabularyMeaningPickMode.neutral;
    if (koreanNationalPersona) return VocabularyMeaningPickMode.preferJapaneseGloss;
    return VocabularyMeaningPickMode.preferKoreanGloss;
  }

  bool get hasAvatar => imagePath.isNotEmpty;

  /// Korean-national / DM: large line is Korean (or display name). Japanese persona: large line is Japanese ([nameJp]).
  bool get _showsKoreanNamePrimary => isDirectMessage || koreanNationalPersona;

  /// Primary name line for UI (chat header, list tiles, etc.).
  String get displayNamePrimary {
    if (isDirectMessage) return name;
    return _showsKoreanNamePrimary ? name : nameJp;
  }

  /// Smaller bilingual subtitle; empty when there is no second script or it matches [displayNamePrimary].
  String get displayNameSecondary {
    if (omitSecondaryDisplayName) return '';
    if (isDirectMessage) {
      final s = nameJp.trim();
      if (s.isEmpty || s == name) return '';
      return s;
    }
    final other = (_showsKoreanNamePrimary ? nameJp : name).trim();
    if (other.isEmpty || other == displayNamePrimary) return '';
    return other;
  }

  /// List-row titles for a Supabase `characters` row (same rules as [fromRecord] + [displayNamePrimary]).
  static ({String primary, String secondary}) bilingualChatTitlesFromCharacterDb({
    required String language,
    required String dbName,
    String? dbNameSecondary,
  }) {
    final isJaPersona = language == 'ja';
    final String nameKoLine;
    final String nameJaLine;
    if (isJaPersona) {
      final ja = dbName.trim();
      final ko = dbNameSecondary?.trim();
      nameJaLine = ja;
      nameKoLine = (ko != null && ko.isNotEmpty) ? ko : ja;
    } else {
      final ko = dbName.trim();
      final jp = dbNameSecondary?.trim();
      nameKoLine = ko;
      nameJaLine = (jp != null && jp.isNotEmpty) ? jp : ko;
    }
    final koreanNational = !isJaPersona;
    final primary = koreanNational ? nameKoLine : nameJaLine;
    final other = koreanNational ? nameJaLine : nameKoLine;
    final secondary = (other.isEmpty || other == primary) ? '' : other;
    return (primary: primary, secondary: secondary);
  }

  bool get isNetworkImage => imagePath.startsWith('http');

  ImageProvider get imageProvider =>
      isNetworkImage ? NetworkImage(imagePath) : AssetImage(imagePath) as ImageProvider;

  /// DM with a friend; uses [peerUserId] as [id] for stability.
  static Character forDirectMessage({
    required String peerUserId,
    required String roomId,
    required String displayName,
    String? email,
    String? avatarUrl,
  }) {
    final image = (avatarUrl != null && avatarUrl.trim().isNotEmpty) ? avatarUrl.trim() : '';
    return Character(
      id: peerUserId,
      name: displayName,
      nameJp: email ?? displayName,
      nameKanji: displayName,
      level: '—',
      tagline: '',
      description: '',
      age: 0,
      schoolYear: '',
      occupation: '',
      traits: const [CharacterTrait('friend', 1.0)],
      interests: const [CharacterInterest(category: 'chat', items: ['direct'])],
      speechStyle: '',
      primaryColor: const Color(0xFF2E7D32),
      secondaryColor: const Color(0xFFE8F5E9),
      hairStyle: '-',
      hairColor: '-',
      eyeColor: '-',
      outfit: '-',
      accessories: const [],
      selfReference: displayName,
      commonPhrases: const [],
      emotionalResponses: const {},
      imageUrl: image,
      imagePath: image,
      isDirectMessage: true,
      directMessageRoomId: roomId,
      tutorLocale: 'ko',
      koreanNationalPersona: false,
      omitSecondaryDisplayName: false,
    );
  }

  /// Builds a Character for chat from a Supabase custom character record.
  ///
  /// [CharacterRecord.language]: `ja` → Japanese-speaking persona, Korean glosses on vocabulary in JSON.
  /// `ko` → Korean-speaking persona (friend), Japanese glosses on vocabulary in JSON.
  static Character fromRecord(CharacterRecord r) {
    final isJaPersona = r.language == 'ja';
    final levelLabel = isJaPersona ? '일본어' : '한국어';
    final image = r.avatarUrl ?? '';
    final descParts = <String>[
      if (r.tagline != null && r.tagline!.trim().isNotEmpty) r.tagline!.trim(),
      if (r.speechStyle != null && r.speechStyle!.trim().isNotEmpty) r.speechStyle!.trim(),
    ];

    // Align with built-in [Character] rows: [name] = Korean-line label, [nameJp] = Japanese script.
    // DB for `ja` characters: primary [name] is Japanese; [name_secondary] is Korean (optional).
    final String nameKoLine;
    final String nameJaLine;
    final String nameKanjiVal;
    final String selfRef;
    if (isJaPersona) {
      final ja = r.name.trim();
      final ko = r.nameSecondary?.trim();
      nameJaLine = ja;
      nameKoLine = (ko != null && ko.isNotEmpty) ? ko : ja;
      nameKanjiVal = ja;
      selfRef = ja;
    } else {
      final ko = r.name.trim();
      final jp = r.nameSecondary?.trim();
      nameKoLine = ko;
      nameJaLine = (jp != null && jp.isNotEmpty) ? jp : ko;
      nameKanjiVal = nameJaLine;
      selfRef = nameJaLine;
    }

    return Character(
      id: r.id,
      name: nameKoLine,
      nameJp: nameJaLine,
      nameKanji: nameKanjiVal,
      level: levelLabel,
      tagline: r.tagline?.trim() ?? '',
      description: descParts.isEmpty ? '' : descParts.join('\n'),
      age: 0,
      schoolYear: '',
      occupation: isJaPersona
          ? '일본어 튜터 · 말풍선 일본어, 단어 뜻 한국어'
          : '한국어 튜터 · 말풍선 한국어, 단어 뜻 일본어',
      traits: const [CharacterTrait('친절함', 0.8)],
      interests: const [CharacterInterest(category: '언어', items: ['대화'])],
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
      isDirectMessage: false,
      directMessageRoomId: null,
      tutorLocale: 'ko',
      koreanNationalPersona: !isJaPersona,
      omitSecondaryDisplayName: false,
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
          .map((e) => CharacterTrait(e['trait'] as String, e['weight'] as double))
          .toList(),
      interests: (json['interests'] as List)
          .map((e) => CharacterInterest(
                category: e['category'] as String,
                items: e['items'] as List<String>,
              ))
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
      isDirectMessage: json['isDirectMessage'] as bool? ?? false,
      directMessageRoomId: json['directMessageRoomId'] as String?,
      tutorLocale: json['tutorLocale'] as String? ?? 'ko',
      koreanNationalPersona: json['koreanNationalPersona'] as bool? ?? false,
      omitSecondaryDisplayName: json['omitSecondaryDisplayName'] as bool? ?? false,
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
      'traits': traits.map((e) => {'trait': e.trait, 'weight': e.weight}).toList(),
      'interests': interests.map((e) => {'category': e.category, 'items': e.items}).toList(),
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
      'isDirectMessage': isDirectMessage,
      'directMessageRoomId': directMessageRoomId,
      'tutorLocale': tutorLocale,
      'koreanNationalPersona': koreanNationalPersona,
      'omitSecondaryDisplayName': omitSecondaryDisplayName,
    };
  }
}
