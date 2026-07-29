import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:aichat/core/locale/languages.dart';
import 'package:aichat/data/repositories/profile_repository_impl.dart';

void main() {
  late Box box;
  late ProfileRepositoryImpl repo;

  setUp(() async {
    Hive.init('./.dart_tool/hive_test_profile');
    box = await Hive.openBox('settings');
    repo = ProfileRepositoryImpl(box);
  });
  tearDown(() async => Hive.deleteFromDisk());

  test('getProfile creates and persists defaults when absent', () async {
    final p = await repo.getProfile('local');
    expect(p, isNotNull);
    expect(p!.appLanguage, 'ko');
    expect(p.learningLanguage, 'ja');
    expect(p.displayName, isNull);
  });

  test('updateProfile persists local preference fields', () async {
    await repo.getProfile('local');
    final base = await repo.getProfile('local');
    final updated = await repo.updateProfile(
      base!.copyWith(
        displayName: 'ゆき',
        appLanguage: 'ja',
        learningLanguage: 'ko',
      ),
    );
    expect(updated.displayName, 'ゆき');
    expect(updated.appLanguage, 'ja');
    expect(updated.learningLanguage, 'ko');

    final reloaded = await repo.getProfile('local');
    expect(reloaded!.displayName, 'ゆき');
    expect(reloaded.appLanguage, 'ja');
  });

  test('onboarded flag defaults false and round-trips', () async {
    expect(await repo.isOnboarded(), isFalse);
    await repo.setOnboarded();
    expect(await repo.isOnboarded(), isTrue);
  });

  test('nationality round-trips', () async {
    expect(await repo.getNationality(), isNull);
    await repo.setNationality('ko');
    expect(await repo.getNationality(), 'ko');
  });

  // This used to assert "only accepts ko/ja" — written before en/zh shipped and
  // never revisited, so it pinned the bug in place: an English or Chinese friend
  // had its write dropped and reverted to Japanese on the next launch.
  test('friend language defaults null and round-trips every language', () async {
    expect(await repo.getFriendLanguage(), isNull);
    for (final lang in kSupportedLanguages) {
      await repo.setFriendLanguage(lang);
      expect(await repo.getFriendLanguage(), lang);
    }
  });

  test('friend language rejects an unsupported code', () async {
    await repo.setFriendLanguage('ko');
    await repo.setFriendLanguage('fr');
    expect(await repo.getFriendLanguage(), 'ko');
  });
}
