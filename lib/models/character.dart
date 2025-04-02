import 'package:flutter/material.dart';

class CharacterTrait {
  final String trait;
  final double weight; // 성격 특성의 가중치 (0.0 ~ 1.0)

  const CharacterTrait(this.trait, this.weight);
}

class CharacterInterest {
  final String category;
  final List<String> items;
  final double enthusiasm; // 관심도 (0.0 ~ 1.0)

  const CharacterInterest({
    required this.category,
    required this.items,
    this.enthusiasm = 1.0,
  });
}

class Character {
  final String id;
  final String name;  // 한글 이름
  final String nameJp;  // 히라가나/가타카나
  final String nameKanji;  // 한자
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
  });

  String get displayImageUrl => imageUrl;

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
      traits: (json['traits'] as List).map((e) => CharacterTrait(e['trait'] as String, e['weight'] as double)).toList(),
      interests: (json['interests'] as List).map((e) => CharacterInterest(category: e['category'] as String, items: e['items'] as List<String>)).toList(),
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
      emotionalResponses: json['emotionalResponses'] as Map<String, List<String>>,
      imageUrl: json['imageUrl'] as String,
      imagePath: json['imagePath'] as String,
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
      'primaryColor': primaryColor.value.toString(),
      'secondaryColor': secondaryColor.value.toString(),
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
    };
  }
} 