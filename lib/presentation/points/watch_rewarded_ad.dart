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
/// Returns true when the ad was actually shown. Credits the reward, updates the
/// balance and reports the outcome through the app-level messenger.
Future<bool> watchRewardedAdForPoints(BuildContext context) async {
  final ad = context.read<RewardedAdService>();
  final points = context.read<LocalPointsRepositoryImpl>();
  final notifier = context.read<PointsBalanceNotifier>();
  final notReadyText = context.trRead('adEarnNotReady');

  var credited = false;
  final shown = await ad.show(
    onEarned: () async {
      final r = await points.recordAdReward(today: todayKey());
      if (!r.credited) return;
      credited = true;
      notifier.setBalance(r.balance);
    },
  );

  final messenger = appScaffoldMessengerKey.currentState;
  if (!shown) {
    messenger?.showSnackBar(SnackBar(content: Text(notReadyText)));
  } else if (credited) {
    messenger?.showSnackBar(
      SnackBar(content: Text('+${AdConfig.pointsPerAd}pt')),
    );
  }
  return shown;
}
