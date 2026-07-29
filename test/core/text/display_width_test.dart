import 'package:aichat/core/text/display_width.dart';
import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CJK, kana, hangul and emoji count double; Latin counts single', () {
    expect(displayWidth('abcd'), 4);
    expect(displayWidth('한국어'), 6);
    expect(displayWidth('日本語'), 6);
    expect(displayWidth('中文'), 4);
    expect(displayWidth('あア'), 4);
    expect(displayWidth('🍎'), 2);
    // One glyph, many runes — measured once, not once per rune.
    expect(displayWidth('👩‍💻'), 2);
    expect(displayWidth('🇰🇷'), 2);
  });

  test('a budget tuned for CJK no longer clips English at half the room', () {
    // 56 half-widths: 28 Japanese characters, or 56 Latin letters. The old
    // rune count gave English only 28.
    final japanese = 'あ' * 28;
    final english = 'a' * 56;
    expect(clampToDisplayWidth(japanese, 56), japanese);
    expect(clampToDisplayWidth(english, 56), english);
    expect(displayWidth(clampToDisplayWidth('a' * 57, 56)), lessThanOrEqualTo(56));
  });

  test('a multi-rune emoji is kept whole or dropped whole', () {
    // Walking runes left a dangling ZWJ behind ('👩‍…'); grapheme clusters
    // cannot be cut apart.
    for (final budget in [2, 3, 4, 5, 6]) {
      final clamped = clampToDisplayWidth('👩‍💻👩‍💻👩‍💻', budget);
      expect(clamped, isNot(contains('‍…')), reason: 'budget $budget');
      expect(clamped.runes.last, isNot(0x200D), reason: 'budget $budget');
      expect(displayWidth(clamped), lessThanOrEqualTo(budget), reason: 'budget $budget');
    }
  });

  test('never exceeds the budget, even when it cannot fit the ellipsis', () {
    // These used to return a bare '…', which is 1 wide — over a budget of 0.
    for (final budget in [0, 1, 2]) {
      expect(displayWidth(clampToDisplayWidth('abc', budget)),
          lessThanOrEqualTo(budget), reason: 'budget $budget');
      expect(displayWidth(clampToDisplayWidth('日本語', budget)),
          lessThanOrEqualTo(budget), reason: 'budget $budget');
    }
  });

  test('a character cap is honoured alongside the width budget', () {
    // An imported ASCII tagline fits 56 half-widths but must still respect the
    // editor field's 40-character limit.
    final clamped = clampToDisplayWidth('a' * 56, 56, maxRunes: 40);
    expect(clamped.characters.length, lessThanOrEqualTo(40));
    expect(clamped, endsWith('…'));
    // CJK is bounded by width first, so the cap changes nothing for it.
    final cjk = 'あ' * 28;
    expect(clampToDisplayWidth(cjk, 56, maxRunes: 40), cjk);
  });

  test('short text is returned untouched, with no ellipsis', () {
    expect(clampToDisplayWidth('hello', 56), 'hello');
    expect(clampToDisplayWidth('', 56), '');
    expect(clampToDisplayWidth('hello', 56, maxRunes: 40), 'hello');
  });
}
