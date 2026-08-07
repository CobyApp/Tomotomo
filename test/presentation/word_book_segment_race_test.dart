import 'package:aichat/core/locale/study_language.dart';
import 'package:aichat/domain/repositories/profile_repository.dart';
import 'package:aichat/presentation/locale/friend_language_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

/// Both language notifiers start on defaults and load from the profile
/// asynchronously. The word book resolved its segment from them in a post-frame
/// callback, which can run first: LocaleNotifier still says 'ko', so the target
/// derives to 'ja', the segment locks in, and — because the screen marked itself
/// initialized — it stayed wrong until the tab was re-selected. In practice that
/// meant opening the app straight onto the word book showed an empty segment
/// next to a full one.
final class _Profiles implements ProfileRepository {
  _Profiles(this.stored);
  String? stored;
  var reads = 0;

  @override
  Future<String?> getFriendLanguage() async {
    reads++;
    return stored;
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnsupportedError('${i.memberName}');
}

void main() {
  test('before loading, the derived target can disagree with the saved one', () {
    // This is the window the screen used to latch onto.
    final notifier = FriendLanguageNotifier(_Profiles('ko'));
    expect(notifier.chosen, isNull);
    expect(notifier.resolve('ko'), studyLanguageForApp('ko'));
    expect(notifier.resolve('ko'), 'ja',
        reason: 'the pre-load guess is what mislabelled the segment');
  });

  test('loading announces the change, which is what the screen listens for',
      () async {
    final notifier = FriendLanguageNotifier(_Profiles('ko'));
    var notified = 0;
    notifier.addListener(() => notified++);

    await notifier.load();

    expect(notified, 1, reason: 'nothing would tell the word book to re-derive');
    expect(notifier.resolve('ja'), 'ko');
    expect(notifier.resolve('ko'), 'ko',
        reason: 'the saved choice must win over the UI-derived guess');
  });

  test('with nothing saved, the derived target is stable across a load',
      () async {
    // The screen must not thrash for users who never chose one.
    final notifier = FriendLanguageNotifier(_Profiles(null));
    final before = notifier.resolve('en');
    await notifier.load();
    expect(notifier.resolve('en'), before);
  });

  test('every UI language derives a study language that is not itself', () {
    // A friend who speaks the language you already read would defeat the app.
    for (final ui in const ['ko', 'ja', 'en', 'zh']) {
      expect(studyLanguageForApp(ui), isNot(ui), reason: ui);
    }
  });
}
