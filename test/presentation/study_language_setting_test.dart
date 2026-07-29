import 'package:aichat/core/locale/languages.dart';
import 'package:aichat/domain/repositories/profile_repository.dart';
import 'package:aichat/presentation/locale/friend_language_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

/// After onboarding there was no control anywhere in the app for the language you
/// are learning — `setLanguage` had exactly one call site, in onboarding — even
/// though it decides the word book's default segment and every new friend's
/// language. Settings now has a section for it.
final class _Profiles implements ProfileRepository {
  String? stored;

  @override
  Future<String?> getFriendLanguage() async => stored;

  @override
  Future<void> setFriendLanguage(String code) async {
    if (kSupportedLanguages.contains(code)) stored = code;
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnsupportedError('${i.memberName}');
}

void main() {
  test('choosing a study language persists it for every language', () async {
    for (final lang in kSupportedLanguageList) {
      final profiles = _Profiles();
      final notifier = FriendLanguageNotifier(profiles);
      await notifier.setLanguage(lang);

      expect(profiles.stored, lang, reason: 'not written for $lang');
      // And it survives a relaunch.
      final reloaded = FriendLanguageNotifier(profiles);
      await reloaded.load();
      expect(reloaded.resolve('ko'), lang, reason: 'not restored for $lang');
    }
  });

  test('an explicit choice wins over the guess made from the UI language', () async {
    final profiles = _Profiles();
    final notifier = FriendLanguageNotifier(profiles);

    // With nothing chosen, the study language is derived from the UI language.
    expect(notifier.resolve('ja'), 'ko');
    expect(notifier.resolve('en'), 'ja');

    await notifier.setLanguage('zh');
    for (final ui in kSupportedLanguageList) {
      expect(notifier.resolve(ui), 'zh', reason: 'UI $ui overrode the choice');
    }
  });

  test('an unsupported code is refused rather than stored', () async {
    final profiles = _Profiles();
    final notifier = FriendLanguageNotifier(profiles);
    await notifier.setLanguage('ko');
    await notifier.setLanguage('fr');
    expect(profiles.stored, 'ko');
  });
}
