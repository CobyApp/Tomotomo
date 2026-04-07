import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'app_tokens.dart';

bool get _iosBlurCrashWorkaround => !kIsWeb && Platform.isIOS;

class NavItemData {
  const NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Frosted floating dock — replaces Material [NavigationBar] for a cleaner look.
class AppGlassNavBar extends StatelessWidget {
  const AppGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final List<NavItemData> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final padBottom = bottomInset > 0 ? 10.0 : 18.0;

    final panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: scheme.surface.withValues(alpha: _iosBlurCrashWorkaround ? 0.92 : 0.72),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: List.generate(items.length, (i) {
            return Expanded(
              child: _NavCell(
                data: items[i],
                selected: i == currentIndex,
                onTap: () => onSelect(i),
              ),
            );
          }),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, padBottom),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: _iosBlurCrashWorkaround
            ? panel
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: panel,
              ),
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  const _NavCell({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        splashColor: primary.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? primary.withValues(alpha: 0.14) : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  selected ? data.selectedIcon : data.icon,
                  size: AppSizes.navIcon,
                  color: selected ? primary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: selected ? -0.1 : 0,
                  color: selected ? primary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
