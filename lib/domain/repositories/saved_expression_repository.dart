import '../entities/saved_expression.dart';

abstract class SavedExpressionRepository {
  /// [notebookLang] is `ko` or `ja`.
  Future<List<SavedExpression>> listForCurrentUser({required String notebookLang});
  Future<void> add(SavedExpressionDraft draft);
  Future<void> delete(String id);
}
