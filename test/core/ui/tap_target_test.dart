import 'package:aichat/core/ui/app_tokens.dart';
import 'package:aichat/core/ui/paper/paper_theme.dart';
import 'package:aichat/core/ui/paper/paper_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chips are the only way to pick a speaking level, a friend language or a
/// notebook segment, and the pill measured 42pt — under the 44pt minimum from the
/// Apple HIG and WCAG 2.5.5. The fix had to leave the drawn pill alone, because
/// the sticker look depends on its size, so the tap area grew instead.
void main() {
  Widget host(List<Widget> chips) => MaterialApp(
    theme: PaperTheme.light,
    home: Scaffold(
      body: Center(child: Row(mainAxisSize: MainAxisSize.min, children: chips)),
    ),
  );

  testWidgets('every chip offers at least the minimum tap target',
      (tester) async {
    // Labels from all four languages: the shortest is what would fall short.
    const labels = ['A', 'ふつう', '보통', '中文', 'Beginner'];
    await tester.pumpWidget(host([
      for (final l in labels)
        PaperChip(label: l, selected: l == 'A', onTap: () {}),
    ]));

    for (final l in labels) {
      final size = tester.getSize(find.ancestor(
        of: find.text(l),
        matching: find.byType(InkWell),
      ));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget),
          reason: '"$l" is ${size.height}pt tall');
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget),
          reason: '"$l" is ${size.width}pt wide');
    }
  });

  testWidgets('the drawn pill keeps its size, so the layout is unchanged',
      (tester) async {
    await tester.pumpWidget(host([
      PaperChip(label: 'ふつう', selected: false, onTap: () {}),
    ]));

    final pill = tester.getSize(find.ancestor(
      of: find.text('ふつう'),
      matching: find.byType(AnimatedContainer),
    ));
    expect(pill.height, 42, reason: 'the sticker pill was resized');
  });

  testWidgets('the whole tap area responds, not just the pill', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host([
      PaperChip(label: 'ふつう', selected: false, onTap: () => taps++),
    ]));

    final inkWell = find.ancestor(
      of: find.text('ふつう'),
      matching: find.byType(InkWell),
    );
    final rect = tester.getRect(inkWell);
    // The strip outside the pill but inside the tap target.
    await tester.tapAt(Offset(rect.center.dx, rect.top + 0.5));
    await tester.pump();
    expect(taps, 1, reason: 'the added hit area is not tappable');
  });
}
