import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ads/ad_config.dart';
import '../../core/ads/rewarded_ad_service.dart';
import '../../core/ui/paper/paper_bottom_sheet.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../../data/repositories/local_points_repository_impl.dart';
import '../locale/l10n_context.dart';
import 'points_balance_notifier.dart';
import 'points_usage_screen.dart';
import 'watch_rewarded_ad.dart';

/// Shown wherever an action is blocked by an empty wallet. The user can top up
/// by watching a rewarded ad WITHOUT leaving the screen they were on — the
/// previous version only pushed the points screen, which dropped them out of
/// whatever they were in the middle of.
Future<void> showPointsTopUpPrompt(BuildContext context) async {
  await showPaperSheet<void>(context, builder: (ctx) => const _TopUpSheet());
}

class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet();

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  bool _watching = false;

  Future<void> _watchAd() async {
    if (_watching) return;
    setState(() => _watching = true);
    final navigator = Navigator.of(context);
    final credited = await watchRewardedAdForPoints(context);
    if (!mounted) return;
    setState(() => _watching = false);
    // Close only once the points are actually in the wallet. It used to close on
    // "the ad was presented", which resolved instantly — so the sheet vanished
    // while the ad was still on screen, and also when the user was still broke.
    if (credited) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final balance = context.watch<PointsBalanceNotifier>().balance;
    final adService = context.watch<RewardedAdService>();
    final adReady = adService.isReady;
    final adLoading = adService.isLoading;
    final remaining = context
        .read<LocalPointsRepositoryImpl>()
        .adsRemainingToday(today: todayKey());
    final capReached = remaining <= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: p.coral, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('pointsInsufficientTitle'),
                  style: TextStyle(
                    color: p.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              if (balance != null)
                Text(
                  '$balance',
                  style: TextStyle(
                    color: p.coralDeep,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            capReached
                ? context.tr('adEarnCapReached')
                : context.tr('pointsInsufficientBody'),
            style: TextStyle(color: p.inkSoft, height: 1.4),
          ),
          const SizedBox(height: 20),
          if (!capReached) ...[
            PaperButton(
              icon: Icons.play_circle_fill_rounded,
              label: context.tr(
                'adEarnSubtitle',
                params: {'points': '${AdConfig.pointsPerAd}'},
              ),
              // Watch the service, so this button reflects reality AND wakes up
              // by itself when an ad finishes loading. Unconditionally enabled,
              // it silently no-opped into a "Loading ad…" snackbar — on the one
              // path where the user is already blocked and has no other move.
              busy: _watching || adLoading,
              onPressed: adReady ? _watchAd : null,
            ),
            if (!adReady) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  context.tr('adEarnNotReady'),
                  style: TextStyle(color: p.inkSoft, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Center(
              child: Text(
                context.tr(
                  'adEarnRemaining',
                  params: {
                    'remaining': '$remaining',
                    'max': '${AdConfig.maxAdsPerDay}',
                  },
                ),
                style: TextStyle(color: p.inkSoft, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const PointsUsageScreen(),
                  ),
                );
              },
              child: Text(
                context.tr('pointsHelpTitle'),
                style: TextStyle(color: p.inkSoft, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
