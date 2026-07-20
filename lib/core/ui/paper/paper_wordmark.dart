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
    return Text(
      text,
      style: cuteDisplay(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: p.coral,
      ),
    );
  }
}
