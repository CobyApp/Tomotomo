import 'package:flutter/material.dart';

import '../../core/ui/holo/holo_tokens.dart';
import '../../core/ui/holo/holo_widgets.dart';
import '../../core/ui/ui.dart';
import '../locale/l10n_context.dart';
import 'points_topup_screen.dart';

/// Explains when points are spent (opened from the balance chip or Settings).
class PointsUsageScreen extends StatelessWidget {
  const PointsUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(height: 1.45, color: Holo.inkPlum);
    const bulletStyle = TextStyle(
      height: 1.45,
      color: Holo.inkPlum,
      fontWeight: FontWeight.w500,
    );

    Widget bullet(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: bulletStyle),
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
              color: Holo.pink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          bullet(context.tr('pointsHelpItemXImport')),
          bullet(context.tr('pointsHelpItemCharacterChat')),
          bullet(context.tr('pointsHelpItemCustomCreate')),
          const SizedBox(height: 8),
          HoloCard(
            dashed: true,
            child: Text(
              context.tr('pointsHelpFooter'),
              style: const TextStyle(height: 1.4, color: Holo.inkPlumSoft),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: HoloButton(
              icon: Icons.play_circle_fill_rounded,
              label: context.tr('pointsEarnAction'),
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const PointsTopUpScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
