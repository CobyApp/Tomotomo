import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../presentation/locale/l10n_context.dart';
import '../../presentation/points/points_balance_notifier.dart';
import '../../presentation/points/points_usage_screen.dart';
import 'paper/paper_tokens.dart';

void openPointsUsageScreen(BuildContext context) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const PointsUsageScreen()),
  );
}

/// Compact balance display for [AppPageScaffold.actions] / chat app bars. Tap opens [PointsUsageScreen].
/// Thin wrapper that watches the balance and hands it down to [_PointsChipAnimated]
/// as a constructor value, so balance changes are visible to [State.didUpdateWidget].
class PointsToolbarChip extends StatelessWidget {
  const PointsToolbarChip({super.key});

  @override
  Widget build(BuildContext context) {
    final bal = context.watch<PointsBalanceNotifier>().balance;
    return _PointsChipAnimated(balance: bal);
  }
}

class _PointsChipAnimated extends StatefulWidget {
  const _PointsChipAnimated({required this.balance});

  final int? balance;

  @override
  State<_PointsChipAnimated> createState() => _PointsChipAnimatedState();
}

class _PointsChipAnimatedState extends State<_PointsChipAnimated>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash;

  @override
  void initState() {
    super.initState();
    _flash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant _PointsChipAnimated oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBal = oldWidget.balance;
    final newBal = widget.balance;
    if (oldBal != null && newBal != null && newBal > oldBal) {
      _flash.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.balance != null ? '${widget.balance}' : '—';
    final p = context.paper;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 2),
      child: Tooltip(
        message: context.tr('pointsChipTooltip'),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => openPointsUsageScreen(context),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedBuilder(
              animation: _flash,
              builder: (context, child) {
                // Short pop + stamp-ink flash toward stampBlue on balance
                // increase, settles back to the plain dashed-ticket look.
                final t = _flash.value;
                final pulse = t < 0.5 ? t * 2 : (1 - t) * 2;
                final scale = 1.0 + 0.16 * pulse;
                final borderColor =
                    Color.lerp(p.coral, p.stampBlue, pulse) ?? p.coral;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: borderColor, width: 1.5),
                      boxShadow: pulse > 0
                          ? [
                              BoxShadow(
                                color: p.stampBlue.withValues(
                                  alpha: 0.45 * pulse,
                                ),
                                blurRadius: 14,
                              ),
                            ]
                          : const [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 15,
                          color: borderColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: borderColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
