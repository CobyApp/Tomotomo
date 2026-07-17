import 'package:flutter/material.dart';

import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/journal_note.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../locale/l10n_context.dart';
import 'points_topup_screen.dart';

/// Explains when points are spent (opened from the balance chip or Settings).
class PointsUsageScreen extends StatelessWidget {
  const PointsUsageScreen({super.key});

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
          8,
          AppSpacing.pageH,
          AppSpacing.pageBottom,
        ),
        children: [
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
          const SizedBox(height: 20),
          Center(
            child: PaperButton(
              expand: false,
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
