import 'package:flutter/material.dart';
import '../../../presentation/locale/l10n_context.dart';
import 'paper_tokens.dart';

/// Shows a rounded sticker-style modal bottom sheet with a gradient grab
/// handle and an explicit close button. Capped to 90% height, dismissible by
/// drag, close button, or tapping the scrim — so it's always easy to get out.
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
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: maxH),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              border: Border.all(color: p.ink, width: 2.5),
              boxShadow: [
                BoxShadow(color: p.hardShadow, offset: const Offset(0, -3)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          tooltip: sheetContext.tr('close'),
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
