import 'package:aichat/data/character/characters_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loose script detectors — enough to catch a persona authored in the wrong
/// language, which is the bug this guards.
final _hangul = RegExp(r'[가-힣]');
final _kana = RegExp(r'[぀-ゟ゠-ヿ]');
final _cjk = RegExp(r'[一-鿿]');
final _latin = RegExp(r'[A-Za-z]');

void main() {
  // The friend's speech style is shown to the user in the persona field (the
  // onboarding prefill) AND fed to the model as that friend's voice. A Korean
  // friend once carried Japanese examples, so a learner picking Korean saw
  // Japanese in the form.
  test('each built-in friend speaks its own language', () {
    for (final character in characters) {
      final style = character.speechStyle;
      final phrases = character.commonPhrases.join(' ');
      final sample = '$style $phrases';
      final where = '${character.id} (${character.friendLanguage})';

      switch (character.friendLanguage) {
        case 'ko':
          expect(_hangul.hasMatch(sample), isTrue, reason: '$where: no Hangul');
          expect(_kana.hasMatch(sample), isFalse, reason: '$where: has Kana');
        case 'ja':
          expect(_kana.hasMatch(sample), isTrue, reason: '$where: no Kana');
          expect(_hangul.hasMatch(sample), isFalse, reason: '$where: Hangul');
        case 'zh':
          expect(_cjk.hasMatch(sample), isTrue, reason: '$where: no Chinese');
          expect(_kana.hasMatch(sample), isFalse, reason: '$where: has Kana');
          expect(_hangul.hasMatch(sample), isFalse, reason: '$where: Hangul');
        case 'en':
          expect(_latin.hasMatch(sample), isTrue, reason: '$where: no Latin');
          expect(_kana.hasMatch(sample), isFalse, reason: '$where: has Kana');
          expect(_hangul.hasMatch(sample), isFalse, reason: '$where: Hangul');
      }
    }
  });

  test('every supported study language has a template friend', () {
    // The onboarding prefill looks a friend up by study language; a missing one
    // silently leaves the whole form blank.
    for (final language in const ['ko', 'ja', 'en', 'zh']) {
      expect(
        characters.where((c) => c.friendLanguage == language),
        isNotEmpty,
        reason: 'no built-in friend speaks $language',
      );
    }
  });

  test('each built-in is named in its own language', () {
    // Collapsing the old name/nameJp/nameKanji trio into one `name` had to leave
    // every displayed name byte-identical to what displayNamePrimary returned.
    expect(
      {for (final c in characters) c.id: c.name},
      {
        'yuna': 'ゆうな',
        'junho': '준호',
        'emily': 'Emily',
        'jack': 'Jack',
        'lina': '李娜',
        'wangwei': '王伟',
      },
    );
  });
}
