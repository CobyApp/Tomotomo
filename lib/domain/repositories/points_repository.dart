/// Point wallet and expression-analysis cache.
abstract class PointsRepository {
  /// Deducts [amount] for [reason]. Returns updated balance or failure.
  Future<SpendPointsOutcome> spendPoints(int amount, String reason);

  /// Cached AI line analysis for a message and UI language.
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
