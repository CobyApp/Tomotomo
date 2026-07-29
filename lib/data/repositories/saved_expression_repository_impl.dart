import 'package:hive_ce/hive.dart';

import '../../domain/entities/saved_expression.dart';
import '../../domain/repositories/saved_expression_repository.dart';
import '../local/local_json_store.dart';

/// Local word-book persistence in the `wordbook` box. One map per saved
/// expression, keyed by a generated id. Single local user (no auth).
class SavedExpressionRepositoryImpl implements SavedExpressionRepository {
  SavedExpressionRepositoryImpl(Box box) : _store = LocalJsonStore(box);
  final LocalJsonStore _store;

  /// The single local user id; there are no accounts in the offline app.
  static const _localUserId = 'local';

  @override
  Future<List<SavedExpression>> listForCurrentUser({required String notebookLang}) async {
    final rows = _store
        .listItems()
        .where((m) => (m['notebook_lang'] as String?) == notebookLang)
        .map(SavedExpression.fromRow)
        .toList();
    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rows;
  }

  @override
  Future<void> add(SavedExpressionDraft draft) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await _store.putItem(id, {
      'id': id,
      'user_id': _localUserId,
      'source': draft.source,
      'notebook_lang': draft.notebookLang,
      'content': draft.content,
      'explanation': draft.explanation,
      'reading': draft.reading,
      'translation': draft.translation,
      'room_id': draft.roomId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> delete(String id) async {
    await _store.deleteItem(id);
  }
}
