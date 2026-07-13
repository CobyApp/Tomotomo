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
    final ok = await repo.spendPoints(30, 'dm');
    expect(ok.ok, isTrue);
    expect(ok.balance, 70);
    final bad = await repo.spendPoints(1000, 'dm');
    expect(bad.ok, isFalse);
    expect(bad.balance, 70);
  });

  test('tryUnlockDmExpression charges once per message', () async {
    final repo = LocalPointsRepositoryImpl(box);
    final first = await repo.tryUnlockDmExpression('m1');
    expect(first.charged, isTrue);
    expect(first.balance, 99);
    final second = await repo.tryUnlockDmExpression('m1');
    expect(second.charged, isFalse);
    expect(second.balance, 99);
  });

  test('creditIapPoints is idempotent by transactionId', () async {
    final repo = LocalPointsRepositoryImpl(box);
    final a = await repo.creditIapPoints(
      store: 'play_store', transactionId: 'tx1', productId: 'p',
      points: 300, usdCents: 100);
    expect(a.credited, isTrue);
    expect(a.balance, 400);
    final b = await repo.creditIapPoints(
      store: 'play_store', transactionId: 'tx1', productId: 'p',
      points: 300, usdCents: 100);
    expect(b.credited, isFalse);
    expect(b.balance, 400);
  });
}
