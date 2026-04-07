import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  Future<void> _confirmDelete(SavedExpression e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.trRead('notebookDeleteTitle')),
        content: Text(ctx.trRead('notebookDeleteConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.trRead('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.trRead('charactersDelete'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final deletedMsg = context.trRead('notebookWordDeleted');
    final deleteFailedPrefix = context.trRead('notebookDeleteFailed');
    try {
      await context.read<SavedExpressionRepository>().delete(e.id);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(deletedMsg)));
      await _load(showSpinner: false);
      _syncHomeWidgetFromServer();
    } catch (err) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('$deleteFailedPrefix\n$err')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Localizations.localeOf(context).toString();
    final scheme = Theme.of(context).colorScheme;

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
                              padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, 8, AppSpacing.pageH, 8),
                              itemCount: _items.length,
                              itemBuilder: (context, i) {
                                final e = _items[i];
                                final dateStr = DateFormat.yMMMd(loc).add_jm().format(e.createdAt.toLocal());
                                final legacyBlock = e.explanation?.trim();
                                final hasLegacy = legacyBlock != null && legacyBlock.isNotEmpty;
                                final gloss = e.translation?.trim();
                                final hasGloss = gloss != null && gloss.isNotEmpty;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: AppSpacing.listGap),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    title: Text(
                                      e.content ?? '—',
                                      style: AppTextStyles.listTitle(context).copyWith(fontSize: 17),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (hasGloss)
                                            Text(
                                              gloss,
                                              style: TextStyle(
                                                height: 1.45,
                                                color: scheme.primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                margin: const EdgeInsets.only(right: 8),
                                                decoration: BoxDecoration(
                                                  color: scheme.primaryContainer.withValues(alpha: 0.6),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  e.notebookLang == 'ja'
                                                      ? context.tr('notebookLangJa')
                                                      : context.tr('notebookLangKo'),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: scheme.onPrimaryContainer,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  dateStr,
                                                  style: AppTextStyles.listSubtitle(context).copyWith(fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (hasLegacy) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              context.tr('notebookLegacyNoteLabel'),
                                              style: AppTextStyles.listSubtitle(context).copyWith(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              legacyBlock,
                                              maxLines: 6,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.listSubtitle(context).copyWith(fontSize: 13),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _confirmDelete(e),
                                    ),
                                    isThreeLine: hasLegacy || hasGloss,
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
