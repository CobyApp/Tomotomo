import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ads/ad_config.dart';
import '../../core/ads/rewarded_ad_service.dart';
import '../../core/ui/holo/holo_tokens.dart';
import '../../core/ui/holo/holo_widgets.dart';
import '../../core/ui/ui.dart';
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
    return AppPageScaffold(
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
              return _AdShimmerCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: Holo.holoGradient,
                      ),
                      child: const Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('adEarnTitle'),
                            style: const TextStyle(
                              color: Holo.inkPlum,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            capReached
                                ? context.tr('adEarnCapReached')
                                : '${context.tr('adEarnSubtitle', params: {'points': '${AdConfig.pointsPerAd}'})}\n${context.tr('adEarnRemaining', params: {'remaining': '$remaining', 'max': '${AdConfig.maxAdsPerDay}'})}',
                            style: const TextStyle(
                              color: Holo.inkPlumSoft,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          HoloButton(
                            icon: adReady
                                ? Icons.play_arrow_rounded
                                : Icons.refresh_rounded,
                            label: adReady || capReached
                                ? context.tr('adEarnWatch')
                                : adLoading
                                ? context.tr('adEarnNotReady')
                                : context.tr('adEarnRetry'),
                            onPressed: capReached || adLoading
                                ? null
                                : adReady
                                ? _watchAd
                                : adService.load,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Holographic shimmer sweep behind the ad-earning card content — the visual
/// hero of the top-up screen. Purely decorative: a diagonal translucent band
/// slides across the card on a gentle 2s repeating loop.
class _AdShimmerCard extends StatefulWidget {
  const _AdShimmerCard({required this.child});

  final Widget child;

  @override
  State<_AdShimmerCard> createState() => _AdShimmerCardState();
}

class _AdShimmerCardState extends State<_AdShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Holo.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Holo.pink.withValues(alpha: 0.35), width: 2),
        boxShadow: Holo.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(padding: const EdgeInsets.all(14), child: widget.child),
            Positioned.fill(
              child: IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final dx = -w * 0.6 + _controller.value * (w * 1.9);
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: Transform.rotate(
                            angle: -0.35,
                            child: Container(
                              width: w * 0.45,
                              height: h * 2.2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.0),
                                    Colors.white.withValues(alpha: 0.45),
                                    Holo.cyan.withValues(alpha: 0.3),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.0, 0.45, 0.65, 1.0],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
