import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/locale/languages.dart';

import '../../core/home_widget/notebook_home_widget_sync.dart';
import '../locale/friend_language_notifier.dart';
import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/paper_dialog.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_status_views.dart';
import '../../core/ui/paper/paper_theme.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../../core/widgets/on_app_resumed_mixin.dart';
import '../../domain/entities/saved_expression.dart';
import '../../domain/repositories/saved_expression_repository.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import 'word_book_refresh_notifier.dart';
import 'notebook_study_screen.dart';

/// Third tab: vocabulary saved per word via [+] on the chat expression sheet.
class WordBookScreen extends StatefulWidget {
  const WordBookScreen({super.key});

  @override
  WordBookScreenState createState() => WordBookScreenState();
}

class WordBookScreenState extends State<WordBookScreen>
    with WidgetsBindingObserver, OnAppResumedMixin<WordBookScreen> {
  List<SavedExpression> _items = [];
  bool _loading = true;
  String? _error;
  String _notebookLang = 'ko';
  bool _langInitialized = false;
  WordBookRefreshNotifier? _refreshNotifier;

  /// Segments (`ko|ja|en|zh`) that currently have at least one saved word.
  List<String> _availableSegments = const [];

  /// Bottom nav re-selects this tab (IndexedStack does not dispose children).
  void reloadWhenTabSelected() {
    if (!mounted) return;
    final targetLanguage = _targetLanguageCode();
    if (_langInitialized && _notebookLang == targetLanguage) {
      unawaited(_load(showSpinner: false));
    } else {
      unawaited(_bootstrapNotebookTab());
    }
  }

  String _targetLanguageCode() {
    return context.read<FriendLanguageNotifier>().resolve(
      context.read<LocaleNotifier>().languageCode,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshNotifier = context.read<WordBookRefreshNotifier>();
      _refreshNotifier!.addListener(_onWordBookRefreshRequested);
      unawaited(_bootstrapNotebookTab());
    });
  }

  @override
  void dispose() {
    _refreshNotifier?.removeListener(_onWordBookRefreshRequested);
    super.dispose();
  }

  void _onWordBookRefreshRequested() {
    if (!mounted || !_langInitialized) return;
    unawaited(_load(showSpinner: false));
  }

  @override
  void onAppResumed() {
    if (_langInitialized) unawaited(_load(showSpinner: false));
  }

  Future<void> _bootstrapNotebookTab() async {
    if (!mounted) return;
    final targetLanguage = _targetLanguageCode();
    final repo = context.read<SavedExpressionRepository>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await repo.listForCurrentUser(notebookLang: targetLanguage);
      if (!mounted) return;
      setState(() {
        _notebookLang = targetLanguage;
        _langInitialized = true;
        _items = items;
        _loading = false;
      });
      _syncHomeWidgetFromLocalData();
      unawaited(_refreshAvailableSegments());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notebookLang = targetLanguage;
        _langInitialized = true;
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// Refreshes which of the four vocabulary segments have saved words, for
  /// the segment-selector chip row.
  Future<void> _refreshAvailableSegments() async {
    try {
      final repo = context.read<SavedExpressionRepository>();
      final found = <String>[];
      for (final seg in kSupportedLanguageList) {
        final items = await repo.listForCurrentUser(notebookLang: seg);
        if (items.isNotEmpty) found.add(seg);
      }
      if (!mounted) return;
      setState(() => _availableSegments = found);
    } catch (_) {}
  }

  void _selectSegment(String seg) {
    if (seg == _notebookLang) return;
    setState(() => _notebookLang = seg);
    unawaited(_load());
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (!_langInitialized) return;
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }
    try {
      final repo = context.read<SavedExpressionRepository>();
      final list = await repo.listForCurrentUser(notebookLang: _notebookLang);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
      _syncHomeWidgetFromLocalData();
      unawaited(_refreshAvailableSegments());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _syncHomeWidgetFromLocalData() {
    if (!_langInitialized || !mounted) return;
    final repo = context.read<SavedExpressionRepository>();
    unawaited(
      syncNotebookToHomeWidget(repo, defaultLangIfUnset: _notebookLang),
    );
  }

  /// Same flow as [ChatsTab._confirmDeleteRoom]: dialog only; API runs in [Dismissible.confirmDismiss].
  /// Same shape as [_vocabTranslationLine] in chat: `reading — meaning` when both exist.
  (String? reading, String meaning) _parseNotebookTranslation(
    String? translation,
  ) {
    final t = translation?.trim() ?? '';
    if (t.isEmpty) return (null, '');
    const sep = ' — ';
    final i = t.indexOf(sep);
    if (i < 0) return (null, t);
    final r = t.substring(0, i).trim();
    final m = t.substring(i + sep.length).trim();
    if (m.isEmpty) return (null, t);
    return (r.isEmpty ? null : r, m);
  }

  Future<bool> _confirmDeleteExpression(
    BuildContext context,
    SavedExpression e,
  ) {
    return showPaperConfirm(
      context,
      title: context.tr('notebookDeleteTitle'),
      message: context.tr('notebookDeleteConfirm'),
      confirmLabel: context.tr('confirm'),
      destructive: true,
    );
  }

  Widget _dismissibleWordRow(BuildContext context, SavedExpression e) {
    final p = context.paper;
    final legacyBlock = e.explanation?.trim();
    final hasLegacy = legacyBlock != null && legacyBlock.isNotEmpty;
    final (reading, meaningBody) = _parseNotebookTranslation(e.translation);
    final hasGlossLine = meaningBody.isNotEmpty;
    final word = (e.content ?? '').trim().isEmpty ? '—' : e.content!.trim();
    // Same split as the chat expression sheet: cute headword, body-font reading
    // and gloss line.
    final wordStyle = cuteDisplay(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: p.ink,
      language: e.notebookLang,
    );
    final readingStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: p.inkSoft,
    );
    final meaningStyle = TextStyle(
      fontSize: 13,
      height: 1.4,
      color: p.ink,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.listGap),
      child: Dismissible(
        key: ValueKey<String>('notebook_${e.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          final ok = await _confirmDeleteExpression(context, e);
          if (!context.mounted || ok != true) return false;
          final messenger = ScaffoldMessenger.of(context);
          try {
            await context.read<SavedExpressionRepository>().delete(e.id);
            if (!context.mounted) return false;
            return true;
          } catch (_) {
            if (!context.mounted) return false;
            messenger.showSnackBar(
              SnackBar(content: Text(context.trRead('notebookDeleteFailed'))),
            );
            return false;
          }
        },
        onDismissed: (_) {
          if (!mounted) return;
          setState(() {
            _items.removeWhere((x) => x.id == e.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.trRead('notebookWordDeleted'))),
          );
          _syncHomeWidgetFromLocalData();
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(
            color: p.coral.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(PaperRadii.card),
            border: Border.all(color: p.coral.withValues(alpha: 0.3)),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: p.coralDeep,
            size: 28,
          ),
        ),
        child: PaperCard(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(word, style: wordStyle),
                    if (reading != null && reading.isNotEmpty)
                      Text('($reading)', style: readingStyle),
                  ],
                ),
                if (hasGlossLine) ...[
                  const SizedBox(height: 8),
                  Text(meaningBody, style: meaningStyle),
                ],
                if (hasLegacy) ...[
                  const SizedBox(height: 10),
                  Divider(height: 1, color: p.cardEdge),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('notebookLegacyNoteLabel'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: p.inkSoft,
                                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    legacyBlock,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: meaningStyle.copyWith(color: p.inkSoft),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PaperScaffold(
      title: context.tr('notebookTitle'),
      showBackground: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_langInitialized && _availableSegments.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageH,
                8,
                AppSpacing.pageH,
                0,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final seg in _availableSegments)
                    PaperChip(
                      label: languageEndonym(seg),
                      selected: _notebookLang == seg,
                      onTap: () => _selectSegment(seg),
                    ),
                ],
              ),
            ),
          Expanded(
            child: !_langInitialized || _loading
                ? const PaperLoadingBody()
                : _error != null
                ? PaperErrorBody(
                    message: _error!,
                    onRetry: () => unawaited(_load()),
                    retryLabel: context.tr('retry'),
                  )
                : _items.isEmpty
                ? PaperEmptyState(
                    icon: Icons.menu_book_outlined,
                    title: context.tr('notebookEmpty'),
                    subtitle: context.tr(
                      const {
                            'ko': 'notebookEmptyHintKo',
                            'ja': 'notebookEmptyHintJa',
                            'en': 'notebookEmptyHintEn',
                            'zh': 'notebookEmptyHintZh',
                          }[_notebookLang] ??
                          'notebookEmptyHintKo',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageH,
                      8,
                      AppSpacing.pageH,
                      AppSpacing.pageBottom,
                    ),
                    itemCount: _items.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return _StudyLauncherCard(
                          count: _items.length,
                          onTap: () {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NotebookStudyScreen(
                                  items: List<SavedExpression>.of(_items),
                                  notebookLanguage: _notebookLang,
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return _dismissibleWordRow(context, _items[i - 1]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StudyLauncherCard extends StatelessWidget {
  const _StudyLauncherCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final radius = BorderRadius.circular(PaperRadii.card);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          foregroundDecoration: stickerGloss(borderRadius: radius),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [p.coral, p.coralDeep],
            ),
            borderRadius: radius,
            border: Border.all(color: p.ink, width: 2.5),
            boxShadow: [
              BoxShadow(color: p.hardShadow, offset: const Offset(4, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: p.ink, width: 2),
                ),
                child: Icon(Icons.style_rounded, color: p.coral, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('notebookStudyStart'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.tr(
                        'notebookStudyStartSubtitle',
                        params: {'count': '$count'},
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
