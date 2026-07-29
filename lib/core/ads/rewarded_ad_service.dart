import 'dart:async';

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

  /// Shows the ad and waits until it is GONE, then reports what happened.
  ///
  /// `RewardedAd.show()` resolves as soon as the ad is presented, not when the
  /// reward is granted — so the previous `Future<bool>` was always true the
  /// instant the ad appeared, and callers reading a "credited" flag right after
  /// it always read false. The success message was unreachable, and closing the
  /// ad early, failing to show, and hitting the daily cap were indistinguishable:
  /// every one of them left the user with no feedback at all.
  Future<RewardedAdOutcome> show({
    required Future<void> Function() onEarned,
  }) async {
    final ad = _ad;
    if (ad == null) {
      load();
      return RewardedAdOutcome.notReady;
    }
    _ad = null;
    notifyListeners();

    final closed = Completer<void>();
    void done(RewardedAd a) {
      a.dispose();
      load();
      if (!closed.isCompleted) closed.complete();
    }

    var earned = false;
    Future<void>? crediting;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: done,
      onAdFailedToShowFullScreenContent: (a, _) => done(a),
    );
    await ad.show(
      onUserEarnedReward: (_, _) {
        earned = true;
        crediting = onEarned();
      },
    );
    await closed.future;
    if (crediting != null) await crediting;
    return earned ? RewardedAdOutcome.rewarded : RewardedAdOutcome.notFinished;
  }

  @override
  void dispose() {
    _ad?.dispose();
    _ad = null;
    super.dispose();
  }
}

/// What a rewarded-ad attempt actually ended in.
enum RewardedAdOutcome {
  /// No ad loaded yet.
  notReady,

  /// Shown, but closed before the reward point.
  notFinished,

  /// Watched to the reward point; [RewardedAdService.show]'s `onEarned` ran.
  rewarded,
}
