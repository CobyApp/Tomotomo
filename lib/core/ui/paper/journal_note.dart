import 'package:flutter/material.dart';
import 'paper_tokens.dart';
import 'paper_widgets.dart';

/// A [PaperCard] styled like a journal entry: a coral label, a dashed rule,
/// then arbitrary content.
class JournalNote extends StatelessWidget {
  const JournalNote({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: p.coral,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          _DashedDivider(color: p.cardEdge),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// A thin horizontal dashed rule, drawn without any extra painting packages.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedLinePainter(color: color),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashGap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => oldDelegate.color != color;
}
