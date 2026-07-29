import 'package:flutter/foundation.dart';

import '../../data/repositories/local_points_repository_impl.dart';
import '../../domain/repositories/points_repository.dart';
import 'watch_rewarded_ad.dart';

/// Cached point balance from the local wallet / spend outcomes; drives the app bar chip.
class PointsBalanceNotifier extends ChangeNotifier {
  PointsBalanceNotifier(this._pointsRepository);

  final PointsRepository _pointsRepository;
  int? _balance;

  int? get balance => _balance;

  void setBalance(int? value) {
    if (_balance == value) return;
    _balance = value;
    notifyListeners();
  }

  /// Points granted by the daily free top-up during the last [loadInitial], or 0.
  ///
  /// Surfaced so the app can say why the balance went up — a silent increase reads
  /// as a bug.
  int get lastDailyGrant => _lastDailyGrant;
  int _lastDailyGrant = 0;

  /// Loads the current balance from the local wallet (e.g. on app startup), and
  /// grants the day's free points if they have not been claimed yet.
  Future<void> loadInitial() async {
    try {
      final repo = _pointsRepository;
      if (repo is LocalPointsRepositoryImpl) {
        // Claimed here rather than in main(): this is where the wallet is first
        // read, whichever screen gets there first, and the grant is idempotent
        // per day so calling it more than once is safe.
        _lastDailyGrant = await repo.claimDailyFreePoints(today: todayKey());
      }
      setBalance(await _pointsRepository.currentBalance());
    } catch (_) {}
  }
}
