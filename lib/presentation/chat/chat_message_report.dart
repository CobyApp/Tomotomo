import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ui/paper/paper_dialog.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../locale/l10n_context.dart';

const String _reportMailTo = 'dime0801001@gmail.com';

Future<void> _launchReportMail({
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
    if (!result) {
      final encSubject = Uri.encodeComponent(subject);
      final encBody = Uri.encodeComponent(body);
      final gmailUri = Uri.parse(
        'https://mail.google.com/mail/?view=cm&fs=1&to=$_reportMailTo&su=$encSubject&body=$encBody',
      );
      await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    debugPrint('Failed to launch email: $e');
  }
}

Future<void> _openReportMailDraft(
  BuildContext context, {
  required ChatMessage message,
}) async {
  final tr = context.tr;
  final subject = tr('chatReportSubject');
  final body =
      '${tr('chatReportBodyPrefix')}${message.content}\n\n${tr('chatReportReasonLabel')}\n';
  await _launchReportMail(subject: subject, body: body);
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
  await _openReportMailDraft(context, message: message);
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
      '${tr('chatRoomReportBodyPrefix')}'
      '${tr('chatRoomReportFieldRoom')}: ${chatRoomId ?? '-'}\n'
      '${tr('chatRoomReportFieldType')}: $typeLine\n'
      '${tr('chatRoomReportFieldName')}: ${character.displayNamePrimary}\n\n'
      '${tr('chatReportReasonLabel')}\n';
  await _launchReportMail(subject: subject, body: body);
}
