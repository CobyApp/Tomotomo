import 'package:flutter/material.dart';

import 'paper/paper_theme.dart';

/// Shared layout and typography tokens for shell tabs and list-heavy screens.
abstract final class AppSpacing {
  static const double pageH = 20;
  static const double pageTop = 12;
  static const double pageBottom = 32;
  static const double listGap = 12;
  static const double sectionAfter = 12;

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal inset for the glass bottom navigation dock.
  static const double navDockInset = 12;

  /// Side / bottom margin for floating modal sheets (e.g. expression sheet).
  static const double sheetSide = 16;
  static const double sheetBottom = 20;

  /// Outer padding for the chat composer bar.
  static const double composerPadH = 16;
  static const double composerPadTop = 10;
  static const double composerPadBottom = 10;
}

abstract final class AppRadii {
  static const double card = 20;
  static const double cardSmall = 16;
  static const double sheet = 28;
  static const double pill = 999;
}

abstract final class AppSizes {
  static const double listAvatar = 24;
  static const double listAvatarLg = 30;
  static const double navIcon = 24;
  static const double minTapTarget = 44;
}

abstract final class AppTextStyles {
  /// [language] is the language of the text being rendered — pass it when a row
  /// shows content (a friend's name), not UI chrome, since the theme's stack is
  /// built for the UI language. See [cuteDisplayFallback].
  static TextStyle listTitle(BuildContext context, {String? language}) {
    final t = Theme.of(context).textTheme;
    return (t.titleMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
      height: 1.25,
      fontFamilyFallback: language == null
          ? null
          : cuteDisplayFallback(language),
    );
  }

  static TextStyle listSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      height: 1.4,
    );
  }

  static TextStyle sectionLabel(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall!.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.1,
    );
  }

  static TextStyle pageTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.w800,
      fontSize: 24,
      letterSpacing: -0.7,
    );
  }
}
