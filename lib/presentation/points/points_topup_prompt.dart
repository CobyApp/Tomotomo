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
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(context.tr('pointsTopupBuy')),
        ),
      ],
    ),
  );
  if (open == true && context.mounted) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PointsTopUpScreen()),
    );
  }
}
