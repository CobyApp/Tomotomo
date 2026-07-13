import 'package:flutter/material.dart';
import '../app_glass_nav_bar.dart' show NavItemData;
import 'holo_tokens.dart';

/// HOLO-KITSCH bottom dock. Drop-in shape-compatible replacement for
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
    const dockHeight = 64.0;

    final panel = SizedBox(
      height: dockHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Holo.surfaceCard,
          // Subtle holographic tint over the card surface.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Holo.pink.withValues(alpha: 0.10),
              Holo.lilac.withValues(alpha: 0.08),
              Holo.cyan.withValues(alpha: 0.10),
            ],
          ),
          border: Border.all(color: Holo.pink.withValues(alpha: 0.35), width: 2),
          boxShadow: Holo.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomGap),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: panel,
        ),
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
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: Holo.pink.withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
            splashFactory: InkRipple.splashFactory,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                gradient: selected ? Holo.holoGradient : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? data.selectedIcon : data.icon,
                    size: 22,
                    color: selected ? Colors.white : Holo.inkPlumSoft,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
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
