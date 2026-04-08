import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/language/dm_utterance_script.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';

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
  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    path: 'dime0801001@gmail.com',
    queryParameters: {'subject': subject, 'body': body},
  );
  try {
    final result = await launchUrl(
      emailLaunchUri,
      mode: LaunchMode.externalApplication,
    );
    if (!result) {
      final gmailUri = Uri.parse(
        'https://mail.google.com/mail/?view=cm&fs=1&to=dime0801001@gmail.com&su=$subject&body=$body',
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
