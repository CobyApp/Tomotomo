import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_tokens.dart';
import 'paper_tokens.dart';

/// Data for a single bottom-nav destination used by [PaperNavBar].
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

/// PAPER-CARTOON bottom dock. Renders a clean paper bar with a
/// coral-selected line-icon cell and a top hairline.
class PaperNavBar extends StatelessWidget {
  const PaperNavBar({
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
    final p = context.paper;
    const dockHeight = 68.0;

    final panel = SizedBox(
      height: dockHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: p.card,
          border: Border(top: BorderSide(color: p.cardEdge, width: 1.5)),
          boxShadow: [
            BoxShadow(color: p.hardShadow, offset: const Offset(0, 2)),
            BoxShadow(color: p.softShadow, blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(items.length, (i) {
              return Expanded(
                child: _PaperNavCell(
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
        padding: EdgeInsets.fromLTRB(AppSpacing.navDockInset, 0, AppSpacing.navDockInset, bottomGap),
        child: ClipRRect(borderRadius: BorderRadius.circular(22), child: panel),
      ),
    );
  }
}

class _PaperNavCell extends StatelessWidget {
  const _PaperNavCell({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
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
            borderRadius: BorderRadius.circular(14),
            splashColor: p.coral.withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
            splashFactory: InkRipple.splashFactory,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? p.coral.withValues(alpha: 0.10) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? data.selectedIcon : data.icon,
                    size: 22,
                    color: selected ? p.coral : p.inkSoft,
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
                      color: selected ? p.coral : p.inkSoft,
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
