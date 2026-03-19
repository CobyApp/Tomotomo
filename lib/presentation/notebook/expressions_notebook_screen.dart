import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/saved_expression.dart';
import '../../domain/repositories/saved_expression_repository.dart';
import '../locale/l10n_context.dart';

/// Lists saved expressions from Supabase.
class ExpressionsNotebookScreen extends StatefulWidget {
  const ExpressionsNotebookScreen({super.key});

  @override
  State<ExpressionsNotebookScreen> createState() => _ExpressionsNotebookScreenState();
}

class _ExpressionsNotebookScreenState extends State<ExpressionsNotebookScreen> {
  List<SavedExpression> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<SavedExpressionRepository>();
      final list = await repo.listForCurrentUser();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _confirmDelete(SavedExpression e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('charactersDelete')),
        content: Text(context.tr('notebookDeleteConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('charactersDelete'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<SavedExpressionRepository>().delete(e.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('charactersDeleted'))));
      _load();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('notebookTitle')),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: Text(context.tr('retry'))),
                      ],
                    ),
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.book_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(context.tr('notebookEmpty'), style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('notebookEmptyHint'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final e = _items[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ExpansionTile(
                              title: Text(
                                e.content ?? '—',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                DateFormat.yMMMd(loc).add_jm().format(e.createdAt.toLocal()),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDelete(e),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (e.explanation != null && e.explanation!.isNotEmpty) ...[
                                        Text(e.explanation!, style: const TextStyle(height: 1.5)),
                                        const SizedBox(height: 12),
                                      ],
                                      if (e.translation != null && e.translation!.isNotEmpty)
                                        Text(
                                          e.translation!,
                                          style: TextStyle(
                                            height: 1.5,
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
