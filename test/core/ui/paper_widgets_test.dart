import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aichat/core/ui/paper/paper_widgets.dart';

void main() {
  testWidgets('PaperButton shows label and fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: PaperButton(label: '학습하기', onPressed: () => tapped = true))),
    ));
    expect(find.text('학습하기'), findsOneWidget);
    await tester.tap(find.byType(PaperButton));
    expect(tapped, isTrue);
  });

  testWidgets('StampTicket renders its child', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: StampTicket(child: Text('충전')))),
    ));
    expect(find.text('충전'), findsOneWidget);
  });
}
