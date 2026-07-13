import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:aichat/data/repositories/saved_expression_repository_impl.dart';
import 'package:aichat/domain/entities/saved_expression.dart';

void main() {
  late Box box;
  late SavedExpressionRepositoryImpl repo;

  setUp(() async {
    Hive.init('./.dart_tool/hive_test_wordbook');
    box = await Hive.openBox('wordbook');
    repo = SavedExpressionRepositoryImpl(box);
  });
  tearDown(() async => Hive.deleteFromDisk());

  test('add stores entries; list filters by notebookLang', () async {
    await repo.add(const SavedExpressionDraft(
      notebookLang: 'ja',
      content: '勉強',
      translation: 'べんきょう · 공부',
    ));
    await repo.add(const SavedExpressionDraft(
      notebookLang: 'ko',
      content: '공부',
      translation: '勉強',
    ));

    final ja = await repo.listForCurrentUser(notebookLang: 'ja');
    expect(ja.length, 1);
    expect(ja.first.content, '勉強');

    final ko = await repo.listForCurrentUser(notebookLang: 'ko');
    expect(ko.length, 1);
    expect(ko.first.content, '공부');
  });

  test('delete removes by id', () async {
    await repo.add(const SavedExpressionDraft(notebookLang: 'ja', content: 'x'));
    final list = await repo.listForCurrentUser(notebookLang: 'ja');
    expect(list.length, 1);
    await repo.delete(list.first.id);
    expect((await repo.listForCurrentUser(notebookLang: 'ja')).isEmpty, isTrue);
  });
}
