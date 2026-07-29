import 'package:aichat/data/repositories/ai_system_prompt_builder.dart';
import 'package:aichat/domain/entities/character.dart';
import 'package:aichat/domain/entities/character_record.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nothing told the model it cannot look anything up, so "what's your new song?"
/// or "what's the weather?" came back as a confident, invented answer the learner
/// had no way to tell from a real one. The persona rule matters for the same
/// reason: a friend based on a real person must not assert that person's actual
/// releases or schedule as its own.
void main() {
  Character friend(String language) => Character.fromRecord(
    CharacterRecord.draft(name: 'Sam', language: language),
  );

  test('every friend/learner combination carries the two rules', () {
    for (final friendLang in const ['ko', 'ja', 'en', 'zh']) {
      for (final appLang in const ['ko', 'ja', 'en', 'zh']) {
        final prompt = buildChatReplySystemPrompt(
          friend(friendLang),
          appUiLanguageCode: appLang,
        );
        expect(prompt, contains('cannot look anything up'),
            reason: 'friend=$friendLang app=$appLang');
        expect(prompt, contains('fictional friend'),
            reason: 'friend=$friendLang app=$appLang');
      }
    }
  });

  test('the deflection names the things that actually need looking up', () {
    final prompt = buildChatReplySystemPrompt(friend('ja'));
    for (final topic in const [
      'the date',
      'weather',
      'news',
      'prices',
      'scores',
      'trends',
      'release',
      'schedule',
    ]) {
      expect(prompt, contains(topic), reason: 'not covered: $topic');
    }
  });

  test('it forbids the failure modes that would be worse than not knowing', () {
    final prompt = buildChatReplySystemPrompt(friend('ko'));
    // Breaking character is worse for a language partner than a vague answer.
    expect(prompt, contains('Never break character'));
    expect(prompt, contains('being an AI'));
    // And it must not turn into a wall of apology.
    expect(prompt, contains('Say briefly'));
  });

  test('the reply rules stay numbered 1..N with no gaps or repeats', () {
    // The rules are a numbered list the model follows, and rule 6 refers to
    // "rule 5" by number — inserting a rule without renumbering silently points
    // it at the wrong one.
    final prompt = buildChatReplySystemPrompt(friend('ja'));
    final block = prompt.split('REPLY RULES').last.split('CHECK BEFORE').first;
    final numbers = RegExp(r'^(\d+)\. ', multiLine: true)
        .allMatches(block)
        .map((m) => int.parse(m.group(1)!))
        .toList();
    expect(numbers, List.generate(numbers.length, (i) => i + 1),
        reason: 'rule numbering is $numbers');
    expect(numbers.length, greaterThanOrEqualTo(11));
  });
}
