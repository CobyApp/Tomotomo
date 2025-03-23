import 'package:flutter/material.dart';

class Member {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final String personalityPrompt; // 멤버별 AI 성격을 정의하는 프롬프트
  final Color primaryColor; // 멤버별 테마 색상

  Member({
    required this.id,
    required this.name, 
    required this.imageUrl,
    required this.description,
    required this.personalityPrompt,
    required this.primaryColor,
  });
} 