import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';

/// Loads and shows a single rewarded ad. Calls [onEarned] once the user earns
/// the reward, then preloads the next ad.
class RewardedAdService extends ChangeNotifier {
  RewardedAd? _ad;
  bool _loading = false;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    load();
  }

  void load() {
    if (_loading || _ad != null) return;
    _loading = true;
    notifyListeners();
    RewardedAd.load(
      adUnitId: AdConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          notifyListeners();
        },
        onAdFailedToLoad: (_) {
          _ad = null;
          _loading = false;
          notifyListeners();
        },
      ),
    );
  }

  bool get isReady => _ad != null;
  bool get isLoading => _loading;

  /// Shows the ad; invokes [onEarned] on completion. Returns false if not ready.
  Future<bool> show({required void Function() onEarned}) async {
    final ad = _ad;
    if (ad == null) {
      load();
      return false;
    }
    _ad = null;
    notifyListeners();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        load();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        load();
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => onEarned());
    return true;
  }

  @override
  void dispose() {
    _ad?.dispose();
    _ad = null;
    super.dispose();
  }
}
