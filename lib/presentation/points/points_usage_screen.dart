import 'package:flutter/material.dart';

import '../../core/ui/ui.dart';
import '../locale/l10n_context.dart';

/// Explains when points are spent (opened from the balance chip or Settings).
class PointsUsageScreen extends StatelessWidget {
  const PointsUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.45,
          color: scheme.onSurface,
        );
    final bulletStyle = bodyStyle?.copyWith(fontWeight: FontWeight.w500);

    Widget bullet(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: bulletStyle),
            Expanded(child: Text(text, style: bodyStyle)),
          ],
        ),
      );
    }

    return AppPageScaffold(
      title: context.tr('pointsHelpTitle'),
      subtitle: context.tr('pointsHelpLead'),
      transparentBackground: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          8,
          AppSpacing.pageH,
          AppSpacing.pageBottom,
        ),
        children: [
          Text(
            context.tr('pointsHelpSectionWhen'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          bullet(context.tr('pointsHelpItemSignup')),
          bullet(context.tr('pointsHelpItemXImport')),
          bullet(context.tr('pointsHelpItemCharacterChat')),
          bullet(context.tr('pointsHelpItemDmLearning')),
          bullet(context.tr('pointsHelpItemPublicChar')),
          bullet(context.tr('pointsHelpItemCustomCreate')),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Text(
              context.tr('pointsHelpFooter'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.4,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
