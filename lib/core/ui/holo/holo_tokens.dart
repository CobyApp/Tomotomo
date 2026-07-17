import 'package:flutter/material.dart';

/// Tomotomo's soft holographic palette.
///
/// Accent colors stay playful, while surfaces and borders remain quiet enough
/// for long chat and study sessions.
abstract final class Holo {
  static const pink = Color(0xFFFF4FA3);
  static const cyan = Color(0xFF35C8E8);
  static const lemon = Color(0xFFFFD84D);
  static const lilac = Color(0xFFB38CFF);
  static const inkPlum = Color(0xFF35283A);
  static const inkPlumSoft = Color(0xFF746779);
  static const surface = Color(0xFFFCF7FC);
  static const surfaceCard = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF6EFF7);
  static const border = Color(0x244F3156);

  /// Primary holographic sweep for buttons/chips/rings.
  static const holoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, lilac, cyan],
  );

  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF0FB), Color(0xFFF5EEFF), Color(0xFFEAF8FF)],
  );

  static const glitchR = pink;
  static const glitchG = cyan;
  static const glitchB = lemon;

  static List<BoxShadow> get cardShadow => const [
    BoxShadow(color: Color(0x124A2D50), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static List<BoxShadow> get floatingShadow => const [
    BoxShadow(color: Color(0x1A4A2D50), blurRadius: 28, offset: Offset(0, 12)),
  ];
}
