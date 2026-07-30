import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_tokens.dart';
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
    // The pill measures 42pt tall, 2pt under the 44pt minimum, and chips are the
    // only way to pick a level / language / notebook segment. The InkWell — the
    // part that receives the tap — is stretched to 44 while the pill keeps its
    // size, so the sticker look is unchanged. The pill is opaque, so it already
    // hid the ink splash; that does not change either.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(PaperRadii.pill),
        onTap: onTap,
        child: SizedBox(
          height: kMinTapTarget,
          child: Center(
            widthFactor: 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              foregroundDecoration: selected
                  ? stickerGloss(
                      borderRadius: BorderRadius.circular(PaperRadii.pill),
                      strength: 0.22,
                    )
                  : null,
              decoration: BoxDecoration(
                // Sticker chip: hotpink fill when selected, ink border + hard shadow.
                color: selected ? p.coral : p.card,
                borderRadius: BorderRadius.circular(PaperRadii.pill),
                border: Border.all(color: p.ink, width: 2),
                boxShadow: [
                  BoxShadow(color: p.hardShadow, offset: const Offset(2, 2)),
                ],
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
        ),
      ),
    );
  }
}

/// Layered "cut-paper" sticker card: thick ink edge + hard offset shadow. When
/// [onTap] is set it presses in (shadow collapses + slight scale) like a real
/// sticker being pushed, with a light haptic tick.
class PaperCard extends StatefulWidget {
  const PaperCard({super.key, required this.child, this.padding, this.onTap});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  State<PaperCard> createState() => _PaperCardState();
}

