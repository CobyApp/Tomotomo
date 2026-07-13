import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:aichat/data/repositories/theme_repository_impl.dart';
import 'package:aichat/domain/entities/user_theme.dart';

void main() {
  late Box box;
  late ThemeRepositoryImpl repo;

  setUp(() async {
    Hive.init('./.dart_tool/hive_test_theme');
    box = await Hive.openBox('settings');
    repo = ThemeRepositoryImpl(box);
  });
  tearDown(() async => Hive.deleteFromDisk());

  test('getTheme is null before any save', () async {
    expect(await repo.getTheme('local'), isNull);
  });

  test('saveTheme then getTheme round-trips', () async {
    await repo.saveTheme(
      'local',
      const UserTheme(chatBubbleUser: 'FF6A3EA1', accent: 'FF00FF00'),
    );
    final t = await repo.getTheme('local');
    expect(t, isNotNull);
    expect(t!.chatBubbleUser, 'FF6A3EA1');
    expect(t.accent, 'FF00FF00');
    expect(t.chatBg, isNull);
  });
}
