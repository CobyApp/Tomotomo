import 'package:aichat/core/l10n/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('en and zh resolve for a known key', () {
    expect(AppStrings.of('en', 'tabChats'), 'Chats');
    expect(AppStrings.of('zh', 'tabChats'), '聊天');
  });

  test('unknown language falls back to ko', () {
    expect(AppStrings.of('fr', 'tabChats'), AppStrings.of('ko', 'tabChats'));
  });

  test('all four languages define the same non-empty keys', () {
    // The real regression to guard: a key added to one block but not the others
    // silently falls back and ships text in the wrong language.
    final korean = AppStrings.all('ko');
    expect(korean, isNotEmpty);
    for (final language in const ['ja', 'en', 'zh']) {
      final map = AppStrings.all(language);
      expect(
        map.keys.toSet(),
        korean.keys.toSet(),
        reason: '$language does not define the same keys as ko',
      );
      for (final entry in map.entries) {
        expect(
          entry.value.trim(),
          isNotEmpty,
          reason: '$language.${entry.key} is empty',
        );
      }
    }
  });
}
