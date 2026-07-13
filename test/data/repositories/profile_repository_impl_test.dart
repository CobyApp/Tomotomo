import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:aichat/data/repositories/profile_repository_impl.dart';
import 'package:aichat/domain/entities/profile.dart';

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
    expect(p.pointBalance, 500);
    expect(p.displayName, isNull);
  });

  test('updateProfile persists fields and keeps default point balance', () async {
    await repo.getProfile('local');
    final base = await repo.getProfile('local');
    final updated = await repo.updateProfile(base!.copyWith(
      displayName: 'ゆき',
      appLanguage: 'ja',
      learningLanguage: 'ko',
    ));
    expect(updated.displayName, 'ゆき');
    expect(updated.appLanguage, 'ja');
    expect(updated.learningLanguage, 'ko');
    expect(updated.pointBalance, 500);

    final reloaded = await repo.getProfile('local');
    expect(reloaded!.displayName, 'ゆき');
    expect(reloaded.appLanguage, 'ja');
  });
}
