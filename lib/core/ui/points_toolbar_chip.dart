import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../presentation/locale/l10n_context.dart';
import '../../presentation/points/points_balance_notifier.dart';
import 'app_tokens.dart';

/// Compact balance display for [AppPageScaffold.actions] / chat app bars.
class PointsToolbarChip extends StatelessWidget {
  const PointsToolbarChip({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bal = context.watch<PointsBalanceNotifier>().balance;
    if (bal == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: Material(
        color: scheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stars_rounded, size: 16, color: scheme.secondary),
              const SizedBox(width: 4),
              Text(
                '$bal',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSecondaryContainer,
                    ),
              ),
              const SizedBox(width: 2),
              Tooltip(
                message: context.tr('pointsChipTooltip'),
                child: Icon(Icons.help_outline_rounded, size: 14, color: scheme.onSecondaryContainer.withValues(alpha: 0.75)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
