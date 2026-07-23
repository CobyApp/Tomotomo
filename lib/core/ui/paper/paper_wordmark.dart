import 'package:flutter/material.dart';
import 'paper_theme.dart';
import 'paper_tokens.dart';

/// The app wordmark in the paper-cartoon style: a coral cute-display title with
/// a soft marker underline. No glitch/print-offset ghost — clean and readable.
class PaperWordmark extends StatelessWidget {
  const PaperWordmark(this.text, {super.key, this.fontSize = 24});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final base = cuteDisplay(fontSize: fontSize, fontWeight: FontWeight.w800);
    Widget ghost(Color c, Offset d) => Transform.translate(
      offset: d,
      child: Text(
        text,
        style: base.copyWith(color: c.withValues(alpha: 0.55)),
      ),
    );
    // Y2K chromatic-aberration glitch: cyan + pink offset copies behind.
    return Stack(
      children: [
        ghost(p.stampBlue, const Offset(-1.6, 1.2)),
        ghost(p.coral, const Offset(1.6, -1.2)),
        Text(text, style: base.copyWith(color: p.ink)),
      ],
    );
  }
}
