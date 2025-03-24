import 'package:flutter/material.dart';

class Character {
  final String id;
  final String name;
  final String imageUrl;
  final Color primaryColor;
  final String description;
  final String personality;
  final String firstMessage;

  Character({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.primaryColor,
    required this.description,
    required this.personality,
    required this.firstMessage,
  });
} 