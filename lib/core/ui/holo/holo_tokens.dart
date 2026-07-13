import 'package:flutter/material.dart';

/// HOLO-KITSCH palette + surface/shape/shadow tokens. Single bright theme.
abstract final class Holo {
  static const pink = Color(0xFFFF2EC4);
  static const cyan = Color(0xFF17D6FF);
  static const lemon = Color(0xFFFFE600);
  static const lilac = Color(0xFFC8A2FF);
  static const inkPlum = Color(0xFF5A1550);
  static const inkPlumSoft = Color(0xFF9A5C8E);
  static const surface = Color(0xFFFFF4FC);
  static const surfaceCard = Color(0xFFFFFFFF);

  /// Primary holographic sweep for buttons/chips/rings.
  static const holoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, lilac, cyan],
  );

  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFE8FA), Color(0xFFE7F6FF)],
  );

  static const glitchR = pink;
  static const glitchG = cyan;
  static const glitchB = lemon;

  static List<BoxShadow> get cardShadow => const [
        BoxShadow(color: Color(0x22FF2EC4), blurRadius: 18, offset: Offset(0, 8)),
      ];
}
