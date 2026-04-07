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

String _expressionSheetTitle(String Function(String key) tr) {
  return tr('expressionExplanationTitle');
}

String _expressionVocabHeading(Character c, String Function(String key) tr) {
  if (c.tutorLocale == 'ja') return tr('expressionSectionVocabJaImmersion');
  if (c.koreanNationalPersona) return tr('expressionSectionVocabKoToJaNote');
  return tr('expressionSectionVocabJaToKo');
}

String _expressionVocabHintLine(Character c, String Function(String key) tr) {
  if (c.tutorLocale == 'ja') return tr('expressionVocabAddHintImmersion');
  if (c.koreanNationalPersona) return tr('expressionVocabAddHintKoFriend');
  return tr('expressionVocabAddHintKoNotebook');
}

String _dmVocabHeading(DmUtteranceScript s, String Function(String key) tr) {
  switch (s) {
    case DmUtteranceScript.japaneseHeavy:
      return tr('expressionSectionVocabJaToKo');
    case DmUtteranceScript.koreanHeavy:
      return tr('expressionSectionVocabKoToJaNote');
    case DmUtteranceScript.ambiguous:
      return tr('expressionSectionVocabulary');
  }
}

String _dmVocabHint(DmUtteranceScript s, String Function(String key) tr) {
  switch (s) {
    case DmUtteranceScript.japaneseHeavy:
      return tr('expressionVocabAddHintKoNotebook');
    case DmUtteranceScript.koreanHeavy:
      return tr('expressionVocabAddHintKoFriend');
    case DmUtteranceScript.ambiguous:
      return tr('expressionVocabAddHint');
  }
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
    builder: (sheetContext) => Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: character.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _expressionSheetTitle(sheetContext.tr),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: character.primaryColor,
                      fontFamily: 'Pretendard',
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.flag, color: Colors.red, size: 20),
                    onPressed: () async {
                      final subject = sheetContext.tr('expressionDmReportSubject');
                      final bodyPrefix = dmScript == DmUtteranceScript.koreanHeavy
                          ? sheetContext.tr('expressionDmReportBodyPrefixJa')
                          : sheetContext.tr('expressionDmReportBodyPrefixKo');
                      final body = '$bodyPrefix${message.content}\n\n${sheetContext.tr('expressionDmReportReasonLabel')}\n';
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
                    },
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
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
    ),
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
  ChatMessage? _dmAnalysis;
  bool _dmLoading = false;
  String? _dmError;

  @override
  void initState() {
    super.initState();
    if (widget.character.isDirectMessage && widget.dmScript != null) {
      _dmLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadDmAnalysis());
    }
  }

  Future<void> _loadDmAnalysis() async {
    if (!mounted || widget.dmScript == null) return;
    setState(() {
      _dmLoading = true;
      _dmError = null;
    });
    try {
      final appLang = context.read<LocaleNotifier>().languageCode;
      final ai = context.read<AiChatRepository>();
      final result = await ai.generateDmExpressionAnalysis(widget.message.content, appUiLanguageCode: appLang);
      if (!mounted) return;
      setState(() {
        _dmAnalysis = result;
        _dmLoading = false;
        _dmError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dmLoading = false;
        _dmError = e.toString();
      });
    }
  }

  List<Vocabulary>? get _effectiveVocabulary => _dmAnalysis?.vocabulary ?? widget.message.vocabulary;

  /// Vocabulary gloss line uses Hangul (needs Pretendard) vs Japanese-only.
  bool get _vocabMeaningUsesHangul {
    if (!widget.character.isDirectMessage) return widget.character.expectsKoreanStudyNotes;
    return widget.dmScript == DmUtteranceScript.japaneseHeavy;
  }

  bool get _meaningStyleHangul => _vocabMeaningUsesHangul;

  bool get _koPhraseVocabLayout {
    return widget.character.koreanNationalPersona ||
        (widget.character.isDirectMessage && widget.dmScript == DmUtteranceScript.koreanHeavy);
  }

  bool get _showJaSurfaceMeaningLabel {
    if (!widget.character.isDirectMessage) return true;
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
    final vocabHeading =
        character.isDirectMessage && dm != null ? _dmVocabHeading(dm, tr) : _expressionVocabHeading(character, tr);
    final vocabHint =
        character.isDirectMessage && dm != null ? _dmVocabHint(dm, tr) : _expressionVocabHintLine(character, tr);

    final messageStyle = TextStyle(
      fontSize: 15,
      height: 1.55,
      color: Colors.grey[800],
      fontFamily: character.assistantMessagePrefersHangulFont ? 'Pretendard' : null,
    );
    final meaningStyle = TextStyle(
      fontSize: 14,
      color: Colors.grey[700],
      height: 1.5,
      fontFamily: _meaningStyleHangul ? 'Pretendard' : null,
    );
    final wordStyle = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: Colors.grey[900],
    );
    final koreanGlossHeadlineStyle = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.45,
      color: Colors.grey[900],
      fontFamily: 'Pretendard',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('expressionSectionUtterance'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(message.content, style: messageStyle),
          ),
          if (character.isDirectMessage && dm != null) ...[
            const SizedBox(height: 18),
            if (_dmLoading)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: character.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('expressionDmLoadingVocab'),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            if (_dmError != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tr('expressionDmFailedVocab')}\n$_dmError',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _loadDmAnalysis,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(tr('expressionDmRetry')),
                  ),
                ],
              ),
          ],
          const SizedBox(height: 22),
          Text(
            vocabHeading,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: character.primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            vocabHint,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.35),
          ),
          const SizedBox(height: 12),
          if (_effectiveVocabulary != null && _effectiveVocabulary!.isNotEmpty)
            ..._effectiveVocabulary!.asMap().entries.map((e) {
              final i = e.key;
              final vocab = e.value;
              final done = _savedWordIndices.contains(i);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_koPhraseVocabLayout) ...[
                                Text(vocab.word, style: koreanGlossHeadlineStyle),
                                if (vocab.reading != null && vocab.reading!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '(${vocab.reading})',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Text(
                                  tr('expressionVocabJaMeaningForKoPhrase'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  vocab.meaning,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                    height: 1.5,
                                  ),
                                ),
                              ] else ...[
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(vocab.word, style: wordStyle),
                                    if (vocab.reading != null && vocab.reading!.isNotEmpty)
                                      Text(
                                        '(${vocab.reading})',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                                if (_showJaSurfaceMeaningLabel) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    character.expectsKoreanStudyNotes
                                        ? tr('expressionVocabLineMeaningKo')
                                        : tr('expressionVocabLineMeaningJa'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(vocab.meaning, style: meaningStyle),
                              ],
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
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
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
                                      size: 28,
                                      color: done ? Colors.green.shade700 : character.primaryColor,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            })
          else if (character.isDirectMessage && dm != null && (_dmLoading || _dmError != null))
            const SizedBox.shrink()
          else if (character.isDirectMessage && dm != null)
            Text(
              dm == DmUtteranceScript.koreanHeavy ? tr('expressionMissingVocabularyJa') : tr('expressionMissingVocabulary'),
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.orange.shade800,
                fontFamily: dm == DmUtteranceScript.japaneseHeavy ? 'Pretendard' : null,
              ),
            )
          else if (character.expectsKoreanStudyNotes)
            Text(
              tr('expressionMissingVocabulary'),
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.orange.shade800,
                fontFamily: 'Pretendard',
              ),
            )
          else if (character.expectsJapaneseStudyNotes)
            Text(
              tr('expressionMissingVocabularyJa'),
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.orange.shade800,
              ),
            ),
        ],
      ),
    );
  }
}
