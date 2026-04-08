import '../../core/supabase/app_supabase.dart';
import '../../domain/repositories/points_repository.dart';

class PointsRepositoryImpl implements PointsRepository {
  Map<String, dynamic> _asJsonMap(dynamic res) {
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  @override
  Future<SpendPointsOutcome> spendPoints(int amount, String reason) async {
    final res = await AppSupabase.client.rpc(
      'spend_points',
      params: {'p_amount': amount, 'p_reason': reason},
    );
    return SpendPointsOutcome.fromRpcJson(_asJsonMap(res));
  }

  @override
  Future<DmExpressionUnlockOutcome> tryUnlockDmExpression(String messageServerId) async {
    final res = await AppSupabase.client.rpc(
      'try_unlock_dm_expression',
      params: {'p_message_id': messageServerId},
    );
    return DmExpressionUnlockOutcome.fromRpcJson(_asJsonMap(res));
  }

  @override
  Future<LineAnalysisCacheRow?> getLineAnalysisCache(String messageServerId, String appLang) async {
    final res = await AppSupabase.client.rpc(
      'get_line_analysis_cache',
      params: {'p_message_id': messageServerId, 'p_app_lang': appLang},
    );
    if (res == null) return null;
    final m = _asJsonMap(res);
    if (m.isEmpty) return null;
    final vocab = m['vocabulary'];
    final list = <Map<String, dynamic>>[];
    if (vocab is List) {
      for (final e in vocab) {
        if (e is Map) list.add(Map<String, dynamic>.from(e));
      }
    }
    return LineAnalysisCacheRow(
      explanation: m['explanation']?.toString(),
      lineTranslation: m['line_translation']?.toString(),
      vocabularyJson: list,
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
    await AppSupabase.client.rpc(
      'save_line_analysis_cache',
      params: {
        'p_message_id': messageServerId,
        'p_app_lang': appLang,
        'p_explanation': explanation,
        'p_line_translation': lineTranslation,
        'p_vocabulary': vocabularyJson ?? [],
      },
    );
  }
}
