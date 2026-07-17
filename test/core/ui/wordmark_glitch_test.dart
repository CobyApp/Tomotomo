import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aichat/core/ui/paper/wordmark_glitch.dart';

void main() {
  testWidgets('WordmarkGlitch renders the text with offset ghost copies', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: WordmarkGlitch('トモトモ'))),
    ));
    expect(find.text('トモトモ'), findsWidgets);
  });
}
