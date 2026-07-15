import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:aichat/data/repositories/local_points_repository_impl.dart';

void main() {
  late Box box;
  setUp(() async {
    Hive.init('./.dart_tool/hive_test_2_1');
    box = await Hive.openBox('points');
    await box.put('balance', 100);
  });
  tearDown(() async => Hive.deleteFromDisk());

  test('spendPoints deducts and fails when insufficient', () async {
    final repo = LocalPointsRepositoryImpl(box);
    final ok = await repo.spendPoints(30, 'character_chat');
    expect(ok.ok, isTrue);
    expect(ok.balance, 70);
    final bad = await repo.spendPoints(1000, 'character_chat');
    expect(bad.ok, isFalse);
    expect(bad.balance, 70);
    // Active point consumers gate the point-earning prompt on this error code.
    expect(bad.error, 'insufficient_points');
  });

  test('rewarded ad daily cap counts and resets by date', () async {
    final repo = LocalPointsRepositoryImpl(box);
    expect(repo.adsRemainingToday(today: '2026-07-13'), 5);
    final r = await repo.recordAdReward(today: '2026-07-13'); // credits +30
    expect(r.credited, isTrue);
    expect(repo.adsRemainingToday(today: '2026-07-13'), 4);
    for (var i = 0; i < 4; i++) {
      await repo.recordAdReward(today: '2026-07-13');
    }
    expect(repo.adsRemainingToday(today: '2026-07-13'), 0);
    final blocked = await repo.recordAdReward(today: '2026-07-13');
    expect(blocked.credited, isFalse);
    expect(repo.adsRemainingToday(today: '2026-07-14'), 5);
  });
}
