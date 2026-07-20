import 'package:aichat/core/ui/paper/paper_theme.dart';
import 'package:aichat/core/ui/paper/paper_wordmark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PaperWordmark renders the text once (no ghost copies)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PaperTheme.light,
        home: const Scaffold(body: Center(child: PaperWordmark('トモトモ'))),
      ),
    );
    expect(find.text('トモトモ'), findsOneWidget);
  });
}
