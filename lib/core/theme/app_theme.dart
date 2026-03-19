import 'package:flutter/material.dart';
import 'chat_theme_data.dart';

/// Centralized app theme. Single place to change look and feel.
class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Pretendard';
  static const Color seedColor = Color(0xFF6A3EA1);
  static const Color scaffoldBackground = Color(0xFFF8F9FA);

  static Color _parseAccent(String? hex) {
    if (hex == null || hex.isEmpty) return seedColor;
    String s = hex.startsWith('#') ? hex.substring(1) : hex;
    if (s.length == 6) s = 'FF$s';
    return Color(int.parse(s, radix: 16));
  }

  /// Builds theme with optional user overrides (from Supabase themes).
  static ThemeData buildWithOverrides(
    ThemeData base,
    {String? accent, String? chatBubbleUser, String? chatBubbleBot, String? chatBg}
  ) {
    final seed = accent != null && accent.isNotEmpty ? _parseAccent(accent) : null;
    return base.copyWith(
      colorScheme: seed != null
          ? ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light)
          : null,
      extensions: [
        ChatThemeData.fromUserTheme(
          chatBubbleUser: chatBubbleUser,
          chatBubbleBot: chatBubbleBot,
          chatBg: chatBg,
        ),
      ],
    );
  }

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: scaffoldBackground,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontFamily: fontFamily,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: fontFamily),
          displayMedium: TextStyle(fontFamily: fontFamily),
          displaySmall: TextStyle(fontFamily: fontFamily),
          headlineLarge: TextStyle(fontFamily: fontFamily),
          headlineMedium: TextStyle(fontFamily: fontFamily),
          headlineSmall: TextStyle(fontFamily: fontFamily),
          titleLarge: TextStyle(fontFamily: fontFamily),
          titleMedium: TextStyle(fontFamily: fontFamily),
          titleSmall: TextStyle(fontFamily: fontFamily),
          bodyLarge: TextStyle(fontFamily: fontFamily),
          bodyMedium: TextStyle(fontFamily: fontFamily),
          bodySmall: TextStyle(fontFamily: fontFamily),
          labelLarge: TextStyle(fontFamily: fontFamily),
          labelMedium: TextStyle(fontFamily: fontFamily),
          labelSmall: TextStyle(fontFamily: fontFamily),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          contentTextStyle: TextStyle(fontFamily: fontFamily),
        ),
        extensions: const [ChatThemeData()],
      );
}
