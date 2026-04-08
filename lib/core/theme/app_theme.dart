import 'package:flutter/material.dart';
import 'chat_theme_data.dart';

/// App-wide light theme: soft tinted shell (no flat grey), M3, ties to [ThemeNotifier] / user accent.
class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Pretendard';

  /// Default brand seed — soft rose pink, kawaii & friendly.
  static const Color seedColor = Color(0xFFFF6B9D);

  static Color parseAccentHex(String? hex) {
    if (hex == null || hex.isEmpty) return seedColor;
    String s = hex.startsWith('#') ? hex.substring(1) : hex;
    if (s.length == 6) s = 'FF$s';
    return Color(int.parse(s, radix: 16));
  }

  /// Top color for shell gradient (used by [MainShell]).
  static Color shellGradientTop(ColorScheme scheme) {
    return Color.alphaBlend(scheme.primary.withValues(alpha: 0.09), scheme.surface);
  }

  /// Bottom color for shell gradient.
  static Color shellGradientBottom(ColorScheme scheme) {
    return Color.alphaBlend(scheme.tertiary.withValues(alpha: 0.07), scheme.surface);
  }

  /// Full light theme; [seedColor] drives ColorScheme. Chat bubbles/bg from [chatExtension].
  static ThemeData buildLightTheme({
    Color? seedColor,
    ChatThemeData chatExtension = const ChatThemeData(),
  }) {
    final seed = seedColor ?? AppTheme.seedColor;
    const surface = Color(0xFFFFFEFE);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      surface: surface,
      surfaceContainerHighest: Color.alphaBlend(seed.withValues(alpha: 0.10), surface),
      surfaceContainerHigh: Color.alphaBlend(seed.withValues(alpha: 0.07), surface),
      surfaceContainer: Color.alphaBlend(seed.withValues(alpha: 0.055), surface),
      surfaceContainerLow: Color.alphaBlend(seed.withValues(alpha: 0.04), surface),
      surfaceContainerLowest: Color.alphaBlend(seed.withValues(alpha: 0.025), surface),
    );

    final scaffoldTint = Color.alphaBlend(seed.withValues(alpha: 0.045), surface);

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldTint,
      // InkSparkle uses a shader path that has triggered EXC_BAD_ACCESS on some iOS devices (Skia).
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          color: scheme.onSurface,
          fontFamily: fontFamily,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant.withValues(alpha: 0.85),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: seed.withValues(alpha: 0.14),
        ),
        labelStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, fontSize: 13),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        indicatorColor: seed.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fontFamily,
            fontSize: 11,
            letterSpacing: 0.2,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? seed : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? seed : scheme.onSurfaceVariant,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.40)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: seed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.55)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        focusElevation: 5,
        highlightElevation: 5,
        backgroundColor: seed,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.35),
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        elevation: 6,
        shadowColor: seed.withValues(alpha: 0.12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentTextStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.30)),
      ),
      textTheme: TextTheme(
        displayLarge: const TextStyle(fontFamily: fontFamily),
        displayMedium: const TextStyle(fontFamily: fontFamily),
        displaySmall: const TextStyle(fontFamily: fontFamily),
        headlineLarge: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w800),
        headlineMedium: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w800),
        headlineSmall: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
        titleLarge: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w800, letterSpacing: -0.4),
        titleMedium: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
        titleSmall: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontFamily: fontFamily, height: 1.45),
        bodyMedium: const TextStyle(fontFamily: fontFamily, height: 1.45),
        bodySmall: const TextStyle(fontFamily: fontFamily, height: 1.35),
        labelLarge: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
        labelMedium: const TextStyle(fontFamily: fontFamily),
        labelSmall: const TextStyle(fontFamily: fontFamily),
      ),
      extensions: [chatExtension],
    );
  }

  /// Same as [buildLightTheme] with defaults (e.g. tests).
  static ThemeData get light => buildLightTheme();
}
