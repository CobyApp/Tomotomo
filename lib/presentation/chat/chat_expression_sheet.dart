import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/language/dm_utterance_script.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/saved_expression.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../../domain/repositories/saved_expression_repository.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import '../notebook/word_book_refresh_notifier.dart';

Future<void> _launchChatMessageReportEmail(
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
  await _launchChatMessageReportEmail(
    context,
    message: message,
    character: character,
  );
}

/// Bottom sheet: message, per-word [+] saves **that word only** (headword + gloss) to the word book.
Future<void> showChatExpressionSheet(
  BuildContext context, {
  required ChatMessage message,
  required Character character,
  String? chatRoomId,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final rootLang = context.read<LocaleNotifier>().languageCode;
  final dmScript = character.isDirectMessage
      ? resolveDmUtteranceScript(message.content, appLanguageCode: rootLang)
      : null;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Center(
                child: Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            Flexible(
              child: _ExpressionSheetBody(
                message: message,
                character: character,
                chatRoomId: chatRoomId,
                messenger: messenger,
                dmScript: dmScript,
              ),
            ),
          ],
        ),
      );
    },
  );
}

String _vocabTranslationLine(Vocabulary v) {
  final r = v.reading?.trim();
  if (r != null && r.isNotEmpty) {
    return '$r — ${v.meaning}';
  }
  return v.meaning;
}

class _ExpressionSheetBody extends StatefulWidget {
  final ChatMessage message;
  final Character character;
  final String? chatRoomId;
  final ScaffoldMessengerState messenger;
  final DmUtteranceScript? dmScript;

  const _ExpressionSheetBody({
    required this.message,
    required this.character,
    required this.chatRoomId,
    required this.messenger,
    required this.dmScript,
  });

  @override
  State<_ExpressionSheetBody> createState() => _ExpressionSheetBodyState();
}

class _ExpressionSheetBodyState extends State<_ExpressionSheetBody> {
  final Set<int> _savedWordIndices = {};
  final Set<int> _savingIndices = {};
  ChatMessage? _fetchedLineAnalysis;
  bool _lineFetchLoading = false;
  String? _lineFetchError;

  bool _shouldFetchLineAnalysis() {
    final raw = widget.message.content.trim();
    if (raw.isEmpty || DmVoiceMessage.isVoiceContent(raw)) return false;
    if (widget.character.isDirectMessage) return widget.dmScript != null;
    return true;
  }

