import 'package:flutter/foundation.dart';

import '../../domain/repositories/points_repository.dart';

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

  /// Loads the current balance from the local wallet (e.g. on app startup).
  Future<void> loadInitial() async {
    try {
      // A zero-amount spend is a side-effect-free way to read the current
      // balance through the [PointsRepository] interface (which exposes no
      // dedicated getter).
      final result = await _pointsRepository.spendPoints(0, 'balance_check');
      setBalance(result.balance);
    } catch (_) {}
  }
}
