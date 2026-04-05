import 'package:flutter/material.dart';

/// Shared layout and typography tokens for shell tabs and list-heavy screens.
abstract final class AppSpacing {
  static const double pageH = 20;
  static const double pageTop = 8;
  static const double pageBottom = 28;
  static const double listGap = 10;
  static const double sectionAfter = 8;
}

abstract final class AppRadii {
  static const double card = 24;
  static const double cardSmall = 18;
  static const double sheet = 28;
  static const double pill = 999;
}

abstract final class AppSizes {
  static const double listAvatar = 26;
  static const double listAvatarLg = 32;
  static const double navIcon = 24;
}

abstract final class AppTextStyles {
  static TextStyle listTitle(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return (t.titleMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.25,
      height: 1.2,
    );
  }

  static TextStyle listSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.3,
        );
  }

  static TextStyle sectionLabel(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall!.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.15,
        );
  }

  static TextStyle pageTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        );
  }
}
