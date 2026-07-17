import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aichat/core/ui/paper/journal_note.dart';

void main() {
  testWidgets('JournalNote renders label and child', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: JournalNote(label: '오늘의 단어', child: Text('こんにちは')),
      ),
    ));
    expect(find.text('오늘의 단어'), findsOneWidget);
    expect(find.text('こんにちは'), findsOneWidget);
  });
}
