import 'dart:math' as math;

import 'package:aichat/core/ui/paper/paper_theme.dart';
import 'package:aichat/core/ui/paper/paper_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The theme used to assert in a comment that white-on-coralDeep "keeps
/// white-on-fill text at/above WCAG AA contrast in both modes". Measured, it was
/// 4.29:1 in light and 2.99:1 in dark — the dark one below even the 3:1
/// large-text floor, on the primary button and every snackbar. Numbers instead of
/// a claim, so this cannot drift back.
void main() {
  const aaBody = 4.5;

  for (final entry in {'light': PaperColors.light, 'dark': PaperColors.dark}.entries) {
    final name = entry.key;
    final c = entry.value;

    test('$name: body text on both surfaces meets AA', () {
      for (final pair in {
        'ink on card': (c.ink, c.card),
        'ink on paperBg': (c.ink, c.paperBg),
        'inkSoft on card': (c.inkSoft, c.card),
        'inkSoft on paperBg': (c.inkSoft, c.paperBg),
      }.entries) {
        final r = contrast(pair.value.$1, pair.value.$2);
        expect(r, greaterThanOrEqualTo(aaBody),
            reason: '$name ${pair.key} is ${r.toStringAsFixed(2)}:1');
      }
    });
  }

  for (final brightness in Brightness.values) {
    test('${brightness.name}: the primary button label meets AA on its fill', () {
      final theme = brightness == Brightness.dark
          ? PaperTheme.dark
          : PaperTheme.light;
      final style = theme.filledButtonTheme.style!;
      final fill = style.backgroundColor!.resolve({})!;
      final label = style.foregroundColor!.resolve({})!;
      final r = contrast(label, fill);
      expect(r, greaterThanOrEqualTo(aaBody),
          reason: '${brightness.name} button label is ${r.toStringAsFixed(2)}:1');
    });

    test('${brightness.name}: snackbar text meets AA on the snackbar fill', () {
      final theme = brightness == Brightness.dark
          ? PaperTheme.dark
          : PaperTheme.light;
      final bar = theme.snackBarTheme;
      final r = contrast(bar.contentTextStyle!.color!, bar.backgroundColor!);
      expect(r, greaterThanOrEqualTo(aaBody),
          reason: '${brightness.name} snackbar text is ${r.toStringAsFixed(2)}:1');
    });
  }
}
