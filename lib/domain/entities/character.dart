import 'package:flutter/material.dart';

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

  const Character({
    required this.id,
    required this.name,
    required this.nameJp,
    required this.nameKanji,
    required this.level,
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
  });

  String get displayImageUrl => imageUrl;

  bool get hasAvatar => imagePath.isNotEmpty;

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
    );
  }

  /// Builds a Character for chat from a Supabase custom character record.
  static Character fromRecord(CharacterRecord r) {
    final lang = r.language == 'ja' ? '일본어' : '한국어';
    final image = r.avatarUrl ?? '';
    final descParts = <String>[
      if (r.tagline != null && r.tagline!.trim().isNotEmpty) r.tagline!.trim(),
      if (r.speechStyle != null && r.speechStyle!.trim().isNotEmpty) r.speechStyle!.trim(),
    ];
    return Character(
      id: r.id,
      name: r.name,
      nameJp: r.nameSecondary ?? r.name,
      nameKanji: r.nameSecondary ?? r.name,
      level: lang,
      description: descParts.isEmpty ? '' : descParts.join('\n'),
      age: 0,
      schoolYear: '',
      occupation: lang == '일본어' ? '일본어 학습 도우미' : '한국어 학습 도우미',
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
      selfReference: r.nameSecondary ?? r.name,
      commonPhrases: [],
      emotionalResponses: {},
      imageUrl: image,
      imagePath: image,
      isDirectMessage: false,
      directMessageRoomId: null,
    );
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as String,
      name: json['name'] as String,
      nameJp: json['nameJp'] as String,
      nameKanji: json['nameKanji'] as String,
      level: json['level'] as String,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameJp': nameJp,
      'nameKanji': nameKanji,
      'level': level,
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
    };
  }
}
