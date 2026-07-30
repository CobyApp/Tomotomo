import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ui/paper/paper_dialog.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../locale/l10n_context.dart';

const String _reportMailTo = 'dime0801001@gmail.com';

/// Returns false when no mail app and no browser could be opened, so the caller
/// can say so: reporting used to fail in complete silence — the user confirmed
/// the dialog and nothing happened at all (an iPhone with Mail deleted, or a
/// device with no default browser).
Future<bool> _launchReportMail({
  required String subject,
  required String body,
}) async {
  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    path: _reportMailTo,
    queryParameters: {'subject': subject, 'body': body},
  );
  try {
    final result = await launchUrl(
      emailLaunchUri,
      mode: LaunchMode.externalApplication,
    );
    if (result) return true;
    final encSubject = Uri.encodeComponent(subject);
    final encBody = Uri.encodeComponent(body);
    final gmailUri = Uri.parse(
      'https://mail.google.com/mail/?view=cm&fs=1&to=$_reportMailTo&su=$encSubject&body=$encBody',
    );
    return await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Failed to launch email: $e');
    return false;
  }
}

/// Tells the user where to send the report by hand, with the address one tap
/// away on the clipboard.
void _showReportFallback(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 8),
      content: Text(
        context.tr('chatReportNoMailApp', params: {'email': _reportMailTo}),
      ),
      action: SnackBarAction(
        label: context.tr('chatReportCopyAddress'),
        onPressed: () async {
          // Resolved before the await: the snackbar outlives this context.
          final copied = context.trRead('chatReportAddressCopied');
          await Clipboard.setData(const ClipboardData(text: _reportMailTo));
          messenger.showSnackBar(SnackBar(content: Text(copied)));
        },
      ),
    ),
  );
}

Future<bool> _openReportMailDraft(
  BuildContext context, {
  required ChatMessage message,
}) async {
  final tr = context.tr;
  final subject = tr('chatReportSubject');
  final body =
      '${tr('chatReportBodyPrefix')}${message.content}\n\n${tr('chatReportReasonLabel')}\n';
  return _launchReportMail(subject: subject, body: body);
}

/// Long-press on a chat bubble: ask, then open the report mail draft.
Future<void> confirmAndReportChatMessage(
  BuildContext context, {
  required ChatMessage message,
  required Character character,
}) async {
  final tr = context.tr;
  final ok = await showPaperConfirm(
    context,
    title: tr('chatReportDialogTitle'),
    message: tr('chatReportDialogBody'),
    confirmLabel: tr('chatReportConfirm'),
    cancelLabel: tr('chatReportCancel'),
  );
  if (!ok || !context.mounted) return;
  final launched = await _openReportMailDraft(context, message: message);
  if (!launched && context.mounted) _showReportFallback(context);
}

/// Report the whole chat (from ⋮ menu): mail draft with room / peer context.
Future<void> confirmAndReportChatRoom(
  BuildContext context, {
  required Character character,
  String? chatRoomId,
}) async {
  final tr = context.tr;
  final ok = await showPaperConfirm(
    context,
    title: tr('chatRoomReportDialogTitle'),
    message: tr('chatRoomReportDialogBody'),
    confirmLabel: tr('chatReportConfirm'),
    cancelLabel: tr('chatReportCancel'),
  );
  if (!ok || !context.mounted) return;
  final subject = tr('chatRoomReportSubject');
  final typeLine = tr('chatRoomReportTypeAi');
  final body =
      '${tr('chatRoomReportFieldRoom')}: ${chatRoomId ?? '-'}\n'
      '${tr('chatRoomReportFieldType')}: $typeLine\n'
      '${tr('chatRoomReportFieldName')}: ${character.name}\n\n'
      '${tr('chatReportReasonLabel')}\n';
  final launched = await _launchReportMail(subject: subject, body: body);
  if (!launched && context.mounted) _showReportFallback(context);
}
