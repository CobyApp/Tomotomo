/// Point wallet and expression-analysis cache.
abstract class PointsRepository {
  /// The stored balance right now.
  ///
  /// Callers that are about to do expensive work check this FIRST and charge
  /// only once the work succeeded — charging up front meant a failed X-profile
  /// import (bad URL, offline, timeout) took the points anyway, with no refund.
  Future<int> currentBalance();

  /// Deducts [amount] for [reason]. Returns updated balance or failure.
  Future<SpendPointsOutcome> spendPoints(int amount, String reason);

}

class SpendPointsOutcome {
  final bool ok;
  final int balance;
  final String? error;

  const SpendPointsOutcome({required this.ok, required this.balance, this.error});
}
