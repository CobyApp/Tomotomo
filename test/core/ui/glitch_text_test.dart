import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aichat/core/ui/holo/glitch_text.dart';

void main() {
  testWidgets('GlitchText renders the text and layered copies', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: GlitchText('トモトモ'))),
    ));
    expect(find.text('トモトモ'), findsWidgets);
  });
}
