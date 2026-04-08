/// Server-backed point wallet (see `public.spend_points`, `try_unlock_dm_expression`, line-analysis cache RPCs).
abstract class PointsRepository {
  /// Deducts [amount] for [reason] (audit string). Returns updated balance or failure.
  Future<SpendPointsOutcome> spendPoints(int amount, String reason);

  /// DM learning sheet: charge 1 pt the first time per message; repeat opens are free server-side.
  Future<DmExpressionUnlockOutcome> tryUnlockDmExpression(String messageServerId);

  /// Cached Gemini line analysis for a message (per UI language).
  Future<LineAnalysisCacheRow?> getLineAnalysisCache(String messageServerId, String appLang);

  Future<void> saveLineAnalysisCache(
    String messageServerId,
    String appLang, {
    String? explanation,
    String? lineTranslation,
    List<Map<String, dynamic>>? vocabularyJson,
  });
}

class SpendPointsOutcome {
  final bool ok;
  final int balance;
  final String? error;

  const SpendPointsOutcome({required this.ok, required this.balance, this.error});

  static SpendPointsOutcome fromRpcJson(Map<String, dynamic> json) {
    final ok = json['ok'] == true;
    final balRaw = json['balance'];
    final bal = balRaw is num ? balRaw.toInt() : int.tryParse('$balRaw') ?? 0;
    final err = json['error'];
    return SpendPointsOutcome(
      ok: ok,
      balance: bal,
      error: err?.toString(),
    );
  }
}

class DmExpressionUnlockOutcome {
  final bool ok;
  final int balance;
  final bool charged;
  final String? error;

  const DmExpressionUnlockOutcome({
    required this.ok,
    required this.balance,
    required this.charged,
    this.error,
  });

  static DmExpressionUnlockOutcome fromRpcJson(Map<String, dynamic> json) {
    final ok = json['ok'] == true;
    final balRaw = json['balance'];
    final bal = balRaw is num ? balRaw.toInt() : int.tryParse('$balRaw') ?? 0;
    final charged = json['charged'] == true;
    final err = json['error'];
    return DmExpressionUnlockOutcome(
      ok: ok,
      balance: bal,
      charged: charged,
      error: err?.toString(),
    );
  }
}

class LineAnalysisCacheRow {
  final String? explanation;
  final String? lineTranslation;
  final List<Map<String, dynamic>> vocabularyJson;

  const LineAnalysisCacheRow({
    this.explanation,
    this.lineTranslation,
    this.vocabularyJson = const [],
  });
}
