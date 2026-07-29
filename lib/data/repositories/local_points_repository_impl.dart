import 'package:hive_ce/hive.dart';
import '../../core/ads/ad_config.dart';
import '../../domain/repositories/points_repository.dart';

/// Outcome of a rewarded-ad reward attempt against the daily cap.
class AdRewardOutcome {
  const AdRewardOutcome({
    required this.credited,
    required this.balance,
    required this.remaining,
  });
  final bool credited;
  final int balance;
  final int remaining;
}

/// Local Hive-backed wallet implementing [PointsRepository]. Single-user; no server.
class LocalPointsRepositoryImpl implements PointsRepository {
  LocalPointsRepositoryImpl(this._box);
  final Box _box;

  int get _balance => (_box.get('balance') as num?)?.toInt() ?? 0;
  Future<void> _setBalance(int v) => _box.put('balance', v);

  @override
  Future<int> currentBalance() async => _balance;

  @override
  Future<SpendPointsOutcome> spendPoints(int amount, String reason) async {
    if (amount <= 0) {
      return SpendPointsOutcome(ok: true, balance: _balance);
    }
    if (_balance < amount) {
      return SpendPointsOutcome(
        ok: false,
        balance: _balance,
        error: 'insufficient_points',
      );
    }
    await _setBalance(_balance - amount);
    return SpendPointsOutcome(ok: true, balance: _balance);
  }

  @override
  Future<LineAnalysisCacheRow?> getLineAnalysisCache(
    String messageServerId,
    String appLang,
  ) async {
    final v = _box.get('line_cache/$messageServerId/$appLang');
    if (v is! Map) return null;
    final m = Map<String, dynamic>.from(v);
    final vocab =
        (m['vocabulary'] as List?)
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

  /// Remaining rewarded-ad views left for [today] (resets when the stored date differs).
  int adsRemainingToday({required String today}) {
    final storedDate = _box.get('ad_date') as String?;
    final count = storedDate == today
        ? ((_box.get('ad_count') as num?)?.toInt() ?? 0)
        : 0;
    final rem = AdConfig.maxAdsPerDay - count;
    return rem < 0 ? 0 : rem;
  }

  /// Records a completed rewarded-ad view for [today] and credits the reward if
  /// the daily cap has not been reached yet.
  Future<AdRewardOutcome> recordAdReward({required String today}) async {
    final storedDate = _box.get('ad_date') as String?;
    var count = storedDate == today
        ? ((_box.get('ad_count') as num?)?.toInt() ?? 0)
        : 0;
    if (count >= AdConfig.maxAdsPerDay) {
      return AdRewardOutcome(credited: false, balance: _balance, remaining: 0);
    }
    count += 1;
    // One write, not two: awaiting the date first left a window where a reader
    // saw today's date beside yesterday's count, which would have credited twice
    // and advanced the counter once.
    await _box.putAll({'ad_date': today, 'ad_count': count});
    final bal = await creditReward(AdConfig.pointsPerAd);
    return AdRewardOutcome(
      credited: true,
      balance: bal,
      remaining: AdConfig.maxAdsPerDay - count,
    );
  }
}
