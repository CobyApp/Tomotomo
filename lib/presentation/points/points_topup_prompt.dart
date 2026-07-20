import 'package:flutter/material.dart';

import '../../core/ui/paper/paper_bottom_sheet.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../locale/l10n_context.dart';
import 'points_usage_screen.dart';

Future<void> showPointsTopUpPrompt(BuildContext context) async {
  final open = await showPaperSheet<bool>(
    context,
    builder: (ctx) {
      final p = ctx.paper;
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
                    ctx.tr('pointsInsufficientTitle'),
                    style: TextStyle(
                      color: p.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ctx.tr('pointsInsufficientBody'),
              style: TextStyle(color: p.inkSoft, height: 1.4),
            ),
            const SizedBox(height: 20),
            PaperButton(
              icon: Icons.play_circle_fill_rounded,
              label: ctx.tr('pointsEarnAction'),
              onPressed: () => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  ctx.tr('cancel'),
                  style: TextStyle(color: p.inkSoft, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
  if (open == true && context.mounted) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PointsUsageScreen()),
    );
  }
}
