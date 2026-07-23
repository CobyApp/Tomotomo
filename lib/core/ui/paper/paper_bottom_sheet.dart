import 'package:flutter/material.dart';
import 'paper_tokens.dart';

/// Shows a rounded cyber modal bottom sheet with a neon grab handle and an
/// explicit close button. Capped to 90% height, dismissible by drag, close
/// button, or tapping the scrim — so it's always easy to get out of.
Future<T?> showPaperSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (sheetContext) {
      final p = sheetContext.paper;
      final maxH = MediaQuery.of(sheetContext).size.height * 0.9;
      return SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Container(
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              border: Border.all(color: p.stampBlue.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: p.coral.withValues(alpha: 0.18),
                  blurRadius: 26,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle + close row.
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 2),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: [p.coral, p.stampBlue],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: Icon(Icons.close_rounded, color: p.inkSoft),
                          tooltip: 'Close',
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(child: builder(sheetContext)),
              ],
            ),
          ),
        ),
      );
    },
  );
}
