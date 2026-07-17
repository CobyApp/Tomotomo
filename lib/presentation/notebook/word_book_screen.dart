import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/home_widget/notebook_home_widget_sync.dart';
import '../../core/locale/study_language.dart';
import '../../core/ui/ui.dart';
import '../../core/ui/holo/holo_tokens.dart';
import '../../core/ui/holo/holo_widgets.dart';
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
    return studyLanguageForApp(context.read<LocaleNotifier>().languageCode);
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

  Future<bool?> _confirmDeleteExpression(
    BuildContext context,
    SavedExpression e,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('notebookDeleteTitle')),
        content: Text(ctx.tr('notebookDeleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('confirm')),
          ),
        ],
      ),
    );
  }

  Widget _dismissibleWordRow(BuildContext context, SavedExpression e) {
    final scheme = Theme.of(context).colorScheme;
    final legacyBlock = e.explanation?.trim();
    final hasLegacy = legacyBlock != null && legacyBlock.isNotEmpty;
    final (reading, meaningBody) = _parseNotebookTranslation(e.translation);
    final hasGlossLine = meaningBody.isNotEmpty;
    final word = (e.content ?? '').trim().isEmpty ? '—' : e.content!.trim();
    final usePretendard = e.notebookLang == 'ko';

    // Mirrors chat expression sheet: headline word chip, optional reading chip, then gloss line.
    final chipTextStyle = TextStyle(
      fontFamily: usePretendard ? 'Pretendard' : null,
    );
    final meaningStyle = TextStyle(
      fontSize: 13,
      height: 1.4,
      color: Holo.inkPlumSoft,
      fontFamily: usePretendard ? 'Pretendard' : null,
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
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: scheme.onErrorContainer,
            size: 28,
          ),
        ),
        child: HoloCard(
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
                    HoloChip(child: Text(word, style: chipTextStyle)),
                    if (reading != null && reading.isNotEmpty)
                      HoloChip(
                        filled: false,
                        child: Text(reading, style: chipTextStyle),
                      ),
                  ],
                ),
                if (hasGlossLine) ...[
                  const SizedBox(height: 8),
                  Text(meaningBody, style: meaningStyle),
                ],
                if (hasLegacy) ...[
                  const SizedBox(height: 10),
                  Divider(height: 1, color: Holo.pink.withValues(alpha: 0.2)),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('notebookLegacyNoteLabel'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Holo.inkPlumSoft,
                      fontFamily: usePretendard ? 'Pretendard' : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    legacyBlock,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: meaningStyle,
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
    return AppPageScaffold(
      title: context.tr('notebookTitle'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageH,
              8,
              AppSpacing.pageH,
              4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('notebookSubtitle'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: !_langInitialized || _loading
                ? const AppLoadingBody()
                : _error != null
                ? AppErrorBody(
                    message: _error!,
                    onRetry: () => unawaited(_load()),
                    retryLabel: context.tr('retry'),
                  )
                : _items.isEmpty
                ? AppEmptyState(
                    icon: Icons.menu_book_outlined,
                    title: context.tr('notebookEmpty'),
                    subtitle: _notebookLang == 'ko'
                        ? context.tr('notebookEmptyHintKo')
                        : context.tr('notebookEmptyHintJa'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageH,
                      8,
                      AppSpacing.pageH,
                      AppSpacing.pageBottom,
                    ),
                    itemCount: _items.length + 2,
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
                      if (i == 1) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            context.tr('chatsDeleteSwipeHint'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                          ),
                        );
                      }
                      return _dismissibleWordRow(context, _items[i - 2]);
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Holo.pink.withValues(alpha: 0.92),
                  Holo.lilac.withValues(alpha: 0.92),
                  Holo.cyan.withValues(alpha: 0.88),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
              boxShadow: Holo.floatingShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.36),
                    ),
                  ),
                  child: const Icon(
                    Icons.style_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('notebookStudyStart'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
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
                          color: Colors.white.withValues(alpha: 0.88),
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
      ),
    );
  }
}
