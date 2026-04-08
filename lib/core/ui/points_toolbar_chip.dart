import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../presentation/locale/l10n_context.dart';
import '../../presentation/points/points_balance_notifier.dart';
import '../../presentation/points/points_usage_screen.dart';
import 'app_tokens.dart';

void openPointsUsageScreen(BuildContext context) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const PointsUsageScreen()),
  );
}

/// Compact balance display for [AppPageScaffold.actions] / chat app bars. Tap opens [PointsUsageScreen].
class PointsToolbarChip extends StatelessWidget {
  const PointsToolbarChip({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bal = context.watch<PointsBalanceNotifier>().balance;
    final label = bal != null ? '$bal' : '—';

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: Material(
        color: scheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: InkWell(
          onTap: () => openPointsUsageScreen(context),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded, size: 16, color: scheme.secondary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSecondaryContainer,
                      ),
                ),
                const SizedBox(width: 2),
                Tooltip(
                  message: context.tr('pointsChipTooltip'),
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 14,
                    color: scheme.onSecondaryContainer.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
