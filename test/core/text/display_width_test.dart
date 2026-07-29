import 'package:aichat/core/text/display_width.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CJK, kana and hangul count double; Latin counts single', () {
    expect(displayWidth('abcd'), 4);
    expect(displayWidth('한국어'), 6);
    expect(displayWidth('日本語'), 6);
    expect(displayWidth('中文'), 4);
    expect(displayWidth('あア'), 4);
  });

  test('a budget tuned for CJK no longer clips English at half the room', () {
    // 56 half-widths: 28 Japanese characters, or 56 Latin letters. The old
    // rune count gave English only 28.
    final japanese = 'あ' * 28;
    final english = 'a' * 56;
    expect(clampToDisplayWidth(japanese, 56), japanese);
    expect(clampToDisplayWidth(english, 56), english);
    expect(clampToDisplayWidth('a' * 57, 56).length, lessThan(57));
  });

  test('never splits an emoji into broken halves', () {
    // '👩‍💻' and friends are surrogate pairs in UTF-16; substring on a code-unit
    // index could keep half of one.
    final clamped = clampToDisplayWidth('🍎🍊🍇🍓🍒', 6);
    expect(clamped.runes.every((r) => r != 0xFFFD), isTrue);
    expect(clamped.runes.length, greaterThan(1));
    expect(clamped, endsWith('…'));
    // Re-encoding is lossless, which a split pair would break.
    expect(String.fromCharCodes(clamped.runes), clamped);
  });

  test('short text is returned untouched, with no ellipsis', () {
    expect(clampToDisplayWidth('hello', 56), 'hello');
    expect(clampToDisplayWidth('', 56), '');
  });

  test('the ellipsis fits inside the budget', () {
    final clamped = clampToDisplayWidth('日' * 40, 20);
    expect(displayWidth(clamped), lessThanOrEqualTo(20));
    expect(clamped, endsWith('…'));
  });
}
