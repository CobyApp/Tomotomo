import '../entities/saved_expression.dart';

abstract class SavedExpressionRepository {
  Future<List<SavedExpression>> listForCurrentUser();
  Future<void> add(SavedExpressionDraft draft);
  Future<void> delete(String id);
}
