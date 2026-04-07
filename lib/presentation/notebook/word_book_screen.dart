import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/home_widget/notebook_home_widget_sync.dart';
import '../../core/ui/ui.dart';
import '../../core/widgets/on_app_resumed_mixin.dart';
import '../../domain/entities/saved_expression.dart';
import '../../domain/repositories/saved_expression_repository.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import 'word_book_refresh_notifier.dart';

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
    if (_langInitialized) {
      unawaited(_load(showSpinner: false));
    } else {
      unawaited(_bootstrapNotebookTab());
    }
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
    final code = context.read<LocaleNotifier>().languageCode;
    final repo = context.read<SavedExpressionRepository>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        repo.listForCurrentUser(notebookLang: 'ko'),
        repo.listForCurrentUser(notebookLang: 'ja'),
      ]);
      if (!mounted) return;
      final koList = results[0];
      final jaList = results[1];
      final onlyKo = koList.isNotEmpty && jaList.isEmpty;
      final onlyJa = jaList.isNotEmpty && koList.isEmpty;
      final lang = onlyJa
          ? 'ja'
          : onlyKo
              ? 'ko'
              : ((code == 'ja') ? 'ja' : 'ko');
      setState(() {
        _notebookLang = lang;
        _langInitialized = true;
        _items = lang == 'ko' ? koList : jaList;
        _loading = false;
      });
      _syncHomeWidgetFromServer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notebookLang = (code == 'ja') ? 'ja' : 'ko';
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
      _syncHomeWidgetFromServer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onNotebookLangChanged(String lang) {
    if (lang == _notebookLang) return;
    setState(() => _notebookLang = lang);
    unawaited(_load());
  }

  void _syncHomeWidgetFromServer() {
    if (!_langInitialized || !mounted) return;
    final repo = context.read<SavedExpressionRepository>();
    final code = context.read<LocaleNotifier>().languageCode;
    unawaited(syncNotebookToHomeWidget(repo, defaultLangIfUnset: code == 'ja' ? 'ja' : 'ko'));
  }

  /// Same flow as [ChatsTab._confirmDeleteRoom]: dialog only; API runs in [Dismissible.confirmDismiss].
  /// Same shape as [_vocabTranslationLine] in chat: `reading — meaning` when both exist.
  (String? reading, String meaning) _parseNotebookTranslation(String? translation) {
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

  Future<bool?> _confirmDeleteExpression(BuildContext context, SavedExpression e) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('notebookDeleteTitle')),
        content: Text(ctx.tr('notebookDeleteConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.tr('confirm'))),
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

    // Mirrors chat expression sheet: headline word, optional (reading), then gloss line.
    final wordStyle = TextStyle(
      fontSize: 15,
      height: 1.45,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
      fontFamily: usePretendard ? 'Pretendard' : null,
    );
    final readingStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
      fontFamily: usePretendard ? 'Pretendard' : null,
    );
    final meaningStyle = TextStyle(
      fontSize: 13,
      height: 1.4,
      color: scheme.onSurfaceVariant,
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
            messenger.showSnackBar(SnackBar(content: Text(context.trRead('notebookDeleteFailed'))));
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
          _syncHomeWidgetFromServer();
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Icon(Icons.delete_outline_rounded, color: scheme.onErrorContainer, size: 28),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: wordStyle,
                  children: [
                    TextSpan(text: word),
                    if (reading != null && reading.isNotEmpty)
                      TextSpan(text: ' ($reading)', style: readingStyle),
                  ],
                ),
              ),
              if (hasGlossLine) ...[
                const SizedBox(height: 3),
                Text(meaningBody, style: meaningStyle),
              ],
              if (hasLegacy) ...[
                const SizedBox(height: 10),
                Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 8),
                Text(
                  context.tr('notebookLegacyNoteLabel'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: context.tr('notebookTitle'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loading ? null : () => unawaited(_load()),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, 8, AppSpacing.pageH, 8),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment<String>(
                  value: 'ko',
                  label: Text(context.tr('notebookLangKo')),
                  icon: const Icon(Icons.language, size: 18),
                ),
                ButtonSegment<String>(
                  value: 'ja',
                  label: Text(context.tr('notebookLangJa')),
                  icon: const Icon(Icons.translate_rounded, size: 18),
                ),
              ],
              selected: {_notebookLang},
              onSelectionChanged: (s) {
                if (s.isEmpty) return;
                _onNotebookLangChanged(s.first);
              },
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
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.pageH,
                                8,
                                AppSpacing.pageH,
                                AppSpacing.pageBottom,
                              ),
                              itemCount: _items.length + 1,
                              itemBuilder: (context, i) {
                                if (i == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      context.tr('chatsDeleteSwipeHint'),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            height: 1.35,
                                          ),
                                    ),
                                  );
                                }
                                return _dismissibleWordRow(context, _items[i - 1]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
