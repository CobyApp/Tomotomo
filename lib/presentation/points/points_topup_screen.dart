import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ads/ad_config.dart';
import '../../core/ads/rewarded_ad_service.dart';
import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../../data/repositories/local_points_repository_impl.dart';
import '../locale/l10n_context.dart';
import 'points_balance_notifier.dart';

class PointsTopUpScreen extends StatefulWidget {
  const PointsTopUpScreen({super.key});

  @override
  State<PointsTopUpScreen> createState() => _PointsTopUpScreenState();
}

class _PointsTopUpScreenState extends State<PointsTopUpScreen> {
  String _today() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _watchAd() async {
    final ad = context.read<RewardedAdService>();
    final pts = context.read<LocalPointsRepositoryImpl>();
    final notifier = context.read<PointsBalanceNotifier>();
    final shown = await ad.show(
      onEarned: () async {
        final r = await pts.recordAdReward(today: _today());
        if (r.credited) {
          notifier.setBalance(r.balance);
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('+${AdConfig.pointsPerAd}pt')),
            );
          }
        }
      },
    );
    if (!shown && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('adEarnNotReady'))));
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PaperScaffold(
      title: context.tr('pointsEarnTitle'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          8,
          AppSpacing.pageH,
          AppSpacing.pageBottom,
        ),
        children: [
          Builder(
            builder: (context) {
              final pts = context.read<LocalPointsRepositoryImpl>();
              final adService = context.watch<RewardedAdService>();
              final adReady = adService.isReady;
              final adLoading = adService.isLoading;
              final remaining = pts.adsRemainingToday(today: _today());
              final capReached = remaining == 0;
              return _AdRewardCard(
                adReady: adReady,
                adLoading: adLoading,
                capReached: capReached,
                remaining: remaining,
                onWatch: _watchAd,
                onRetryLoad: adService.load,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The hero "free ticket" card that lets the user earn points by watching a
/// rewarded ad. Static paper styling only — no shimmer/gradient animation.
class _AdRewardCard extends StatelessWidget {
  const _AdRewardCard({
    required this.adReady,
    required this.adLoading,
    required this.capReached,
    required this.remaining,
    required this.onWatch,
    required this.onRetryLoad,
  });

  final bool adReady;
  final bool adLoading;
  final bool capReached;
  final int remaining;
  final VoidCallback onWatch;
  final VoidCallback onRetryLoad;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return PaperCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StampTicket(
                rotate: -0.05,
                child: Text(context.tr('adEarnFreeBadge')),
              ),
              const Spacer(),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.coral.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: p.coral,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('adEarnTitle'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: p.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            capReached
                ? context.tr('adEarnCapReached')
                : '${context.tr('adEarnSubtitle', params: {'points': '${AdConfig.pointsPerAd}'})}\n${context.tr('adEarnRemaining', params: {'remaining': '$remaining', 'max': '${AdConfig.maxAdsPerDay}'})}',
            style: TextStyle(color: p.inkSoft, height: 1.35),
          ),
          const SizedBox(height: 16),
          PaperButton(
            icon: adReady ? Icons.play_arrow_rounded : Icons.refresh_rounded,
            label: adReady || capReached
                ? context.tr('adEarnWatch')
                : adLoading
                ? context.tr('adEarnNotReady')
                : context.tr('adEarnRetry'),
            onPressed: capReached || adLoading
                ? null
                : adReady
                ? onWatch
                : onRetryLoad,
          ),
        ],
      ),
    );
  }
}
