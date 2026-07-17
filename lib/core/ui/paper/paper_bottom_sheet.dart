import 'package:flutter/material.dart';
import 'paper_tokens.dart';

/// Shows a rounded PAPER-CARTOON modal bottom sheet with a grab handle.
Future<T?> showPaperSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final p = sheetContext.paper;
      return SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: p.paperBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: p.cardEdge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.cardEdge,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(child: builder(sheetContext)),
            ],
          ),
        ),
      );
    },
  );
}
