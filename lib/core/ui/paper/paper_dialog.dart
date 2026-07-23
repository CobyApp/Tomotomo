import 'package:flutter/material.dart';

import 'paper_theme.dart';
import 'paper_tokens.dart';
import '../../../presentation/locale/l10n_context.dart';

/// PAPER-CARTOON styled confirm dialog: cream card surface, cute display
/// title, ink/inkSoft body copy, a [PaperButton]-style primary action and a
/// plain subtle cancel action. Use in place of the default [AlertDialog]
/// for every yes/no confirmation in the app.
///
/// Returns `true` when the primary action is confirmed, `false` when
/// cancelled (including scrim taps / back gesture).
Future<bool> showPaperConfirm(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (dialogContext) => PaperDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel ?? dialogContext.tr('cancel'),
      destructive: destructive,
    ),
  );
  return result ?? false;
}

/// Reusable paper-styled dialog body. Prefer [showPaperConfirm] for the
/// common yes/no case; use this widget directly for custom `showDialog`
/// call sites that need the same chrome.
class PaperDialog extends StatelessWidget {
  const PaperDialog({
    super.key,
    required this.title,
    this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.destructive = false,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    // Muted red for destructive actions — kept in the warm palette family so
    // it reads as "danger" without clashing with the coral brand accent.
    final dangerFill = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFD8503C)
        : const Color(0xFFB3402C);
    final dangerShadow = Color.lerp(dangerFill, Colors.black, 0.28)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(PaperRadii.card + 4),
          border: Border.all(color: p.ink, width: 2.5),
          boxShadow: [
            BoxShadow(color: p.hardShadow, offset: const Offset(5, 5)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: cuteDisplay(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                message!,
                style: TextStyle(fontSize: 14, height: 1.45, color: p.inkSoft),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: p.inkSoft,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(PaperRadii.button),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      cancelLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _PaperDialogConfirmButton(
                    label: confirmLabel,
                    fill: destructive ? dangerFill : p.coralDeep,
                    shadow: destructive
                        ? dangerShadow
                        : Color.lerp(p.coralDeep, Colors.black, 0.28)!,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact [PaperButton]-style press treatment for the dialog's primary
/// action, but sized to share a row with the cancel button rather than
/// expanding to the full dialog width.
class _PaperDialogConfirmButton extends StatefulWidget {
  const _PaperDialogConfirmButton({
    required this.label,
    required this.fill,
    required this.shadow,
    required this.onPressed,
  });

  final String label;
  final Color fill;
  final Color shadow;
  final VoidCallback onPressed;

  @override
  State<_PaperDialogConfirmButton> createState() =>
      _PaperDialogConfirmButtonState();
}

class _PaperDialogConfirmButtonState extends State<_PaperDialogConfirmButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        transform: Matrix4.translationValues(_down ? 3 : 0, _down ? 3 : 0, 0),
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [widget.fill, widget.shadow],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: p.ink, width: 2),
          boxShadow: [
            BoxShadow(color: p.hardShadow, offset: Offset(_down ? 0 : 3, _down ? 0 : 3)),
          ],
        ),
        child: Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
