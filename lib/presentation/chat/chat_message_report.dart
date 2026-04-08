import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/language/dm_utterance_script.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';

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
      await launchUrl(
        gmailUri,
        mode: LaunchMode.externalApplication,
      );
    }
  } catch (e) {
    debugPrint('Failed to launch email: $e');
  }
}

Future<void> _openReportMailDraft(
  BuildContext context, {
  required ChatMessage message,
  required Character character,
}) async {
  final rootLang = context.read<LocaleNotifier>().languageCode;
  final dmScript = character.isDirectMessage
      ? resolveDmUtteranceScript(message.content, appLanguageCode: rootLang)
      : null;
  final tr = context.tr;
  final subject = tr('expressionDmReportSubject');
  final bodyPrefix = dmScript == DmUtteranceScript.koreanHeavy
      ? tr('expressionDmReportBodyPrefixJa')
      : tr('expressionDmReportBodyPrefixKo');
  final body = '$bodyPrefix${message.content}\n\n${tr('expressionDmReportReasonLabel')}\n';
  await _launchReportMail(subject: subject, body: body);
}

/// Long-press on a chat bubble: ask, then open the report mail draft.
Future<void> confirmAndReportChatMessage(
  BuildContext context, {
  required ChatMessage message,
  required Character character,
}) async {
  final tr = context.tr;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tr('chatReportDialogTitle')),
      content: Text(tr('chatReportDialogBody')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(tr('chatReportCancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(tr('chatReportConfirm')),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await _openReportMailDraft(
    context,
    message: message,
    character: character,
  );
}

/// Report the whole chat (from ⋮ menu): mail draft with room / peer context.
Future<void> confirmAndReportChatRoom(
  BuildContext context, {
  required Character character,
  String? chatRoomId,
}) async {
  final tr = context.tr;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tr('chatRoomReportDialogTitle')),
      content: Text(tr('chatRoomReportDialogBody')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(tr('chatReportCancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(tr('chatReportConfirm')),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final subject = tr('chatRoomReportSubject');
  final typeLine = character.isDirectMessage ? tr('chatRoomReportTypeDm') : tr('chatRoomReportTypeAi');
  final body = '${tr('chatRoomReportBodyPrefix')}'
      '${tr('chatRoomReportFieldRoom')}: ${chatRoomId ?? '-'}\n'
      '${tr('chatRoomReportFieldType')}: $typeLine\n'
      '${tr('chatRoomReportFieldName')}: ${character.displayNamePrimary}\n\n'
      '${tr('expressionDmReportReasonLabel')}\n';
  await _launchReportMail(subject: subject, body: body);
}
