import 'package:flutter/material.dart';

import '../../core/ui/holo/holo_tokens.dart';
import '../../core/ui/holo/holo_widgets.dart';
import '../locale/l10n_context.dart';
import 'points_topup_screen.dart';

Future<void> showPointsTopUpPrompt(BuildContext context) async {
  final open = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: HoloCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: Holo.pink, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('pointsInsufficientTitle'),
                    style: const TextStyle(
                      color: Holo.inkPlum,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('pointsInsufficientBody'),
              style: const TextStyle(color: Holo.inkPlumSoft, height: 1.4),
            ),
            const SizedBox(height: 20),
            HoloButton(
              icon: Icons.play_circle_fill_rounded,
              label: context.tr('pointsEarnAction'),
              onPressed: () => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  context.tr('cancel'),
                  style: const TextStyle(
                    color: Holo.inkPlumSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (open == true && context.mounted) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PointsTopUpScreen()),
    );
  }
}
