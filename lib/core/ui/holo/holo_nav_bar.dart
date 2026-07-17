import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_tokens.dart';
import '../app_glass_nav_bar.dart' show NavItemData;
import 'holo_tokens.dart';

/// Soft holographic bottom dock. Drop-in shape-compatible replacement for
/// [AppGlassNavBar]: same public constructor params ([currentIndex],
/// [onSelect], [items]). Renders a glossy holo pill with a gradient-highlighted
/// selected item.
class HoloNavBar extends StatelessWidget {
  const HoloNavBar({
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
    const dockHeight = 72.0;

    final panel = SizedBox(
      height: dockHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Holo.surfaceCard.withValues(alpha: 0.74),
          // Layered translucent color gives the dock a glass-like surface
          // without using the iOS blur path that is unstable on some devices.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.72),
              Holo.lilac.withValues(alpha: 0.16),
              Holo.cyan.withValues(alpha: 0.13),
            ],
          ),
          border: Border.all(color: Holo.pink.withValues(alpha: 0.22)),
          boxShadow: Holo.floatingShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(items.length, (i) {
              return Expanded(
                child: _HoloNavCell(
                  data: items[i],
                  selected: i == currentIndex,
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
        padding: EdgeInsets.fromLTRB(
          AppSpacing.navDockInset,
          0,
          AppSpacing.navDockInset,
          bottomGap,
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(24), child: panel),
      ),
    );
  }
}

class _HoloNavCell extends StatelessWidget {
  const _HoloNavCell({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Semantics(
        label: data.label,
        button: true,
        selected: selected,
        child: Tooltip(
          message: data.label,
          waitDuration: const Duration(milliseconds: 450),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: Holo.pink.withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
            splashFactory: InkRipple.splashFactory,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                gradient: selected ? Holo.holoGradient : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Holo.pink.withValues(alpha: 0.22),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? data.selectedIcon : data.icon,
                    size: 23,
                    color: selected ? Colors.white : Holo.inkPlumSoft,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? Colors.white : Holo.inkPlumSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
