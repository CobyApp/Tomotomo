import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ads/ad_config.dart';
import '../../core/ads/rewarded_ad_service.dart';
import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/journal_note.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../../data/repositories/local_points_repository_impl.dart';
import '../locale/l10n_context.dart';
import 'points_balance_notifier.dart';

/// The single points screen: earn (watch a rewarded ad) at the top, then an
/// explanation of when points are spent. Opened from the balance chip or
/// Settings.
class PointsUsageScreen extends StatefulWidget {
  const PointsUsageScreen({super.key});

  @override
  State<PointsUsageScreen> createState() => _PointsUsageScreenState();
}

class _PointsUsageScreenState extends State<PointsUsageScreen> {
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

  Widget _bullet(BuildContext context, String text) {
    final p = context.paper;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              height: 1.45,
              color: p.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(text, style: TextStyle(height: 1.45, color: p.ink)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return PaperScaffold(
      title: context.tr('pointsHelpTitle'),
      subtitle: context.tr('pointsHelpLead'),
      transparentBackground: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          AppSpacing.pageTop,
          AppSpacing.pageH,
          AppSpacing.pageBottom,
        ),
        children: [
          Builder(
            builder: (context) {
              final pts = context.read<LocalPointsRepositoryImpl>();
              final adService = context.watch<RewardedAdService>();
              final remaining = pts.adsRemainingToday(today: _today());
              return _AdRewardCard(
                adReady: adService.isReady,
                adLoading: adService.isLoading,
                capReached: remaining == 0,
                remaining: remaining,
                onWatch: _watchAd,
                onRetryLoad: adService.load,
              );
            },
          ),
          const SizedBox(height: 18),
          JournalNote(
            label: context.tr('pointsHelpSectionWhen'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bullet(context, context.tr('pointsHelpItemXImport')),
                _bullet(context, context.tr('pointsHelpItemCharacterChat')),
                _bullet(context, context.tr('pointsHelpItemCustomCreate')),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PaperCard(
            child: Text(
              context.tr('pointsHelpFooter'),
              style: TextStyle(height: 1.4, color: p.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "free ticket" card that lets the user earn points by watching a
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
