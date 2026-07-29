import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ads/ad_config.dart';
import '../../core/ads/rewarded_ad_service.dart';
import '../../core/ui/app_scaffold_messenger.dart';
import '../../data/repositories/local_points_repository_impl.dart';
import '../locale/l10n_context.dart';
import 'points_balance_notifier.dart';

String todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

/// Rewarded-ad top-up shared by every entry point (the insufficient-points
/// sheet and the Settings points card), so they can't drift apart.
///
/// Returns true when the reward was credited. Every other outcome — no ad
/// loaded, closed before the reward, daily cap already reached — now says so,
/// because they were previously indistinguishable: the sheet just closed with no
/// message and the user was still blocked.
Future<bool> watchRewardedAdForPoints(BuildContext context) async {
  final ad = context.read<RewardedAdService>();
  final points = context.read<LocalPointsRepositoryImpl>();
  final notifier = context.read<PointsBalanceNotifier>();
  final notReadyText = context.trRead('adEarnNotReady');
  final notFinishedText = context.trRead('adEarnNotFinished');
  final capReachedText = context.trRead('adEarnCapReached');

  var credited = false;
  final outcome = await ad.show(
    onEarned: () async {
      final r = await points.recordAdReward(today: todayKey());
      if (!r.credited) return;
      credited = true;
      notifier.setBalance(r.balance);
    },
  );

  final messenger = appScaffoldMessengerKey.currentState;
  void say(String text) =>
      messenger?.showSnackBar(SnackBar(content: Text(text)));

  switch (outcome) {
    case RewardedAdOutcome.notReady:
      say(notReadyText);
    case RewardedAdOutcome.notFinished:
      say(notFinishedText);
    case RewardedAdOutcome.rewarded:
      say(credited ? '+${AdConfig.pointsPerAd}pt' : capReachedText);
  }
  return credited;
}
