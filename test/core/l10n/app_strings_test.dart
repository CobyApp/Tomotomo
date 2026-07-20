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

  test('new language-name keys resolve', () {
    expect(AppStrings.of('en', 'langEnglish'), 'English');
    expect(AppStrings.of('en', 'langChinese'), 'Chinese');
    expect(AppStrings.of('en', 'friendLangZh'), 'Chinese');
  });
}
