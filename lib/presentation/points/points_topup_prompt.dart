import 'package:flutter/material.dart';

import '../locale/l10n_context.dart';
import 'points_topup_screen.dart';

Future<void> showPointsTopUpPrompt(BuildContext context) async {
  final open = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.tr('pointsInsufficientTitle')),
      content: Text(context.tr('pointsInsufficientBody')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(context.tr('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(context.tr('adEarnWatch')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(context.tr('pointsTopupBuy')),
        ),
      ],
    ),
  );
  // Both the "watch ad" and "buy" actions lead here — the ad-earning card
  // lives at the top of the top-up screen, so either path reaches it.
  if (open == true && context.mounted) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PointsTopUpScreen()),
    );
  }
}
