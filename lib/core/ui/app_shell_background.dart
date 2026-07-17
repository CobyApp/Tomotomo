import 'package:flutter/material.dart';

import 'paper/paper_tokens.dart';

/// Full-screen backdrop: a cream paper wash with a subtle dotted grain
/// texture. Retains [showOrbs] / [gradientPrimaryTop] in its signature for
/// call-site compatibility, but the PAPER-CARTOON look is a flat wash with no
/// gradient sweep or floating color orbs.
class AppShellBackground extends StatelessWidget {
  const AppShellBackground({
    super.key,
    required this.child,
    this.showOrbs = true,
    this.gradientPrimaryTop = false,
  });

  final Widget child;
  final bool showOrbs;
  final bool gradientPrimaryTop;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: p.paperBg),
        CustomPaint(painter: _PaperGrainPainter(color: p.grain), size: Size.infinite),
        child,
      ],
    );
  }
}

/// Faint dotted "paper grain" texture, cheap enough to draw every frame.
class _PaperGrainPainter extends CustomPainter {
  const _PaperGrainPainter({required this.color});

  final Color color;
  static const double _spacing = 14;
  static const double _dotRadius = 0.6;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = 0.0; y < size.height; y += _spacing) {
      for (var x = 0.0; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), _dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PaperGrainPainter oldDelegate) => oldDelegate.color != color;
}
