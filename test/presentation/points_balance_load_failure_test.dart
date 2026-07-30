import 'package:aichat/domain/repositories/points_repository.dart';
import 'package:aichat/presentation/points/points_balance_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

/// A failed wallet read left the balance null, and the big balance card rendered
/// null as a hard "0" — so someone holding 200P saw zero and concluded their
/// points had been wiped, while the wallet itself was intact. Unknown and empty
/// must not look the same.
final class _Wallet implements PointsRepository {
  _Wallet(this._balance);
  int? _balance;
  var reads = 0;

  @override
  Future<int> currentBalance() async {
    reads++;
    final b = _balance;
    if (b == null) throw StateError('box closed');
    return b;
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnsupportedError('${i.memberName}');
}

void main() {
  test('a failed read reports unknown, not zero', () async {
    final notifier = PointsBalanceNotifier(_Wallet(null));
    await notifier.loadInitial();

    expect(notifier.balance, isNull, reason: 'a failure invented a balance');
    expect(notifier.loadFailed, isTrue);
  });

  test('it notifies on failure so the retry affordance can appear', () async {
    final notifier = PointsBalanceNotifier(_Wallet(null));
    var notified = 0;
    notifier.addListener(() => notified++);

    await notifier.loadInitial();
    expect(notified, greaterThan(0), reason: 'the UI was never told');
  });

  test('a retry that succeeds clears the failure', () async {
    final wallet = _Wallet(null);
    final notifier = PointsBalanceNotifier(wallet);
    await notifier.loadInitial();
    expect(notifier.loadFailed, isTrue);

    wallet._balance = 200;
    await notifier.loadInitial();

    expect(notifier.loadFailed, isFalse, reason: 'stuck in the failed state');
    expect(notifier.balance, 200);
    expect(wallet.reads, 2);
  });

  test('a genuine zero is not reported as a failure', () async {
    final notifier = PointsBalanceNotifier(_Wallet(0));
    await notifier.loadInitial();

    expect(notifier.balance, 0);
    expect(notifier.loadFailed, isFalse,
        reason: 'an empty wallet was treated as unreadable');
  });
}
