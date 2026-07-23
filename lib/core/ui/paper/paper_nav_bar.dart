import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_tokens.dart';
import 'paper_tokens.dart';
import 'paper_widgets.dart';

/// Which custom kawaii glyph a nav destination draws.
enum NavGlyph { friends, chats, vocab, settings }

/// Custom, hand-drawn nav glyphs sharing one chunky rounded-ink stroke so they
/// read as a cohesive set (not a Material grab-bag). The Chats bubble echoes the
/// app's mascot (rounded bubble + two eyes + smile).
class KawaiiNavIcon extends StatelessWidget {
  const KawaiiNavIcon({
    super.key,
    required this.glyph,
    required this.color,
    this.size = 24,
  });

  final NavGlyph glyph;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _KawaiiIconPainter(glyph, color)),
    );
  }
}

class _KawaiiIconPainter extends CustomPainter {
  _KawaiiIconPainter(this.glyph, this.color);

  final NavGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (glyph) {
      case NavGlyph.friends:
        // Back person.
        canvas.drawCircle(Offset(15.5 * s, 8 * s), 2.5 * s, stroke);
        canvas.drawArc(
          Rect.fromLTWH(11.5 * s, 12.5 * s, 10 * s, 11 * s),
          math.pi, math.pi, false, stroke,
        );
        // Front person.
        canvas.drawCircle(Offset(9 * s, 9 * s), 3.1 * s, stroke);
        canvas.drawArc(
          Rect.fromLTWH(3 * s, 14 * s, 12 * s, 12 * s),
          math.pi, math.pi, false, stroke,
        );
      case NavGlyph.chats:
        // Mascot bubble.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(3.5 * s, 4.5 * s, 17 * s, 12.5 * s),
            Radius.circular(5.5 * s),
          ),
          stroke,
        );
        // Tail.
        final tail = Path()
          ..moveTo(8.5 * s, 16 * s)
          ..lineTo(6.5 * s, 20.5 * s)
          ..lineTo(12.5 * s, 16.5 * s);
        canvas.drawPath(tail, stroke);
        // Eyes + smile (echoes the app mascot).
        canvas.drawCircle(Offset(9.5 * s, 10 * s), 1.15 * s, fill);
        canvas.drawCircle(Offset(14.5 * s, 10 * s), 1.15 * s, fill);
        canvas.drawArc(
          Rect.fromLTWH(9.5 * s, 10.5 * s, 5 * s, 4 * s),
          0.15 * math.pi, 0.7 * math.pi, false, stroke,
        );
      case NavGlyph.vocab:
        // Open book: spine + two curved pages.
        final p = Path()
          ..moveTo(12 * s, 6.5 * s)
          ..lineTo(12 * s, 18.5 * s)
          ..moveTo(12 * s, 7 * s)
          ..cubicTo(9 * s, 5.2 * s, 6 * s, 5.4 * s, 4 * s, 6.4 * s)
          ..lineTo(4 * s, 16.8 * s)
          ..cubicTo(6.5 * s, 15.9 * s, 9.5 * s, 16.1 * s, 12 * s, 17.6 * s)
          ..moveTo(12 * s, 7 * s)
          ..cubicTo(15 * s, 5.2 * s, 18 * s, 5.4 * s, 20 * s, 6.4 * s)
          ..lineTo(20 * s, 16.8 * s)
          ..cubicTo(17.5 * s, 15.9 * s, 14.5 * s, 16.1 * s, 12 * s, 17.6 * s);
        canvas.drawPath(p, stroke);
      case NavGlyph.settings:
        // Two slider bars with knobs (tune).
        canvas.drawLine(Offset(4 * s, 8.5 * s), Offset(20 * s, 8.5 * s), stroke);
        canvas.drawLine(Offset(4 * s, 15.5 * s), Offset(20 * s, 15.5 * s), stroke);
        canvas.drawCircle(Offset(15 * s, 8.5 * s), 2.7 * s, fill);
        canvas.drawCircle(Offset(9 * s, 15.5 * s), 2.7 * s, fill);
    }
  }

  @override
  bool shouldRepaint(_KawaiiIconPainter old) =>
      old.glyph != glyph || old.color != color;
}

/// Data for a single bottom-nav destination used by [PaperNavBar]. Prefer
/// [glyph] (custom hand-drawn icon); [icon]/[selectedIcon] are the Material
/// fallback when no glyph is given.
class NavItemData {
  const NavItemData({
    this.icon,
    this.selectedIcon,
    this.glyph,
    required this.label,
  }) : assert(glyph != null || (icon != null && selectedIcon != null));

  final IconData? icon;
  final IconData? selectedIcon;
  final NavGlyph? glyph;
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
          borderRadius: BorderRadius.circular(24),
          color: p.card,
          border: Border.all(color: p.ink, width: 2.5),
          boxShadow: [
            BoxShadow(color: p.hardShadow, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              foregroundDecoration: selected
                  ? stickerGloss(
                      borderRadius: BorderRadius.circular(16),
                      strength: 0.24,
                    )
                  : null,
              decoration: BoxDecoration(
                // Selected cell: gradient sticker pill matching the buttons —
                // ink border + hard shadow. Unselected stays clean/transparent.
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [p.coral, p.coralDeep],
                      )
                    : null,
                borderRadius: BorderRadius.circular(16),
                border: selected ? Border.all(color: p.ink, width: 2) : null,
                boxShadow: selected
                    ? [BoxShadow(color: p.hardShadow, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  data.glyph != null
                      ? KawaiiNavIcon(
                          glyph: data.glyph!,
                          size: 24,
                          color: selected ? Colors.white : p.inkSoft,
                        )
                      : Icon(
                          selected ? data.selectedIcon : data.icon,
                          size: 22,
                          color: selected ? Colors.white : p.inkSoft,
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
                      color: selected ? Colors.white : p.inkSoft,
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
