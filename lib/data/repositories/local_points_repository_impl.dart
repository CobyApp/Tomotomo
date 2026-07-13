import 'package:hive_ce/hive.dart';
import '../../domain/repositories/points_repository.dart';

/// Local Hive-backed wallet implementing [PointsRepository]. Single-user; no server.
class LocalPointsRepositoryImpl implements PointsRepository {
  LocalPointsRepositoryImpl(this._box);
  final Box _box;

  int get _balance => (_box.get('balance') as num?)?.toInt() ?? 0;
  Future<void> _setBalance(int v) => _box.put('balance', v);

  List<String> _idList(String key) =>
      (_box.get(key) as List?)?.map((e) => e.toString()).toList() ?? <String>[];

  @override
  Future<SpendPointsOutcome> spendPoints(int amount, String reason) async {
    if (amount <= 0) {
      return SpendPointsOutcome(ok: true, balance: _balance);
    }
    if (_balance < amount) {
      return SpendPointsOutcome(ok: false, balance: _balance, error: 'insufficient');
    }
    await _setBalance(_balance - amount);
    return SpendPointsOutcome(ok: true, balance: _balance);
  }

  @override
  Future<DmExpressionUnlockOutcome> tryUnlockDmExpression(String messageServerId) async {
    final unlocked = _idList('dm_unlocks');
    if (unlocked.contains(messageServerId)) {
      return DmExpressionUnlockOutcome(ok: true, balance: _balance, charged: false);
    }
    if (_balance < 1) {
      return DmExpressionUnlockOutcome(
          ok: false, balance: _balance, charged: false, error: 'insufficient');
    }
    await _setBalance(_balance - 1);
    await _box.put('dm_unlocks', [...unlocked, messageServerId]);
    return DmExpressionUnlockOutcome(ok: true, balance: _balance, charged: true);
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
    final processed = _idList('iap_tx');
    if (processed.contains(transactionId)) {
      return CreditIapPointsOutcome(ok: true, credited: false, balance: _balance);
    }
    await _setBalance(_balance + points);
    await _box.put('iap_tx', [...processed, transactionId]);
    return CreditIapPointsOutcome(ok: true, credited: true, balance: _balance);
  }

  @override
  Future<LineAnalysisCacheRow?> getLineAnalysisCache(String messageServerId, String appLang) async {
    final v = _box.get('line_cache/$messageServerId/$appLang');
    if (v is! Map) return null;
    final m = Map<String, dynamic>.from(v);
    final vocab = (m['vocabulary'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];
    return LineAnalysisCacheRow(
      explanation: m['explanation']?.toString(),
      lineTranslation: m['line_translation']?.toString(),
      vocabularyJson: vocab,
    );
  }

  @override
  Future<void> saveLineAnalysisCache(
    String messageServerId,
    String appLang, {
    String? explanation,
    String? lineTranslation,
    List<Map<String, dynamic>>? vocabularyJson,
  }) async {
    await _box.put('line_cache/$messageServerId/$appLang', {
      'explanation': explanation,
      'line_translation': lineTranslation,
      'vocabulary': vocabularyJson ?? [],
    });
  }

  /// Credits an arbitrary reward (used by rewarded ads in Phase 3). Returns new balance.
  Future<int> creditReward(int points) async {
    await _setBalance(_balance + points);
    return _balance;
  }

  int get balance => _balance;
}
