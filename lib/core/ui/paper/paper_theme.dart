import 'package:flutter/material.dart';
import 'paper_tokens.dart';

/// Cute display text style: Korean via Do Hyeon (CuteKo), Japanese kana/kanji
/// via M PLUS Rounded 1c (CuteJp), falling back to Pretendard for anything else.
TextStyle cuteDisplay({double? fontSize, FontWeight? fontWeight, Color? color}) {
  return TextStyle(
    fontFamily: 'CuteKo',
    fontFamilyFallback: const ['CuteJp', 'Pretendard'],
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    // Slight tracking for a cleaner, techy display feel.
    letterSpacing: 0.4,
  );
}

/// PAPER-CARTOON theme: light + dark [ThemeData], both driven by [PaperColors].
abstract final class PaperTheme {
  static ThemeData get light => _build(Brightness.light, PaperColors.light);
  static ThemeData get dark => _build(Brightness.dark, PaperColors.dark);

  static ThemeData _build(Brightness brightness, PaperColors colors) {
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.coral,
      brightness: brightness,
      surface: colors.card,
    ).copyWith(
      primary: colors.coral,
      onPrimary: Colors.white,
      surface: colors.card,
      onSurface: colors.ink,
      onSurfaceVariant: colors.inkSoft,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Pretendard',
      // InkSparkle uses a shader path that has triggered EXC_BAD_ACCESS on some iOS devices (Skia).
      splashFactory: InkRipple.splashFactory,
      scaffoldBackgroundColor: colors.paperBg,
      extensions: [colors],
      colorScheme: scheme,
      dividerColor: colors.cardEdge,
      // Cohesive, soft route motion everywhere: fade + gentle zoom.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: _PaperPageTransitions(),
          TargetPlatform.android: _PaperPageTransitions(),
          TargetPlatform.macOS: _PaperPageTransitions(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        foregroundColor: colors.ink,
        titleTextStyle: cuteDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: colors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PaperRadii.card),
          side: BorderSide(color: colors.cardEdge),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        backgroundColor: colors.card,
        indicatorColor: colors.coral.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 11,
            letterSpacing: 0.2,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? colors.coral : colors.inkSoft,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? colors.coral : colors.inkSoft,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          // coralDeep (not colorScheme.primary=coral) keeps white-on-fill text
          // at/above WCAG AA contrast in both modes — see Step 1 contrast note.
          backgroundColor: colors.coralDeep,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PaperRadii.button),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PaperRadii.button),
          borderSide: BorderSide(color: colors.cardEdge),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PaperRadii.button),
          borderSide: BorderSide(color: colors.cardEdge),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PaperRadii.button),
          borderSide: BorderSide(color: colors.coral, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PaperRadii.button),
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: TextStyle(fontFamily: 'Pretendard', color: colors.inkSoft),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: 'Pretendard', color: colors.ink),
        displayMedium: TextStyle(fontFamily: 'Pretendard', color: colors.ink),
        displaySmall: TextStyle(fontFamily: 'Pretendard', color: colors.ink),
        headlineLarge: cuteDisplay(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: colors.ink,
        ),
        headlineMedium: cuteDisplay(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: colors.ink,
        ),
        headlineSmall: cuteDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: colors.ink,
        ),
        titleLarge: cuteDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: colors.ink,
        ),
        titleMedium: cuteDisplay(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: colors.ink,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w600,
          color: colors.ink,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 15,
          height: 1.4,
          color: colors.ink,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          height: 1.4,
          color: colors.ink,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          height: 1.4,
          color: colors.ink,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          color: colors.ink,
        ),
        labelMedium: TextStyle(fontFamily: 'Pretendard', color: colors.ink),
        // Secondary/caption use — matches Material's onSurfaceVariant pattern.
        labelSmall: TextStyle(fontFamily: 'Pretendard', color: colors.inkSoft),
      ),
    );
  }
}

/// Soft app-wide route transition: the incoming page fades in while gently
/// zooming from 97% — calmer than a hard platform slide and on-brand for the
/// cute paper look. Applied via [ThemeData.pageTransitionsTheme].
class _PaperPageTransitions extends PageTransitionsBuilder {
  const _PaperPageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
        child: child,
      ),
    );
  }
}
