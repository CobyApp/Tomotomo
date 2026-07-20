import 'package:aichat/domain/entities/profile.dart';
import 'package:aichat/domain/repositories/profile_repository.dart';
import 'package:aichat/presentation/locale/friend_language_notifier.dart';
import 'package:aichat/presentation/locale/locale_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements ProfileRepository {
  Profile? stored;
  String? friendLang;
  @override
  Future<Profile?> getProfile(String userId) async =>
      stored ??
      Profile(
        id: userId,
        appLanguage: 'en',
        learningLanguage: 'zh',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
  @override
  Future<Profile> updateProfile(Profile profile) async {
    stored = profile;
    return profile;
  }
  @override
  Future<bool> isOnboarded() async => false;
  @override
  Future<void> setOnboarded() async {}
  @override
  Future<String?> getNationality() async => null;
  @override
  Future<void> setNationality(String? value) async {}
  @override
  Future<String?> getFriendLanguage() async => friendLang;
  @override
  Future<void> setFriendLanguage(String code) async => friendLang = code;
}

void main() {
  test('LocaleNotifier loads and sets en/zh', () async {
    final repo = _FakeRepo();
    final n = LocaleNotifier(repo);
    await n.loadFromProfile('local');
    expect(n.languageCode, 'en');
    final p = (await repo.getProfile('local'))!;
    await n.setAppLanguage('zh', p);
    expect(n.languageCode, 'zh');
  });

  test('FriendLanguageNotifier accepts en/zh', () async {
    final repo = _FakeRepo();
    final n = FriendLanguageNotifier(repo);
    await n.setLanguage('zh');
    expect(n.chosen, 'zh');
    await n.setLanguage('en');
    expect(n.chosen, 'en');
  });
}
