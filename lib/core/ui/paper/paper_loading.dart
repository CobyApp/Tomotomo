import 'package:flutter/material.dart';

import 'paper_tokens.dart';

/// Cute, on-brand loading indicator: three coral dots bouncing in a staggered
/// wave — like a chat "typing…" indicator, fitting a friend-chat app. Used
/// everywhere in place of [CircularProgressIndicator].
class PaperLoading extends StatefulWidget {
  const PaperLoading({super.key, this.size = 10, this.color});

  /// Dot diameter.
  final double size;

  /// Defaults to `context.paper.coral`.
  final Color? color;

  @override
  State<PaperLoading> createState() => _PaperLoadingState();
}

class _PaperLoadingState extends State<PaperLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.paper.coral;
    final gap = widget.size * 0.6;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Each dot is offset in phase so they bounce as a wave.
            final phase = (_c.value + i * 0.18) % 1.0;
            // Smooth up-down: 0→1→0 via a sine-like curve.
            final t = Curves.easeInOut.transform(
              phase < 0.5 ? phase * 2 : (1 - phase) * 2,
            );
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? gap : 0),
              child: Transform.translate(
                offset: Offset(0, -t * widget.size * 0.8),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.55 + t * 0.45),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Centered [PaperLoading] with breathing room — for full-body loading states.
class PaperLoadingBodyDots extends StatelessWidget {
  const PaperLoadingBodyDots({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: PaperLoading(size: 14),
      ),
    );
  }
}
