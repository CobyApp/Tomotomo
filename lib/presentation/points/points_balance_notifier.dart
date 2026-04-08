import 'package:flutter/foundation.dart';

import '../../domain/repositories/profile_repository.dart';

/// Cached [pointBalance] from profile / spend RPCs; drives the app bar chip.
class PointsBalanceNotifier extends ChangeNotifier {
  PointsBalanceNotifier(this._profileRepository);

  final ProfileRepository _profileRepository;
  int? _balance;

  int? get balance => _balance;

  void setBalance(int? value) {
    if (_balance == value) return;
    _balance = value;
    notifyListeners();
  }

  Future<void> refreshFromProfile(String userId) async {
    try {
      final p = await _profileRepository.getProfile(userId);
      if (p != null) setBalance(p.pointBalance);
    } catch (_) {}
  }
}
