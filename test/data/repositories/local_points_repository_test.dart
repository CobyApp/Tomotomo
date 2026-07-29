import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:aichat/core/ads/ad_config.dart';
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
    // Against the constant, not a literal: this asserted 5 and broke the moment
    // the cap was raised, which is noise rather than a finding.
    const cap = AdConfig.maxAdsPerDay;
    final repo = LocalPointsRepositoryImpl(box);
    expect(repo.adsRemainingToday(today: '2026-07-13'), cap);
    final r = await repo.recordAdReward(today: '2026-07-13');
    expect(r.credited, isTrue);
    expect(repo.adsRemainingToday(today: '2026-07-13'), cap - 1);
    for (var i = 0; i < cap - 1; i++) {
      await repo.recordAdReward(today: '2026-07-13');
    }
    expect(repo.adsRemainingToday(today: '2026-07-13'), 0);
    final blocked = await repo.recordAdReward(today: '2026-07-13');
    expect(blocked.credited, isFalse);
    expect(repo.adsRemainingToday(today: '2026-07-14'), cap);
  });
}
