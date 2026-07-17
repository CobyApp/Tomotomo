import 'package:flutter_test/flutter_test.dart';
import 'package:aichat/core/locale/study_language.dart';

void main() {
  test('Japanese app targets Korean study content', () {
    expect(studyLanguageForApp('ja'), 'ko');
  });

  test('Korean and fallback app locales target Japanese study content', () {
    expect(studyLanguageForApp('ko'), 'ja');
    expect(studyLanguageForApp('en'), 'ja');
  });
}
