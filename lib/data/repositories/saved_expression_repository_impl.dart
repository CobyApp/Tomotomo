import '../../core/supabase/app_supabase.dart';
import '../../domain/entities/saved_expression.dart';
import '../../domain/repositories/saved_expression_repository.dart';

class SavedExpressionRepositoryImpl implements SavedExpressionRepository {
  @override
  Future<List<SavedExpression>> listForCurrentUser() async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return [];
    final res = await AppSupabase.client
        .from('saved_expressions')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return (res as List<dynamic>)
        .map((e) => SavedExpression.fromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> add(SavedExpressionDraft draft) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return;
    await AppSupabase.client.from('saved_expressions').insert({
      'user_id': user.id,
      'source': draft.source,
      'content': draft.content,
      'explanation': draft.explanation,
      'translation': draft.translation,
      'room_id': draft.roomId,
    });
  }

  @override
  Future<void> delete(String id) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return;
    await AppSupabase.client.from('saved_expressions').delete().eq('id', id).eq('user_id', user.id);
  }
}
