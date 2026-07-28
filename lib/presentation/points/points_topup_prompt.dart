import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ads/ad_config.dart';
import '../../core/ads/rewarded_ad_service.dart';
import '../../core/ui/app_scaffold_messenger.dart';
import '../../core/ui/paper/paper_bottom_sheet.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../../data/repositories/local_points_repository_impl.dart';
import '../locale/l10n_context.dart';
import 'points_balance_notifier.dart';
import 'points_usage_screen.dart';

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

  String _today() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _watchAd() async {
    if (_watching) return;
    setState(() => _watching = true);
    final ad = context.read<RewardedAdService>();
    final points = context.read<LocalPointsRepositoryImpl>();
    final notifier = context.read<PointsBalanceNotifier>();
    final navigator = Navigator.of(context);
    final notReadyText = context.trRead('adEarnNotReady');

    var credited = false;
    final shown = await ad.show(
      onEarned: () async {
        final r = await points.recordAdReward(today: _today());
        if (!r.credited) return;
        credited = true;
        notifier.setBalance(r.balance);
      },
    );

    if (!mounted) return;
    setState(() => _watching = false);
    // The sheet may outlive the screen underneath, so the app-level messenger
    // (not this context's) is what can safely show the confirmation.
    if (shown) {
      if (credited) {
        appScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('+${AdConfig.pointsPerAd}pt')),
        );
      }
      // Close so the user lands right back on the action they were doing.
      navigator.pop();
    } else {
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(notReadyText)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final balance = context.watch<PointsBalanceNotifier>().balance;
    final remaining = context
        .read<LocalPointsRepositoryImpl>()
        .adsRemainingToday(today: _today());
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
              busy: _watching,
              onPressed: _watchAd,
            ),
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
