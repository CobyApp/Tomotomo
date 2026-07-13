import '../../domain/repositories/points_repository.dart';

// TODO(phase2): replace with LocalPointsRepositoryImpl.
//
// Temporary in-memory stub so the data layer compiles after Supabase removal.
// All operations succeed as no-ops against a fixed default balance; the line
// analysis cache is not persisted. A later phase implements local points.
class PointsRepositoryImpl implements PointsRepository {
  static const int _defaultBalance = 500;

  @override
  Future<SpendPointsOutcome> spendPoints(int amount, String reason) async {
    return const SpendPointsOutcome(ok: true, balance: _defaultBalance);
  }

  @override
  Future<DmExpressionUnlockOutcome> tryUnlockDmExpression(String messageServerId) async {
    return const DmExpressionUnlockOutcome(
      ok: true,
      balance: _defaultBalance,
      charged: false,
    );
  }

  @override
  Future<LineAnalysisCacheRow?> getLineAnalysisCache(
      String messageServerId, String appLang) async {
    return null;
  }

  @override
  Future<void> saveLineAnalysisCache(
    String messageServerId,
    String appLang, {
    String? explanation,
    String? lineTranslation,
    List<Map<String, dynamic>>? vocabularyJson,
  }) async {
    // no-op
  }

  @override
  Future<CreditIapPointsOutcome> creditIapPoints({
    required String store,
    required String transactionId,
    required String productId,
    String? purchaseToken,
    required int points,
    required int usdCents,
    String? rawReceipt,
  }) async {
    return const CreditIapPointsOutcome(
      ok: true,
      credited: false,
      balance: _defaultBalance,
    );
  }
}
