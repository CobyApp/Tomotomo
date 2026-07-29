import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ads/ad_config.dart';
import '../../core/ads/rewarded_ad_service.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../../data/repositories/local_points_repository_impl.dart';
import '../locale/l10n_context.dart';
import 'points_balance_notifier.dart';
import 'points_usage_screen.dart';
import 'watch_rewarded_ad.dart';

/// Balance + one-tap top-up, shown at the top of Settings so points are
/// visible and actionable without digging into a sub-screen.
class PointsSummaryCard extends StatefulWidget {
  const PointsSummaryCard({super.key});

  @override
  State<PointsSummaryCard> createState() => _PointsSummaryCardState();
}

class _PointsSummaryCardState extends State<PointsSummaryCard> {
  bool _watching = false;

  @override
  void initState() {
    super.initState();
    // Settings can be the first screen that needs the balance.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final n = context.read<PointsBalanceNotifier>();
      if (n.balance == null) n.loadInitial();
    });
  }

  Future<void> _watchAd() async {
    if (_watching) return;
    setState(() => _watching = true);
    await watchRewardedAdForPoints(context);
    if (mounted) setState(() => _watching = false);
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

    return PaperCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const PointsUsageScreen()),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: p.coral, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('settingsPointsBalance'),
                  style: TextStyle(
                    color: p.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
              ),
              Text(
                balance == null ? '—' : '$balance',
                style: TextStyle(
                  color: p.coralDeep,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (capReached)
            Text(
              context.tr('adEarnCapReached'),
              style: TextStyle(color: p.inkSoft, fontSize: 12.5),
            )
          else ...[
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
        ],
      ),
    );
  }
}
