import 'package:flutter/material.dart';
import '../../core/ui/paper/paper_loading.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/paper_theme.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/saved_expression.dart';
import '../../domain/repositories/saved_expression_repository.dart';
import '../locale/l10n_context.dart';
import '../notebook/word_book_refresh_notifier.dart';

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
    // Keeps the sheet below the status bar / notch from the ROOT view's safe
    // area. (Manually reading MediaQuery here doesn't work: inside a Scaffold
    // body with an AppBar, removePadding has already zeroed viewPadding.top,
    // which once put this sheet behind the notch with an unreachable X.)
    useSafeArea: true,
    // Drag-to-dismiss from the header. The body is a ListView, so a drag that
    // starts there scrolls the content and only the header (and other
    // non-scrolling chrome) pulls the sheet — no resizing/snapping, which is
    // what made the old draggable sheet feel unstable.
    enableDrag: true,
    isDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (sheetContext) {
      final p = sheetContext.paper;

      // Fill the full height allowed by useSafeArea (screen minus notch).
      return FractionallySizedBox(
        heightFactor: 1,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            border: Border.all(color: p.cardEdge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: title on the left, a prominent on-brand sticker close
              // (X) on the right, over a hairline divider that matches the tone.
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: p.cardEdge),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        sheetContext.tr('expressionSheetTitle'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: cuteDisplay(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: p.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    PaperRoundButton(
                      icon: Icons.close_rounded,
                      size: 40,
                      tooltip: sheetContext.tr('close'),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _ExpressionSheetBody(
                  message: message,
                  character: character,
                  chatRoomId: chatRoomId,
                  messenger: messenger,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}



class _ExpressionSheetBody extends StatefulWidget {
  final ChatMessage message;
  final Character character;
  final String? chatRoomId;
  final ScaffoldMessengerState messenger;

  const _ExpressionSheetBody({
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

  // The study sheet (translation + vocabulary) is produced in the SAME
  // generation as the reply and stored on the message — so we just read it
  // here. No on-demand fetch, no loading spinner.
  List<Vocabulary>? get _effectiveVocabulary => widget.message.vocabulary;

  String? get _effectiveLineTranslation => widget.message.lineTranslation;

  Future<void> _saveWordToNotebook(int index, Vocabulary v) async {
    if (_savedWordIndices.contains(index) || _savingIndices.contains(index)) {
      return;
    }
    final sheetContext = context;
    final repo = sheetContext.read<SavedExpressionRepository>();
    final lang = widget.character.defaultNotebookLangForVocabSave;
    final saveFailedPrefix = sheetContext.trRead('wordSaveNotebookFailed');
    setState(() => _savingIndices.add(index));
    try {
      await repo.add(
        SavedExpressionDraft(
          source: 'chat',
          notebookLang: lang,
          content: v.word,
          reading: v.reading?.trim(),
          translation: v.meaning,
          roomId: widget.chatRoomId,
        ),
      );
      if (!mounted) return;
      await HapticFeedback.mediumImpact();
      setState(() {
        _savedWordIndices.add(index);
        _savingIndices.remove(index);
      });
      // No snackbar on success: it would render behind this full-height sheet
      // and pop up stale after closing. The ✓ icon + haptic is the feedback.
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
    final tr = sheetContext.tr;
    final p = context.paper;

    final messageStyle = TextStyle(
      fontSize: 17,
      height: 1.5,
      color: p.ink,
      fontWeight: FontWeight.w500,
    );
    final meaningStyle = TextStyle(
      fontSize: 14,
      height: 1.42,
      color: p.ink,
    );
    final sectionLabelStyle = TextStyle(
      fontSize: 13,
      height: 1.2,
      fontWeight: FontWeight.w800,
      color: p.coral,
      letterSpacing: 0.4,
    );
    final sectionBodyStyle = TextStyle(
      fontSize: 15,
      height: 1.5,
      color: p.ink,
    );
    // Body text: the theme already supplies Pretendard, so these styles used to
    // carry `isKorean ? 'Pretendard' : null` branches where BOTH arms resolved
    // to Pretendard — a null family in a fresh TextStyle loses to the inherited
    // DefaultTextStyle. Verified by resolving the rendered style.
    // Cute headword, body-font reading and gloss — the same split the word book
    // uses, so a word keeps its look after being saved. The book's comment
    // already claimed it mirrored this sheet; the sheet was the one out of step.
    final wordStyle = cuteDisplay(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: p.ink,
      language: widget.character.friendLanguage,
    );

    final translation = _effectiveLineTranslation?.trim();
    final showTranslation = translation != null && translation.isNotEmpty;

    Widget sectionBlock(String label, String body) {
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: sectionLabelStyle),
            const SizedBox(height: 6),
            _DashedRule(color: p.cardEdge),
            const SizedBox(height: 8),
            Text(body, style: sectionBodyStyle),
          ],
        ),
      );
    }

    final bottomPad = MediaQuery.paddingOf(sheetContext).bottom;
    // Fixed-height sheet: scroll only when the content overflows (no bounce
    // when it fits), so a short sheet stays perfectly still.
    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        4,
        AppSpacing.pageH,
        28 + bottomPad,
      ),
      children: [
        PaperCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Text(message.content, style: messageStyle),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (showTranslation)
              sectionBlock(
                tr('expressionFullTranslationLabel'),
                translation,
              ),
            if (_effectiveVocabulary != null &&
                _effectiveVocabulary!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(tr('expressionVocabularyLabel'), style: sectionLabelStyle),
              const SizedBox(height: 6),
              _DashedRule(color: p.cardEdge),
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
                            StampTicket(
                              child: Text.rich(
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
                                          color: p.inkSoft,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
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
                                  child: PaperLoading(size: 9),
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
                                    color: done ? p.stampBlue : p.coral,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else
              // One key: tr() already resolves to the UI language, so the old
              // ko/ja split just meant a Japanese string could reach other
              // locales. Only the font still depends on the script.
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  tr('expressionMissingVocabulary'),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: p.inkSoft,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Thin dashed rule under a section label — matches [JournalNote]'s divider
/// styling without depending on its private painter.
class _DashedRule extends StatelessWidget {
  const _DashedRule({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedRulePainter(color: color),
    );
  }
}

class _DashedRulePainter extends CustomPainter {
  const _DashedRulePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashGap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRulePainter oldDelegate) =>
      oldDelegate.color != color;
}
