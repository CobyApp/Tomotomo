import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aichat/core/ui/paper/paper_theme.dart';
import 'package:aichat/core/ui/paper/paper_widgets.dart';

void main() {
  testWidgets('determinate PaperProgressBar fill has real width AND height',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PaperTheme.light,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: PaperProgressBar(value: 0.5, height: 16),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // The gradient fill is the DecoratedBox with a LinearGradient. It must have
    // both a fractional width (~half of the ~196px inner track) and full height
    // — the earlier bug collapsed its height to 0.
    final fill = find.byWidgetPredicate((w) {
      if (w is! DecoratedBox) return false;
      final d = w.decoration;
      return d is BoxDecoration && d.gradient != null;
    });
    expect(fill, findsOneWidget);

    final size = tester.getSize(fill);
    expect(size.height, greaterThan(8),
        reason: 'fill must fill the track height, not collapse to 0');
    expect(size.width, greaterThan(60),
        reason: 'fill width should be ~50% of the track');
    expect(size.width, lessThan(160),
        reason: 'fill width should not span the whole track at 50%');
  });
}
