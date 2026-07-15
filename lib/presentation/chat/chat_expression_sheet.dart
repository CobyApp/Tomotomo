import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_tokens.dart';
import '../../core/ui/holo/holo_tokens.dart';
import '../../core/ui/holo/holo_widgets.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/saved_expression.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../../domain/repositories/points_repository.dart';
import '../../domain/repositories/saved_expression_repository.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import '../notebook/word_book_refresh_notifier.dart';

/// List physics: iOS/macOS bounce + overscroll hands off to [DraggableScrollableSheet]; Android clamps.
ScrollPhysics _chatExpressionSheetListPhysics(BuildContext context) {
  final p = Theme.of(context).platform;
  final iosLike = p == TargetPlatform.iOS || p == TargetPlatform.macOS;
  return AlwaysScrollableScrollPhysics(
    parent: iosLike
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics(),
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

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: false,
    enableDrag: false,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (sheetContext) {
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
                color: Holo.surfaceCard,
                elevation: 10,
                shadowColor: Holo.pink.withValues(alpha: 0.28),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  side: BorderSide(color: Holo.pink, width: 1.5),
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
                            color: Holo.cyan.withValues(alpha: 0.7),
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

  const _ExpressionSheetBody({
    required this.scrollController,
    required this.message,
    required this.character,
    required this.chatRoomId,
    required this.messenger,
  });

  @override
  State<_ExpressionSheetBody> createState() => _ExpressionSheetBodyState();
}

class _ExpressionSheetBodyState extends State<_ExpressionSheetBody> {
  final Set<int> _savedWordIndices = {};
  final Set<int> _savingIndices = {};
  ChatMessage? _fetchedAnalysis;
  bool _analysisLoading = false;
  String? _analysisError;

  bool get _hasBundledAnalysis {
    final message = widget.message;
    final translation = message.lineTranslation?.trim() ?? '';
    final explanation = message.explanation?.trim() ?? '';
    final vocabulary = message.vocabulary;
    return translation.isNotEmpty &&
        (explanation.isNotEmpty ||
            (vocabulary != null && vocabulary.isNotEmpty));
  }

  @override
  void initState() {
    super.initState();
    if (!_hasBundledAnalysis && widget.message.content.trim().isNotEmpty) {
      _analysisLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAnalysis());
    }
  }

  List<Vocabulary>? _vocabularyFromCache(
    List<Map<String, dynamic>> values,
  ) {
    final vocabulary = <Vocabulary>[];
    for (final value in values) {
      final parsed = Vocabulary.tryParseLoose(
        value,
        meaningMode: widget.character.vocabularyMeaningPickMode,
      );
      if (parsed != null) vocabulary.add(parsed);
    }
    return vocabulary.isEmpty ? null : vocabulary;
  }

  Future<void> _loadAnalysis() async {
    if (!mounted || _hasBundledAnalysis) return;
    setState(() {
      _analysisLoading = true;
      _analysisError = null;
    });

    final appLanguage = context.read<LocaleNotifier>().languageCode;
    final points = context.read<PointsRepository>();
    final messageId = widget.message.serverId;
    try {
      if (messageId != null) {
        final cached = await points.getLineAnalysisCache(
          messageId,
          appLanguage,
        );
        if (!mounted) return;
        if (cached != null) {
          final vocabulary = _vocabularyFromCache(cached.vocabularyJson);
          if ((cached.lineTranslation?.trim().isNotEmpty ?? false) ||
              (cached.explanation?.trim().isNotEmpty ?? false) ||
              (vocabulary?.isNotEmpty ?? false)) {
            setState(() {
              _fetchedAnalysis = ChatMessage(
                serverId: widget.message.serverId,
                content: widget.message.content,
                role: widget.message.role,
                timestamp: widget.message.timestamp,
                explanation: cached.explanation,
                lineTranslation: cached.lineTranslation,
                vocabulary: vocabulary,
              );
              _analysisLoading = false;
            });
            return;
          }
        }
      }

      final analysis = await context
          .read<AiChatRepository>()
          .generateExpressionAnalysis(
            widget.message.content,
            widget.character,
            appUiLanguageCode: appLanguage,
          );
      if (messageId != null) {
        await points.saveLineAnalysisCache(
          messageId,
          appLanguage,
          explanation: analysis.explanation,
          lineTranslation: analysis.lineTranslation,
          vocabularyJson: analysis.vocabulary
              ?.map((value) => value.toJson())
              .toList(),
        );
      }
      if (!mounted) return;
      setState(() {
        _fetchedAnalysis = analysis;
        _analysisLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _analysisLoading = false;
        _analysisError = error.toString();
      });
    }
  }

  List<Vocabulary>? get _effectiveVocabulary =>
      _fetchedAnalysis?.vocabulary ?? widget.message.vocabulary;

  String? get _effectiveLineTranslation =>
      _fetchedAnalysis?.lineTranslation ?? widget.message.lineTranslation;

  String? get _effectiveExplanation =>
      _fetchedAnalysis?.explanation ?? widget.message.explanation;

  bool get _vocabMeaningUsesHangul => widget.character.expectsKoreanStudyNotes;

  Future<void> _saveWordToNotebook(int index, Vocabulary v) async {
    if (_savedWordIndices.contains(index) || _savingIndices.contains(index)) {
      return;
    }
    final sheetContext = context;
    final repo = sheetContext.read<SavedExpressionRepository>();
    final lang = widget.character.defaultNotebookLangForVocabSave;
    final snackText = lang == 'ko'
        ? sheetContext.trRead('wordAddedToNotebookKo')
        : sheetContext.trRead('wordAddedToNotebookJa');
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
      widget.messenger.showSnackBar(
        SnackBar(content: Text('$saveFailedPrefix\n$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetContext = context;
    final message = widget.message;
    final character = widget.character;
    final tr = sheetContext.tr;
    final scheme = Theme.of(sheetContext).colorScheme;

    final messageStyle = TextStyle(
      fontSize: 17,
      height: 1.5,
      color: Holo.inkPlum,
      fontWeight: FontWeight.w500,
      fontFamily: character.assistantMessagePrefersHangulFont
          ? 'Pretendard'
          : null,
    );
    final meaningStyle = TextStyle(
      fontSize: 14,
      height: 1.42,
      color: Holo.inkPlumSoft,
      fontFamily: _vocabMeaningUsesHangul ? 'Pretendard' : null,
    );
    final sectionLabelStyle = const TextStyle(
      fontSize: 13,
      height: 1.2,
      fontWeight: FontWeight.w900,
      color: Holo.pink,
      letterSpacing: 0.15,
    );
    final sectionBodyStyle = TextStyle(
      fontSize: 15,
      height: 1.5,
      color: Holo.inkPlum,
      fontFamily: character.assistantMessagePrefersHangulFont
          ? 'Pretendard'
          : null,
    );
    final vocabWordUsesPretendard = character.koreanNationalPersona;
    final wordStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Holo.inkPlum,
      fontFamily: vocabWordUsesPretendard ? 'Pretendard' : null,
    );

    final translation = _effectiveLineTranslation?.trim();
    final note = _effectiveExplanation?.trim();
    final showTranslation = translation != null && translation.isNotEmpty;
    final showNote = note != null && note.isNotEmpty;

    final translationUsesHangul = character.expectsKoreanStudyNotes;

    Widget sectionBlock(
      String label,
      String body, {
      bool useHangulBody = false,
    }) {
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
                fontFamily: useHangulBody
                    ? 'Pretendard'
                    : sectionBodyStyle.fontFamily,
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
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        4,
        AppSpacing.pageH,
        28 + bottomPad,
      ),
      children: [
        HoloCard(
          dashed: true,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Text(message.content, style: messageStyle),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (_analysisLoading)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Holo.pink,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      tr('expressionAnalysisLoading'),
                      style: const TextStyle(color: Holo.inkPlumSoft),
                    ),
                  ],
                ),
              ),
            if (_analysisError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('expressionAnalysisFailed'),
                      style: TextStyle(color: scheme.error),
                    ),
                    const SizedBox(height: 8),
                    HoloButton(
                      label: tr('retry'),
                      icon: Icons.refresh_rounded,
                      onPressed: _loadAnalysis,
                    ),
                  ],
                ),
              ),
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
                useHangulBody:
                    context.read<LocaleNotifier>().languageCode == 'ko',
              ),
            if (_effectiveVocabulary != null &&
                _effectiveVocabulary!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Divider(height: 1, color: Holo.pink.withValues(alpha: 0.2)),
              const SizedBox(height: 10),
              ..._effectiveVocabulary!.asMap().entries.map((e) {
                final i = e.key;
                final vocab = e.value;
                final done = _savedWordIndices.contains(i);
                final hasReading =
                    vocab.reading != null && vocab.reading!.trim().isNotEmpty;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: i < _effectiveVocabulary!.length - 1 ? 12 : 0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HoloChip(
                              filled: false,
                              child: Text.rich(
                                TextSpan(
                                  style: wordStyle,
                                  children: [
                                    TextSpan(text: vocab.word),
                                    if (hasReading)
                                      TextSpan(
                                        text: ' (${vocab.reading})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          color: Holo.inkPlumSoft,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
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
                              ? const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Holo.pink,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  onPressed: done
                                      ? null
                                      : () => _saveWordToNotebook(i, vocab),
                                  icon: Icon(
                                    done
                                        ? Icons.check_circle_rounded
                                        : Icons.add_circle_rounded,
                                    size: 28,
                                    color: done ? Holo.cyan : Holo.pink,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else if (_analysisLoading || _analysisError != null)
              const SizedBox.shrink()
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
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: scheme.tertiary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
