import 'package:aichat/data/celebrity_persona/profile_text_compactor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps useful profile text within the rune budget', () {
    final input = [
      'Name: 코비',
      'Bio: 한국어와 음악 이야기를 좋아합니다.',
      'Bio: 한국어와 음악 이야기를 좋아합니다.',
      '[프로필 링크](https://example.com/tracking)',
      'https://example.com/only-a-url',
      List.filled(100, '오늘의 짧은 게시물입니다 🎵').join('\n'),
    ].join('\n');

    final compacted = compactProfileText(input, maxRunes: 180);

    expect(compacted.runes.length, lessThanOrEqualTo(180));
    expect(compacted, contains('Name: 코비'));
    expect(compacted, contains('Bio: 한국어와 음악 이야기를 좋아합니다.'));
    expect('Bio: 한국어와 음악 이야기를 좋아합니다.'.allMatches(compacted), hasLength(1));
    expect(compacted, isNot(contains('https://')));
  });

  test('does not split surrogate-pair characters', () {
    expect(compactProfileText('😀😀😀', maxRunes: 2), '😀😀');
  });
}
