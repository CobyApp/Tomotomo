import 'package:flutter/material.dart';

class Character {
  final String id;
  final Map<String, String> names;  // 언어별 이름
  final String imageUrl;
  final Color primaryColor;
  final Map<String, String> descriptions;  // 언어별 설명
  final Map<String, String> personalities;  // 언어별 성격 설명
  final Map<String, String> firstMessages;  // 언어별 첫 메시지
  final Map<String, String> chatStyles;  // 추가

  Character({
    required this.id,
    required this.names,
    required this.imageUrl,
    required this.primaryColor,
    required this.descriptions,
    required this.personalities,
    required this.firstMessages,
    required this.chatStyles,  // 추가
  });

  String getName(String languageCode) => names[languageCode] ?? names['ko'] ?? '';
  String getDescription(String languageCode) => descriptions[languageCode] ?? descriptions['ko'] ?? '';
  String getPersonality(String languageCode) => personalities[languageCode] ?? personalities['ko'] ?? '';
  String getFirstMessage(String languageCode) => firstMessages[languageCode] ?? firstMessages['ko'] ?? '';
  String getChatStyle(String languageCode) => chatStyles[languageCode] ?? chatStyles['ko'] ?? '';  // 추가

  // 이미지 URL이 유효하지 않을 때 사용할 기본 이미지
  static const String defaultImageUrl = 'assets/images/characters/default_avatar.png';

  // 이미지 URL getter 추가
  String get displayImageUrl => imageUrl.isNotEmpty ? imageUrl : defaultImageUrl;
} 