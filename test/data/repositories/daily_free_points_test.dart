import 'package:aichat/core/ads/ad_config.dart';
import 'package:aichat/data/repositories/local_points_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

/// The wallet was the one thing in this offline app that needed the network:
/// below the cost of a single reply the core feature was locked, and the only
/// top-up was a rewarded ad. A small daily grant keeps a plane or a dead zone
/// usable, and needs no ad and no connection.
void main() {
  late Box box;
  late LocalPointsRepositoryImpl repo;

  setUp(() async {
    Hive.init('./.dart_tool/test_hive_daily');
    box = await Hive.openBox('points_daily_test');
    await box.clear();
    await box.put('balance', 0);
    repo = LocalPointsRepositoryImpl(box);
  });
  tearDown(() async => Hive.deleteFromDisk());

  test('the first call of the day grants, the rest do not', () async {
    expect(await repo.claimDailyFreePoints(today: '2026-07-29'),
        AdConfig.dailyFreePoints);
    expect(await repo.currentBalance(), AdConfig.dailyFreePoints);

    for (var i = 0; i < 3; i++) {
      expect(await repo.claimDailyFreePoints(today: '2026-07-29'), 0,
          reason: 'granted twice on the same day');
    }
    expect(await repo.currentBalance(), AdConfig.dailyFreePoints);
  });

  test('a new day grants again', () async {
    await repo.claimDailyFreePoints(today: '2026-07-29');
    expect(await repo.claimDailyFreePoints(today: '2026-07-30'),
        AdConfig.dailyFreePoints);
    expect(await repo.currentBalance(), AdConfig.dailyFreePoints * 2);
  });

  test('it adds to whatever is already there', () async {
    await box.put('balance', 17);
    await repo.claimDailyFreePoints(today: '2026-07-29');
    expect(await repo.currentBalance(), 17 + AdConfig.dailyFreePoints);
  });

  test('the grant alone covers several replies', () async {
    // The point of it: never stranded below the cost of one reply.
    await repo.claimDailyFreePoints(today: '2026-07-29');
    var replies = 0;
    while ((await repo.spendPoints(5, 'character_chat')).ok) {
      replies++;
    }
    expect(replies, greaterThanOrEqualTo(5),
        reason: 'a day of free points barely buys anything');
  });

  test('the ad cap is the raised one, and still a cap', () async {
    expect(AdConfig.maxAdsPerDay, 10);
    var credited = 0;
    for (var i = 0; i < AdConfig.maxAdsPerDay + 5; i++) {
      final r = await repo.recordAdReward(today: '2026-07-29');
      if (r.credited) credited++;
    }
    expect(credited, AdConfig.maxAdsPerDay, reason: 'the cap did not hold');
    expect(repo.adsRemainingToday(today: '2026-07-29'), 0);
  });
}
