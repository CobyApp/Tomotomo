import 'package:flutter/material.dart';
import 'chat_theme_data.dart';

/// Centralized app theme — modern, clean chat-app aesthetic.
class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Pretendard';
  /// Refined indigo-violet (calmer than pure purple).
  static const Color seedColor = Color(0xFF5B4CE0);
  static const Color scaffoldBackground = Color(0xFFF0F2F5);

  static Color _parseAccent(String? hex) {
    if (hex == null || hex.isEmpty) return seedColor;
    String s = hex.startsWith('#') ? hex.substring(1) : hex;
    if (s.length == 6) s = 'FF$s';
    return Color(int.parse(s, radix: 16));
  }

  static ThemeData buildWithOverrides(
    ThemeData base, {
    String? accent,
    String? chatBubbleUser,
    String? chatBubbleBot,
    String? chatBg,
  }) {
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

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFE8EAED),
      surfaceContainerHigh: const Color(0xFFEEEFF2),
      surfaceContainer: const Color(0xFFF3F4F6),
      surfaceContainerLow: const Color(0xFFF7F8FA),
      surfaceContainerLowest: scaffoldBackground,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: scheme.onSurface,
          fontFamily: fontFamily,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        backgroundColor: scheme.surface,
        indicatorColor: seedColor.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? seedColor : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? seedColor : scheme.onSurfaceVariant,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: seedColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.65)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        focusElevation: 4,
        highlightElevation: 4,
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.45), thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        shadowColor: Colors.black26,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500),
      ),
      textTheme: TextTheme(
        displayLarge: const TextStyle(fontFamily: fontFamily),
        displayMedium: const TextStyle(fontFamily: fontFamily),
        displaySmall: const TextStyle(fontFamily: fontFamily),
        headlineLarge: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
        headlineMedium: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
        headlineSmall: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        titleLarge: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleMedium: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        titleSmall: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontFamily: fontFamily, height: 1.45),
        bodyMedium: const TextStyle(fontFamily: fontFamily, height: 1.45),
        bodySmall: const TextStyle(fontFamily: fontFamily, height: 1.35),
        labelLarge: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        labelMedium: const TextStyle(fontFamily: fontFamily),
        labelSmall: const TextStyle(fontFamily: fontFamily),
      ),
      extensions: const [ChatThemeData()],
    );
  }
}
