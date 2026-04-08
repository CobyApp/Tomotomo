import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    // Scaffold's bottom slot can pass unbounded max height; pin height so Row/Expanded
    // does not expand vertically and swallow the whole screen.
    const dockHeight = 64.0;

    final panel = SizedBox(
      height: dockHeight,
      child: DecoratedBox(
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(items.length, (i) {
              final iconSize = items.length > 5 ? 22.0 : AppSizes.navIcon;
              return Expanded(
                child: _NavCell(
                  data: items[i],
                  selected: i == currentIndex,
                  iconSize: iconSize,
                  onTap: () => onSelect(i),
                ),
              );
            }),
          ),
        ),
      ),
    );

    final bottomGap = MediaQuery.paddingOf(context).bottom > 0 ? 8.0 : 14.0;

    return SafeArea(
      top: false,
      minimum: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 0, 18, bottomGap),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: _iosBlurCrashWorkaround
              ? panel
              : BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: panel,
                ),
        ),
      ),
    );
  }
}

class _NavCell extends StatefulWidget {
  const _NavCell({
    required this.data,
    required this.selected,
    required this.iconSize,
    required this.onTap,
  });

  final NavItemData data;
  final bool selected;
  final double iconSize;
  final VoidCallback onTap;

  @override
  State<_NavCell> createState() => _NavCellState();
}

class _NavCellState extends State<_NavCell> with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.selectionClick();
    widget.onTap();
    unawaited(
      _press.forward(from: 0).then((_) async {
        if (mounted) await _press.reverse();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final iconMuted = scheme.onSurfaceVariant.withValues(alpha: 0.62);

    return Material(
      color: Colors.transparent,
      child: Semantics(
        label: widget.data.label,
        button: true,
        selected: widget.selected,
        child: Tooltip(
          message: widget.data.label,
          waitDuration: const Duration(milliseconds: 450),
          child: InkWell(
            onTap: _onTap,
            borderRadius: BorderRadius.circular(24),
            splashColor: primary.withValues(alpha: 0.06),
            highlightColor: Colors.transparent,
            splashFactory: InkRipple.splashFactory,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: AnimatedBuilder(
                animation: _press,
                builder: (context, child) {
                  final t = Curves.easeOutCubic.transform(_press.value);
                  final scale = 1.0 - 0.07 * t;
                  return Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
                    child: child,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.selected ? primary.withValues(alpha: 0.07) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    widget.selected ? widget.data.selectedIcon : widget.data.icon,
                    size: widget.iconSize,
                    color: widget.selected ? primary : iconMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
