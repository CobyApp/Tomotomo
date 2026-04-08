import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/language/dm_utterance_script.dart';
import '../../core/ui/app_tokens.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/saved_expression.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../../domain/repositories/points_repository.dart';
import '../../domain/repositories/saved_expression_repository.dart';
import '../points/points_balance_notifier.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import '../notebook/word_book_refresh_notifier.dart';

/// List physics: iOS/macOS bounce + overscroll hands off to [DraggableScrollableSheet]; Android clamps.
ScrollPhysics _chatExpressionSheetListPhysics(BuildContext context) {
  final p = Theme.of(context).platform;
  final iosLike = p == TargetPlatform.iOS || p == TargetPlatform.macOS;
  return AlwaysScrollableScrollPhysics(
    parent: iosLike ? const BouncingScrollPhysics() : const ClampingScrollPhysics(),
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
    useSafeArea: false,
    enableDrag: false,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      final mq = MediaQuery.of(sheetContext);
      final h = mq.size.height;
      final w = mq.size.width;
      // Keep sheet geometry below status bar / notch; list still pads bottom for home indicator.
      final topInset = mq.viewPadding.top;

      return Padding(
        padding: EdgeInsets.only(top: topInset),
        child: SizedBox(
          height: h - topInset,
          width: w,
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.32,
            maxChildSize: 1.0,
            expand: false,
            snap: true,
            snapSizes: const <double>[0.32, 0.58, 0.9, 1.0],
            snapAnimationDuration: const Duration(milliseconds: 280),
            builder: (ctx, scrollController) {
              return Material(
                color: scheme.surface,
                elevation: 10,
                shadowColor: Colors.black26,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Taller grab area (iOS HIG–friendly) without huge visual gap.
                    SizedBox(
                      height: 36,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: scheme.outlineVariant.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _ExpressionSheetBody(
                        scrollController: scrollController,
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
          ),
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
  final ScrollController scrollController;
  final ChatMessage message;
  final Character character;
  final String? chatRoomId;
  final ScaffoldMessengerState messenger;
  final DmUtteranceScript? dmScript;

  const _ExpressionSheetBody({
    required this.scrollController,
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

  /// Tutor replies already include [ChatMessage.lineTranslation] + note/vocab from one JSON — no extra API call.
  static bool _assistantHasBundledAiPayload(ChatMessage m) {
    if (m.role != 'assistant') return false;
    final t = m.lineTranslation?.trim() ?? '';
    if (t.isEmpty) return false;
    final hasV = m.vocabulary != null && m.vocabulary!.isNotEmpty;
    final hasN = m.explanation?.trim().isNotEmpty ?? false;
    return hasV || hasN;
  }

  @override
  void initState() {
    super.initState();
    if (!_shouldFetchLineAnalysis()) return;
    if (_assistantHasBundledAiPayload(widget.message)) return;
    _lineFetchLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLineAnalysis());
  }

  List<Vocabulary>? _vocabularyFromCacheJson(List<Map<String, dynamic>> raw) {
    if (raw.isEmpty) return null;
    final mode = widget.character.vocabularyMeaningPickMode;
    final out = <Vocabulary>[];
    for (final m in raw) {
      final v = Vocabulary.tryParseLoose(m, meaningMode: mode);
      if (v != null) out.add(v);
    }
    return out.isEmpty ? null : out;
  }

  Future<void> _loadLineAnalysis() async {
    if (!mounted || !_shouldFetchLineAnalysis()) return;
    if (_assistantHasBundledAiPayload(widget.message)) {
      setState(() {
        _lineFetchLoading = false;
        _lineFetchError = null;
      });
      return;
    }
    setState(() {
      _lineFetchLoading = true;
      _lineFetchError = null;
    });
    final appLang = context.read<LocaleNotifier>().languageCode;
    final mid = widget.message.serverId;
    final points = context.read<PointsRepository>();

    try {
      if (mid != null) {
        final cached = await points.getLineAnalysisCache(mid, appLang);
        if (!mounted) return;
        if (cached != null) {
          final vocab = _vocabularyFromCacheJson(cached.vocabularyJson);
          final hasPayload = (cached.explanation != null && cached.explanation!.trim().isNotEmpty) ||
              (cached.lineTranslation != null && cached.lineTranslation!.trim().isNotEmpty) ||
              (vocab != null && vocab.isNotEmpty);
          if (hasPayload) {
            setState(() {
              _fetchedLineAnalysis = ChatMessage(
                serverId: widget.message.serverId,
                content: widget.message.content,
                role: widget.message.role,
                timestamp: widget.message.timestamp,
                explanation: cached.explanation,
                lineTranslation: cached.lineTranslation,
                vocabulary: vocab,
                senderId: widget.message.senderId,
              );
              _lineFetchLoading = false;
              _lineFetchError = null;
            });
            return;
          }
        }
      }

      if (widget.character.isDirectMessage && mid != null) {
        final unlock = await points.tryUnlockDmExpression(mid);
        if (!mounted) return;
        if (unlock.ok) {
          context.read<PointsBalanceNotifier>().setBalance(unlock.balance);
        } else {
          setState(() {
            _lineFetchLoading = false;
            _lineFetchError = unlock.error == 'insufficient_points'
                ? context.trRead('pointsInsufficient')
                : (unlock.error ?? context.trRead('expressionAnalysisFailed'));
          });
          return;
        }
      }

      final ai = context.read<AiChatRepository>();
      final result = await ai.generateDmExpressionAnalysis(widget.message.content, appUiLanguageCode: appLang);
      if (!mounted) return;
      if (mid != null) {
        try {
          await points.saveLineAnalysisCache(
            mid,
            appLang,
            explanation: result.explanation,
            lineTranslation: result.lineTranslation,
            vocabularyJson: result.vocabulary?.map((v) => v.toJson()).toList(),
          );
        } catch (_) {}
      }
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
      fontSize: 17,
      height: 1.5,
      color: scheme.onSurface,
      fontWeight: FontWeight.w500,
      fontFamily: character.assistantMessagePrefersHangulFont ? 'Pretendard' : null,
    );
    final meaningStyle = TextStyle(
      fontSize: 14,
      height: 1.42,
      color: scheme.onSurfaceVariant,
      fontFamily: _vocabMeaningUsesHangul ? 'Pretendard' : null,
    );
    final sectionLabelStyle = TextStyle(
      fontSize: 13,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: scheme.primary,
      letterSpacing: 0.15,
    );
    final sectionBodyStyle = TextStyle(
      fontSize: 15,
      height: 1.5,
      color: scheme.onSurface,
      fontFamily: character.assistantMessagePrefersHangulFont ? 'Pretendard' : null,
    );
    final vocabWordUsesPretendard = character.koreanNationalPersona ||
        (character.isDirectMessage && dm == DmUtteranceScript.koreanHeavy);
    final wordStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
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

    final bottomPad = MediaQuery.paddingOf(sheetContext).bottom;
    return ListView(
      controller: widget.scrollController,
      physics: _chatExpressionSheetListPhysics(sheetContext),
      padding: EdgeInsets.fromLTRB(AppSpacing.pageH, 4, AppSpacing.pageH, 28 + bottomPad),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadii.cardSmall),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Text(message.content, style: messageStyle),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
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
                      style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
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
                    style: TextStyle(fontSize: 13, height: 1.4, color: scheme.error),
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
                padding: EdgeInsets.only(bottom: i < _effectiveVocabulary!.length - 1 ? 12 : 0),
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
                                      fontWeight: FontWeight.w500,
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
                        width: 44,
                        height: 44,
                        child: _savingIndices.contains(i)
                            ? Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
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
                                  done ? Icons.check_circle_rounded : Icons.add_circle_rounded,
                                  size: 28,
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
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                dm == DmUtteranceScript.koreanHeavy ? tr('expressionMissingVocabularyJa') : tr('expressionMissingVocabulary'),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: scheme.tertiary,
                  fontFamily: dm == DmUtteranceScript.japaneseHeavy ? 'Pretendard' : null,
                ),
              ),
            )
          else if (character.expectsKoreanStudyNotes)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                tr('expressionMissingVocabulary'),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: scheme.tertiary,
                  fontFamily: 'Pretendard',
                ),
              ),
            )
          else if (character.expectsJapaneseStudyNotes)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                tr('expressionMissingVocabularyJa'),
                style: TextStyle(fontSize: 14, height: 1.4, color: scheme.tertiary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
