import '../../core/supabase/app_supabase.dart';
import '../../domain/entities/saved_expression.dart';
import '../../domain/repositories/saved_expression_repository.dart';

class SavedExpressionRepositoryImpl implements SavedExpressionRepository {
  @override
  Future<List<SavedExpression>> listForCurrentUser({required String notebookLang}) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return [];
    final res = await AppSupabase.client
        .from('saved_expressions')
        .select('*')
        .eq('user_id', user.id)
        .eq('notebook_lang', notebookLang)
        .order('created_at', ascending: false);
    return (res as List<dynamic>)
        .map((e) => SavedExpression.fromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> add(SavedExpressionDraft draft) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }
    // Round-trip so RLS / missing column errors surface to the UI.
    await AppSupabase.client.from('saved_expressions').insert({
      'user_id': user.id,
      'source': draft.source,
      'notebook_lang': draft.notebookLang,
      'content': draft.content,
      if (draft.explanation != null) 'explanation': draft.explanation,
      'translation': draft.translation,
      'room_id': draft.roomId,
    }).select('id').single();
  }

  @override
  Future<void> delete(String id) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }
    // No trailing .select(): DELETE often returns an empty body; relying on
    // row count used to throw false "empty" errors with return=representation + RLS.
    await AppSupabase.client.from('saved_expressions').delete().eq('id', id).eq('user_id', user.id);
  }
}
