import 'package:flutter/material.dart';
import 'paper_tokens.dart';

/// The app wordmark with a faint print-offset (misregistration) ghost — a small
/// nod to the old kitsch, readable and restrained.
class WordmarkGlitch extends StatelessWidget {
  const WordmarkGlitch(this.text, {super.key, this.fontSize = 27});
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final base = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, height: 1);
    Widget ghost(Color c, Offset d) => Transform.translate(
          offset: d,
          child: Text(text, style: base.copyWith(color: c.withValues(alpha: 0.35))),
        );
    return Stack(children: [
      ghost(p.coral, const Offset(-1.5, 1)),
      ghost(p.stampBlue, const Offset(1.5, -1)),
      Text(text, style: base.copyWith(color: p.coral)),
    ]);
  }
}
