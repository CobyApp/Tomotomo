import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ads/ad_config.dart';
import '../../core/ads/rewarded_ad_service.dart';
import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/journal_note.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_theme.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../../data/repositories/local_points_repository_impl.dart';
import '../locale/l10n_context.dart';
import 'points_balance_notifier.dart';
import 'watch_rewarded_ad.dart';

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

  @override
  void initState() {
    super.initState();
    // Make sure the balance is populated when opened directly from Settings.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final n = context.read<PointsBalanceNotifier>();
      if (n.balance == null) n.loadInitial();
    });
  }

  /// Delegates to the shared helper so this screen and the top-up sheet cannot
  /// drift apart — this copy had its own credit-and-report logic, which is how it
  /// ended up the only place that ever showed a success message.
  Future<void> _watchAd() async {
    await watchRewardedAdForPoints(context);
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
    final points = context.watch<PointsBalanceNotifier>();
    final balance = points.balance;
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
          _BalanceCard(
            balance: balance,
            unknown: balance == null && points.loadFailed,
          ),
          if (points.loadFailed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: TextButton(
                  onPressed: () => unawaited(points.loadInitial()),
                  child: Text(
                    context.tr('retry'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: p.coralDeep,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
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
                _bullet(
                  context,
                  context.tr(
                    'pointsHelpItemDailyFree',
                    params: {'points': '${AdConfig.dailyFreePoints}'},
                  ),
                ),
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

/// Prominent balance hero: a gradient sticker card showing the user's current
/// points. The number counts up and pops, and a "+N" with sparkles bursts out
/// whenever the balance increases (e.g. after a rewarded ad).
class _BalanceCard extends StatefulWidget {
  const _BalanceCard({required this.balance, required this.unknown});

  final int? balance;

  /// The wallet could not be read — distinct from a balance of zero.
  final bool unknown;

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  int _delta = 0;
  double _from = 0;

  @override
  void initState() {
    super.initState();
    _from = (widget.balance ?? 0).toDouble();
  }

  @override
  void didUpdateWidget(covariant _BalanceCard old) {
    super.didUpdateWidget(old);
    final oldB = old.balance ?? 0;
    final newB = widget.balance ?? 0;
    if (newB != oldB) {
      _from = oldB.toDouble();
      if (newB > oldB) {
        _delta = newB - oldB;
        _burst.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final bal = (widget.balance ?? 0).toDouble();
    final radius = BorderRadius.circular(PaperRadii.card);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      foregroundDecoration: stickerGloss(borderRadius: radius),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.coral, p.coralDeep],
        ),
        borderRadius: radius,
        border: Border.all(color: p.ink, width: 2.5),
        boxShadow: [BoxShadow(color: p.hardShadow, offset: const Offset(4, 4))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.ink, width: 2),
                ),
                // stars, not the sparkle: auto_awesome means "the AI is doing
                // something" in model setup and the X auto-fill, so using it here
                // gave one symbol two meanings. The other two points surfaces
                // already use stars.
                child: Icon(Icons.stars_rounded, color: p.coral, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('pointsBalanceLabel'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedBuilder(
                      animation: _burst,
                      builder: (context, _) {
                        // Single soft pop on increase.
                        final pop = 1 + 0.2 * math.sin(math.pi * _burst.value);
                        return Transform.scale(
                          scale: _burst.isAnimating ? pop : 1.0,
                          alignment: Alignment.centerLeft,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: _from, end: bal),
                            duration: const Duration(milliseconds: 650),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, child) => Text(
                              widget.unknown ? '—' : '${v.round()}',
                              style: cuteDisplay(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          // "+N" and sparkles burst out on a gain.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _burst,
                builder: (context, _) {
                  final t = _burst.value;
                  if (t == 0 || t >= 1) return const SizedBox.shrink();
                  final fade = (1 - t).clamp(0.0, 1.0);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: 6,
                        top: 10 - 42 * t,
                        child: Opacity(
                          opacity: fade,
                          child: Text(
                            '+$_delta',
                            style: cuteDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      for (final (dx, dy, sz, ph) in const [
                        (0.62, 0.15, 16.0, 0.0),
                        (0.78, 0.55, 12.0, 0.25),
                        (0.9, 0.3, 14.0, 0.5),
                        (0.7, 0.8, 10.0, 0.15),
                      ])
                        Positioned(
                          left: null,
                          right: 40 - 60 * dx * t,
                          top: 8 + 46 * dy - 26 * t,
                          child: Opacity(
                            opacity: (fade - ph).clamp(0.0, 1.0),
                            child: Text(
                              '✦',
                              style: TextStyle(
                                fontSize: sz,
                                color: Colors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
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
