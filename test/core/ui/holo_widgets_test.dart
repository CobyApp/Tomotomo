import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aichat/core/ui/holo/holo_widgets.dart';

void main() {
  testWidgets('HoloButton shows label and fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(
        child: HoloButton(label: 'GO', onPressed: () => tapped = true),
      )),
    ));
    expect(find.text('GO'), findsOneWidget);
    await tester.tap(find.byType(HoloButton));
    expect(tapped, isTrue);
  });
}