class _PaperCardState extends State<PaperCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final tappable = widget.onTap != null;
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      transform: Matrix4.translationValues(_down ? 2 : 0, _down ? 2 : 0, 0),
      padding: widget.padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(PaperRadii.card),
        // Sticker: thick ink border + hard offset shadow (no blur).
        border: Border.all(color: p.cardEdge, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: p.hardShadow,
            offset: Offset(_down ? 2 : 4, _down ? 2 : 4),
          ),
        ],
      ),
      child: widget.child,
    );
    if (!tappable) return card;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap!();
      },
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
    this.costPoints,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  /// When set, shows a small "{n}P" cost pill after the label — used on
  /// point-spending actions so the cost sits next to the action itself.
  final int? costPoints;

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
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.busy
          ? null
          : widget.onPressed == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onPressed!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.expand ? double.infinity : null,
        transform: Matrix4.translationValues(_down ? 4 : 0, _down ? 4 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        foregroundDecoration: enabled
            ? stickerGloss(borderRadius: BorderRadius.circular(999))
            : null,
        decoration: BoxDecoration(
          // Sticker style: hotpink→purple gradient, thick ink border, and a
          // HARD offset shadow that collapses on press (button "presses in").
          gradient: enabled
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [p.coral, p.coralDeep],
                )
              : null,
          color: enabled ? null : fill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: p.ink, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: p.hardShadow,
              offset: Offset(_down ? 0 : 4, _down ? 0 : 4),
            ),
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
                  if (widget.costPoints != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${widget.costPoints}P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Compact gradient sticker icon-button for app-bar actions (add friend, etc.)
/// — a hotpink→purple circle with an ink border, gloss, hard shadow, press-in
/// and a light haptic. Cleaner and more on-brand than a bare Material icon.
class PaperRoundButton extends StatefulWidget {
  const PaperRoundButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 40,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final String? tooltip;

  @override
  State<PaperRoundButton> createState() => _PaperRoundButtonState();
}

class _PaperRoundButtonState extends State<PaperRoundButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final btn = GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onPressed?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.size,
        height: widget.size,
        transform: Matrix4.translationValues(_down ? 2 : 0, _down ? 2 : 0, 0),
        foregroundDecoration: stickerGloss(
          shape: BoxShape.circle,
          strength: 0.3,
        ),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.coral, p.coralDeep],
          ),
          border: Border.all(color: p.ink, width: 2),
          boxShadow: [
            BoxShadow(
              color: p.hardShadow,
              offset: Offset(_down ? 0 : 2, _down ? 0 : 2),
            ),
          ],
        ),
        child: Icon(widget.icon, color: Colors.white, size: widget.size * 0.5),
      ),
    );
    if (widget.tooltip == null) return btn;
    return Tooltip(message: widget.tooltip!, child: btn);
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
  final double rotate; // retained for API compatibility; no longer rotated.
  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Transform.rotate(
      angle: rotate,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          // Sticker: ink border + hard offset shadow, slight playful tilt.
          color: p.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.ink, width: 2.5),
          boxShadow: [
            BoxShadow(color: p.hardShadow, offset: const Offset(3, 3)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// One-shot springy entrance (fade + rise) for list items — the reference's
/// card "pop-in". Runs once when the item is first built; later items finish a
/// touch later so a list cascades in. Keep [index] to the on-screen position.
class PaperEntrance extends StatelessWidget {
  const PaperEntrance({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index.clamp(0, 8) * 55)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 18),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// A glossy top sheen for filled "jelly/sticker" elements (buttons, the
/// selected nav pill, chips, the send button). Apply as a `foregroundDecoration`
/// so a soft white highlight sits over the top half of the fill and fades out by
/// the middle — the light-catching look that reads as a 3D sticker, not a flat
/// rectangle. Pass the element's own [borderRadius] (or `shape: circle`).
BoxDecoration stickerGloss({
  BorderRadius? borderRadius,
  BoxShape shape = BoxShape.rectangle,
  double strength = 0.28,
}) {
  return BoxDecoration(
    shape: shape,
    borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.center,
      colors: [
        Colors.white.withValues(alpha: strength),
        Colors.white.withValues(alpha: 0),
      ],
    ),
  );
}

/// Sticker-style progress bar: a paper track with a thick ink border and a
/// hotpink→purple gradient fill. Pass `value` in 0..1 for determinate; pass
/// null for an indeterminate sliding sweep. One shared bar so every progress
/// surface (model download, onboarding) looks identical.
class PaperProgressBar extends StatefulWidget {
  const PaperProgressBar({super.key, required this.value, this.height = 16});
  final double? value;
  final double height;

  @override
  State<PaperProgressBar> createState() => _PaperProgressBarState();
}

class _PaperProgressBarState extends State<PaperProgressBar>
    with SingleTickerProviderStateMixin {
  // Assigned in initState (not a lazy `late final = …`) so it always exists
  // while the widget is active — a lazy field would first initialize inside
  // dispose() for a determinate bar that never touches it, crashing on a
  // deactivated widget.
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    if (widget.value == null) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant PaperProgressBar old) {
    super.didUpdateWidget(old);
    // Only spin for the indeterminate state.
    if (widget.value == null && !_c.isAnimating) {
      _c.repeat();
    } else if (widget.value != null && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final radius = BorderRadius.circular(999);
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: p.paperBg,
        borderRadius: radius,
        border: Border.all(color: p.ink, width: 2),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final fill = DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [p.coral, p.coralDeep]),
                borderRadius: radius,
              ),
            );
            if (widget.value != null) {
              // heightFactor: 1 is essential — without it the fill gets loose
              // height constraints and collapses to 0px, so the bar looks empty
              // even while the percentage climbs.
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: widget.value!.clamp(0.0, 1.0),
                heightFactor: 1.0,
                child: fill,
              );
            }
            // Indeterminate: a block sweeps left→right.
            final blockW = w * 0.4;
            return AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final dx = (w + blockW) * _c.value - blockW;
                return Stack(
                  children: [
                    Positioned(
                      left: dx,
                      top: 0,
                      bottom: 0,
                      width: blockW,
                      child: fill,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Plain "no photo yet" placeholder: a single clean person glyph on a soft
/// neutral fill. Deliberately simple (not a cartoon face) — used as the default
/// profile image for any friend without a picked photo. Drop it in as the child
/// of a [PolaroidAvatar] or any clipped circle.
class PersonAvatarGlyph extends StatelessWidget {
  const PersonAvatarGlyph({super.key, this.size = 52});
  final double size;
  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Container(
      color: p.paperBg,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        size: size * 0.62,
        color: p.inkSoft.withValues(alpha: 0.75),
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
