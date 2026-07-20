import 'package:flutter/material.dart';
import 'paper_loading.dart';
import 'paper_theme.dart';
import 'paper_tokens.dart';

/// Small coral group heading used above card groups and list sections. One
/// shared style so every screen's section labels match.
class PaperSectionLabel extends StatelessWidget {
  const PaperSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Text(
        label,
        style: cuteDisplay(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: context.paper.coral,
        ),
      ),
    );
  }
}

/// Selectable pill chip in the paper style (coral when selected). One shared
/// control for every chip row — speaking level, friend language, notebook
/// segment — so they all look and behave identically.
class PaperChip extends StatelessWidget {
  const PaperChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(PaperRadii.pill),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? p.coralDeep : p.card,
            borderRadius: BorderRadius.circular(PaperRadii.pill),
            border: Border.all(
              color: selected ? p.coralDeep : p.cardEdge,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : p.ink,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// Layered "cut-paper" card: hairline edge + hard offset + soft blur shadow.
class PaperCard extends StatelessWidget {
  const PaperCard({super.key, required this.child, this.padding, this.onTap});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final card = Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(PaperRadii.card),
        border: Border.all(color: p.cardEdge),
        boxShadow: [
          BoxShadow(color: p.hardShadow, offset: const Offset(0, 3)),
          BoxShadow(
            color: p.softShadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(PaperRadii.card),
      onTap: onTap,
      child: card,
    );
  }
}

/// Solid coral CTA with a pressable "paper" bottom edge.
class PaperButton extends StatefulWidget {
  const PaperButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  /// When true, shows a small white [PaperLoading] instead of the label and
  /// ignores taps — same size/shape, no layout jump.
  final bool busy;

  @override
  State<PaperButton> createState() => _PaperButtonState();
}

class _PaperButtonState extends State<PaperButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final enabled = widget.onPressed != null && !widget.busy;
    // coralDeep (not coral) keeps the white label at/near WCAG AA contrast in
    // both light and dark — same reasoning as PaperTheme.filledButtonTheme.
    // The shadow is a further-darkened derivative so the pressable "paper
    // bottom edge" stays visible against the coralDeep fill.
    final fill = enabled ? p.coralDeep : p.inkSoft;
    final shadow = enabled
        ? Color.lerp(p.coralDeep, Colors.black, 0.28)!
        : p.inkSoft;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.busy ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.expand ? double.infinity : null,
        transform: Matrix4.translationValues(0, _down ? 3 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(PaperRadii.button),
          boxShadow: [
            BoxShadow(color: shadow, offset: Offset(0, _down ? 0 : 3)),
          ],
        ),
        child: widget.busy
            ? const SizedBox(
                height: 20,
                child: Center(
                  child: PaperLoading(size: 8, color: Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Dashed-border stamp/ticket (points balance, dates, badges).
class StampTicket extends StatelessWidget {
  const StampTicket({super.key, required this.child, this.rotate = 0});
  final Widget child;
  final double rotate;
  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    // Use the deeper coral in light mode so the small bold label meets WCAG AA
    // on the cream/card surface; the lifted coral already passes in dark mode.
    final stamp = Theme.of(context).brightness == Brightness.dark
        ? p.coral
        : p.coralDeep;
    return Transform.rotate(
      angle: rotate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: stamp,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: stamp,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Emoji/photo inside a white polaroid frame, slightly rotated.
class PolaroidAvatar extends StatelessWidget {
  const PolaroidAvatar({
    super.key,
    required this.child,
    this.size = 52,
    this.rotate = -0.04,
  });
  final Widget child;
  final double size;
  final double rotate;
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.fromLTRB(3, 3, 3, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(PaperRadii.polaroid),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Decorative washi-tape strip; place with Positioned on featured cards.
class WashiTape extends StatelessWidget {
  const WashiTape({
    super.key,
    this.width = 46,
    this.height = 15,
    this.rotate = -0.07,
  });
  final double width, height, rotate;
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate,
      child: Container(width: width, height: height, color: context.paper.tape),
    );
  }
}