  @override
  void initState() {
    super.initState();
    if (_shouldFetchLineAnalysis()) {
      _lineFetchLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadLineAnalysis());
    }
  }

  Future<void> _loadLineAnalysis() async {
    if (!mounted || !_shouldFetchLineAnalysis()) return;
    setState(() {
      _lineFetchLoading = true;
      _lineFetchError = null;
    });
    try {
      final appLang = context.read<LocaleNotifier>().languageCode;
      final ai = context.read<AiChatRepository>();
      final result = await ai.generateDmExpressionAnalysis(widget.message.content, appUiLanguageCode: appLang);
      if (!mounted) return;
      setState(() {
        _fetchedLineAnalysis = result;
        _lineFetchLoading = false;
        _lineFetchError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lineFetchLoading = false;
        _lineFetchError = e.toString();
      });
    }
  }

  List<Vocabulary>? get _effectiveVocabulary =>
      _fetchedLineAnalysis?.vocabulary ?? widget.message.vocabulary;

  String? get _effectiveLineTranslation =>
      _fetchedLineAnalysis?.lineTranslation ?? widget.message.lineTranslation;

  String? get _effectiveExplanation =>
      _fetchedLineAnalysis?.explanation ?? widget.message.explanation;

  bool get _vocabMeaningUsesHangul {
    if (!widget.character.isDirectMessage) return widget.character.expectsKoreanStudyNotes;
    return widget.dmScript == DmUtteranceScript.japaneseHeavy;
  }

  String _notebookLangForDm() {
    if (widget.dmScript == DmUtteranceScript.koreanHeavy) return 'ko';
    if (widget.dmScript == DmUtteranceScript.japaneseHeavy) return 'ja';
    return widget.character.defaultNotebookLangForVocabSave;
  }

  Future<void> _saveWordToNotebook(int index, Vocabulary v) async {
    if (_savedWordIndices.contains(index) || _savingIndices.contains(index)) return;
    final sheetContext = context;
    final repo = sheetContext.read<SavedExpressionRepository>();
    final lang =
        widget.character.isDirectMessage ? _notebookLangForDm() : widget.character.defaultNotebookLangForVocabSave;
    final snackText = lang == 'ko'
        ? sheetContext.trRead('wordAddedToNotebookKo')
        : sheetContext.trRead('wordAddedToNotebookJa');
    final loginRequiredText = sheetContext.trRead('loginRequired');
    final saveFailedPrefix = sheetContext.trRead('wordSaveNotebookFailed');
    setState(() => _savingIndices.add(index));
    try {
      await repo.add(
        SavedExpressionDraft(
          source: 'chat',
          notebookLang: lang,
          content: v.word,
          translation: _vocabTranslationLine(v),
          roomId: widget.chatRoomId,
        ),
      );
      if (!mounted) return;
      await HapticFeedback.mediumImpact();
      setState(() {
        _savedWordIndices.add(index);
        _savingIndices.remove(index);
      });
      widget.messenger.showSnackBar(SnackBar(content: Text(snackText)));
      if (sheetContext.mounted) {
        sheetContext.read<WordBookRefreshNotifier>().requestRefresh();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingIndices.remove(index));
      final isAuth = e is StateError && e.message.contains('Not signed');
      final body = isAuth ? loginRequiredText : '$saveFailedPrefix\n$e';
      widget.messenger.showSnackBar(SnackBar(content: Text(body)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetContext = context;
    final message = widget.message;
    final character = widget.character;
    final tr = sheetContext.tr;
    final dm = widget.dmScript;
    final scheme = Theme.of(sheetContext).colorScheme;

    final messageStyle = TextStyle(
      fontSize: 15,
      height: 1.45,
      color: scheme.onSurface,
      fontFamily: character.assistantMessagePrefersHangulFont ? 'Pretendard' : null,
    );
    final meaningStyle = TextStyle(
      fontSize: 13,
      height: 1.4,
      color: scheme.onSurfaceVariant,
      fontFamily: _vocabMeaningUsesHangul ? 'Pretendard' : null,
    );
    final sectionLabelStyle = TextStyle(
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: scheme.primary,
      letterSpacing: 0.2,
    );
    final sectionBodyStyle = TextStyle(
      fontSize: 14,
      height: 1.45,
      color: scheme.onSurface,
      fontFamily: character.assistantMessagePrefersHangulFont ? 'Pretendard' : null,
    );
    final vocabWordUsesPretendard = character.koreanNationalPersona ||
        (character.isDirectMessage && dm == DmUtteranceScript.koreanHeavy);
    final wordStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
      fontFamily: vocabWordUsesPretendard ? 'Pretendard' : null,
    );

    final fetchLine = _shouldFetchLineAnalysis();
    final translation = _effectiveLineTranslation?.trim();
    final note = _effectiveExplanation?.trim();
    final showTranslation = translation != null && translation.isNotEmpty;
    final showNote = note != null && note.isNotEmpty;

    final translationUsesHangul = character.isDirectMessage
        ? dm != DmUtteranceScript.koreanHeavy
        : character.expectsKoreanStudyNotes;

    Widget sectionBlock(String label, String body, {bool useHangulBody = false}) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: sectionLabelStyle),
            const SizedBox(height: 6),
            Text(
              body,
              style: sectionBodyStyle.copyWith(
                fontFamily: useHangulBody ? 'Pretendard' : sectionBodyStyle.fontFamily,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message.content, style: messageStyle),
          if (fetchLine) ...[
            const SizedBox(height: 12),
            if (_lineFetchLoading)
              Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: character.primaryColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr('expressionAnalysisLoading'),
                      style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            if (_lineFetchError != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tr('expressionAnalysisFailed')}\n$_lineFetchError',
                    style: TextStyle(fontSize: 12, height: 1.35, color: scheme.error),
                  ),
                  TextButton.icon(
                    onPressed: _loadLineAnalysis,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(tr('expressionDmRetry')),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
          ],
          if (showTranslation)
            sectionBlock(
              tr('expressionFullTranslationLabel'),
              translation,
              useHangulBody: translationUsesHangul,
            ),
          if (showNote)
            sectionBlock(
              tr('expressionLearningNoteLabel'),
              note,
              useHangulBody: context.read<LocaleNotifier>().languageCode == 'ko',
            ),
          if (_effectiveVocabulary != null && _effectiveVocabulary!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 10),
            ..._effectiveVocabulary!.asMap().entries.map((e) {
              final i = e.key;
              final vocab = e.value;
              final done = _savedWordIndices.contains(i);
              final hasReading = vocab.reading != null && vocab.reading!.trim().isNotEmpty;

              return Padding(
                padding: EdgeInsets.only(bottom: i < _effectiveVocabulary!.length - 1 ? 10 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              style: wordStyle,
                              children: [
                                TextSpan(text: vocab.word),
                                if (hasReading)
                                  TextSpan(
                                    text: ' (${vocab.reading})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(vocab.meaning, style: meaningStyle),
                        ],
                      ),
                    ),
                    Tooltip(
                      message: done
                          ? tr('expressionWordSavedTooltip')
                          : _savingIndices.contains(i)
                              ? tr('expressionWordSavingTooltip')
                              : tr('addWordToNotebookTooltip'),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: _savingIndices.contains(i)
                            ? Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: character.primaryColor,
                                  ),
                                ),
                              )
                            : IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                onPressed: done ? null : () => _saveWordToNotebook(i, vocab),
                                icon: Icon(
                                  done ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                  size: 26,
                                  color: done ? Colors.green.shade700 : character.primaryColor,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else if (fetchLine && (_lineFetchLoading || _lineFetchError != null))
            const SizedBox.shrink()
          else if (character.isDirectMessage && dm != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                dm == DmUtteranceScript.koreanHeavy ? tr('expressionMissingVocabularyJa') : tr('expressionMissingVocabulary'),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: scheme.tertiary,
                  fontFamily: dm == DmUtteranceScript.japaneseHeavy ? 'Pretendard' : null,
                ),
              ),
            )
          else if (character.expectsKoreanStudyNotes)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                tr('expressionMissingVocabulary'),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: scheme.tertiary,
                  fontFamily: 'Pretendard',
                ),
              ),
            )
          else if (character.expectsJapaneseStudyNotes)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                tr('expressionMissingVocabularyJa'),
                style: TextStyle(fontSize: 13, height: 1.35, color: scheme.tertiary),
              ),
            ),
        ],
      ),
    );
  }
}
