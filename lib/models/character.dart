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
  final String name;
  final String nameKanji;
  final String nameRomaji;
  final int age;
  final String schoolYear;
  final List<CharacterTrait> traits;
  final List<CharacterInterest> interests;
  final String speechStyle;
  final Color primaryColor;
  final Color secondaryColor;
  final String imageUrl;
  
  // 외형 관련
  final String hairStyle;
  final String hairColor;
  final String eyeColor;
  final String outfit;
  final List<String> accessories;
  
  // 대화 스타일 관련
  final String selfReference;
  final List<String> commonPhrases;
  final Map<String, List<String>> emotionalResponses;
  
  // 다국어 지원
  final Map<String, String> names;  // 각 언어별 이름
  final Map<String, String> descriptions;  // 각 언어별 설명
  final Map<String, String> personalities;  // 각 언어별 성격 설명
  final Map<String, String> chatStyles;  // 각 언어별 대화 스타일
  final Map<String, String> firstMessages;  // 각 언어별 첫 메시지

  const Character({
    required this.id,
    required this.name,
    required this.nameKanji,
    required this.nameRomaji,
    required this.age,
    required this.schoolYear,
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
    required this.names,
    required this.descriptions,
    required this.personalities,
    required this.chatStyles,
    required this.firstMessages,
  });

  String getName(String languageCode) => names[languageCode] ?? names['ko'] ?? name;
  String getDescription(String languageCode) => descriptions[languageCode] ?? descriptions['ko'] ?? '';
  String getPersonality(String languageCode) => personalities[languageCode] ?? personalities['ko'] ?? '';
  String getChatStyle(String languageCode) => chatStyles[languageCode] ?? chatStyles['ko'] ?? '';
  String getFirstMessage(String languageCode) => firstMessages[languageCode] ?? firstMessages['ko'] ?? '';

  String get displayImageUrl => imageUrl;
} 