import 'package:aichat/domain/entities/saved_expression.dart';
import 'package:flutter_test/flutter_test.dart';

SavedExpression row({String? reading, String? translation}) => SavedExpression(
  id: '1',
  userId: 'local',
  source: 'chat',
  notebookLang: 'en',
  content: 'today',
  reading: reading,
  translation: translation,
  createdAt: DateTime(2026, 1, 1),
);

/// The reading and the gloss used to be stored as one `reading — meaning` string
/// and split back on the first ` — `. English is the one language whose reading is
/// legitimately absent AND whose glosses idiomatically contain a spaced em dash,
/// so an English gloss was torn in half: the first clause became the
/// pronunciation and the rest of the gloss was shown as the whole meaning.
void main() {
  test('a stored reading is returned as-is, whatever the gloss contains', () {
    final e = row(
      reading: 'təˈdeɪ',
      translation: 'Means "today" — common when asking about someone\'s day.',
    );
    expect(e.readingAndMeaning, (
      'təˈdeɪ',
      'Means "today" — common when asking about someone\'s day.',
    ));
  });

  test('an English gloss with an em dash and no reading stays intact', () {
    final e = row(
      translation: 'Means "today" — common when asking about someone\'s day.',
    );
    final (reading, meaning) = e.readingAndMeaning;
    expect(reading, isNull, reason: 'prose became the pronunciation');
    expect(meaning, 'Means "today" — common when asking about someone\'s day.');
  });

  test('a legacy row written in the joined form still splits', () {
    // Rows saved before `reading` existed carry 'reading — meaning'.
    for (final entry in const {
      'きょう — 「その日」を指す。': ('きょう', '「その日」を指す。'),
      'oneul — 오늘을 뜻한다.': ('oneul', '오늘을 뜻한다.'),
      'jīntiān — 意为“今天”。': ('jīntiān', '意为“今天”。'),
    }.entries) {
      expect(
        row(translation: entry.key).readingAndMeaning,
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('a legacy row whose prefix is clearly prose is left whole', () {
    for (final gloss in const [
      'Means "today" — common when asking about someone\'s day.',
      'A casual greeting, used with friends — never with strangers.',
      '오늘을 뜻하며, 일정 이야기에 자주 쓴다 — 반말이다.',
    ]) {
      final (reading, meaning) = row(translation: gloss).readingAndMeaning;
      expect(reading, isNull, reason: gloss);
      expect(meaning, gloss, reason: gloss);
    }
  });

  test('an empty or missing gloss does not crash', () {
    expect(row().readingAndMeaning, (null, ''));
    expect(row(translation: '  ').readingAndMeaning, (null, ''));
    expect(row(reading: 'x', translation: null).readingAndMeaning, ('x', ''));
  });
}
