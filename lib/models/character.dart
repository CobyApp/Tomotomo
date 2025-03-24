import 'package:flutter/material.dart';

class Character {
  final String id;
  final Map<String, String> names;  // 언어별 이름
  final String imageUrl;
  final Color primaryColor;
  final Map<String, String> descriptions;  // 언어별 설명
  final Map<String, String> personalities;  // 언어별 성격 설명
  final Map<String, String> firstMessages;  // 언어별 첫 메시지

  Character({
    required this.id,
    required this.names,
    required this.imageUrl,
    required this.primaryColor,
    required this.descriptions,
    required this.personalities,
    required this.firstMessages,
  });

  String getName(String languageCode) => names[languageCode] ?? names['ko'] ?? '';
  String getDescription(String languageCode) => descriptions[languageCode] ?? descriptions['ko'] ?? '';
  String getPersonality(String languageCode) => personalities[languageCode] ?? personalities['ko'] ?? '';
  String getFirstMessage(String languageCode) => firstMessages[languageCode] ?? firstMessages['ko'] ?? '';
} 