import 'dart:convert';

import 'package:aichat/core/di/injection.dart';
import 'package:aichat/core/home_widget/notebook_home_widget_sync.dart';
import 'package:aichat/core/locale/languages.dart';
import 'package:aichat/domain/entities/saved_expression.dart';
import 'package:aichat/domain/repositories/saved_expression_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns one word for [_wordsFor] languages and nothing for the rest.
class _FakeRepo implements SavedExpressionRepository {
  _FakeRepo(this._wordsFor);
  final Set<String> _wordsFor;
  final List<String> askedFor = [];

  @override
  Future<List<SavedExpression>> listForCurrentUser({
    String? notebookLang,
  }) async {
    final lang = notebookLang ?? '<null>';
    askedFor.add(lang);
    if (!_wordsFor.contains(lang)) return const [];
    return [
      SavedExpression(
        id: 'id-$lang',
        userId: 'local',
        source: 'chat',
        notebookLang: lang,
        content: 'word-$lang',
        translation: 'meaning-$lang',
        createdAt: DateTime(2026, 1, 1),
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('not needed: ${invocation.memberName}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('home_widget');
  late Map<String, Object?> saved;

  setUp(() {
    saved = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'saveWidgetData':
              final args = call.arguments as Map;
              saved[args['id'] as String] = args['data'];
              return true;
            case 'getWidgetData':
              return saved[(call.arguments as Map)['id'] as String];
            default:
              return true;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    appLanguageCode = 'ko';
  });

  test('every supported language gets its own payload', () async {
    final repo = _FakeRepo({'en'});
    await syncNotebookToHomeWidget(repo);

    expect(repo.askedFor.toSet(), kSupportedLanguages);
    for (final lang in kSupportedLanguages) {
      expect(
        saved['notebook_widget_payload_$lang'],
        isNotNull,
        reason: 'a $lang learner\'s words never reached the widget',
      );
    }
    // The English words are the ones actually carried, not dropped.
    expect(
      saved['notebook_widget_payload_en'],
      contains('word-en'),
      reason: 'only ko/ja used to be fetched at all',
    );
  });

  test('keeps the historical ko/ja key names', () async {
    await syncNotebookToHomeWidget(_FakeRepo({'ko'}));
    expect(saved.keys, containsAll(<String>{
      'notebook_widget_payload_ko',
      'notebook_widget_payload_ja',
    }));
  });

  test('shows the only language that has words', () async {
    // Default says ko, but every saved word is Chinese — an empty widget is
    // worse than a language the user did not ask for.
    await syncNotebookToHomeWidget(_FakeRepo({'zh'}), defaultLangIfUnset: 'ko');
    expect(saved['notebook_widget_lang'], 'zh');
    expect(saved['notebook_widget_labels'], '中文');
  });

  test('respects a language the user already chose', () async {
    saved['notebook_widget_lang'] = 'ja';
    await syncNotebookToHomeWidget(_FakeRepo({'zh'}));
    expect(saved['notebook_widget_lang'], 'ja');
    // The shown language is in the cycle even with no words of its own, and the
    // labels line up with it index for index.
    expect(saved['notebook_widget_langs'], 'ja,zh');
    expect(saved['notebook_widget_labels'], '日本語,中文');
  });

  test('widget chrome follows the app UI language, not a hardcoded one', () async {
    appLanguageCode = 'en';
    await syncNotebookToHomeWidget(_FakeRepo({'ja'}));
    expect(saved['notebook_widget_title'], 'Vocabulary');
    expect(saved['notebook_widget_empty'], 'No saved words');

    appLanguageCode = 'ko';
    await syncNotebookToHomeWidget(_FakeRepo({'ja'}));
    expect(saved['notebook_widget_title'], '단어장');
  });

  test('payload carries word and meaning', () async {
    await syncNotebookToHomeWidget(_FakeRepo({'ko'}));
    final decoded =
        jsonDecode(saved['notebook_widget_payload_ko'] as String) as List;
    expect(decoded.single, {'c': 'word-ko', 't': 'meaning-ko'});
  });

  test('the shown language stays reachable when its own words are gone', () async {
    // On 'ja', every Japanese word deleted, words exist only in Korean. Listing
    // just the languages WITH words left a one-entry cycle: the chip hid itself
    // and the widget was stuck showing an empty Japanese list for good.
    saved['notebook_widget_lang'] = 'ja';
    await syncNotebookToHomeWidget(_FakeRepo({'ko'}));

    final cycle = (saved['notebook_widget_langs'] as String).split(',');
    expect(cycle, containsAll(<String>['ja', 'ko']));
    expect(cycle.length, greaterThan(1), reason: 'a hidden chip strands the widget');
    expect(saved['notebook_widget_lang'], 'ja', reason: 'the choice is not overridden');
  });

  test('labels always pair up with the cycle, one for one', () async {
    for (final withWords in [<String>{}, {'ko'}, {'ko', 'zh'}, {'ko', 'ja', 'en', 'zh'}]) {
      saved.clear();
      await syncNotebookToHomeWidget(_FakeRepo(withWords));
      final langs = (saved['notebook_widget_langs'] as String).split(',');
      final labels = (saved['notebook_widget_labels'] as String).split(',');
      expect(labels.length, langs.length, reason: 'mismatched for $withWords');
      expect(langs, isNot(contains('')), reason: 'empty entry for $withWords');
    }
  });
}
