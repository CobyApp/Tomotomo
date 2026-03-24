import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../../domain/entities/saved_expression.dart';
import '../../domain/repositories/saved_expression_repository.dart';
import '../supabase/app_supabase.dart';

/// iOS: add a Widget Extension in Xcode, enable App Group [kNotebookWidgetAppGroup] on Runner + extension,
/// and use Swift kind `NotebookWidget`. Reference: `ios/NotebookWidgetExtension/NotebookWidget.swift`.
const String kNotebookWidgetAppGroup = 'group.com.dime.tomotomo';

const String _keyLang = 'notebook_widget_lang';
const String _keyPayloadKo = 'notebook_widget_payload_ko';
const String _keyPayloadJa = 'notebook_widget_payload_ja';

const int _maxItems = 8;

/// Call once at startup (before [syncNotebookToHomeWidget]) on iOS.
Future<void> initNotebookHomeWidget() async {
  if (!Platform.isIOS) return;
  try {
    await HomeWidget.setAppGroupId(kNotebookWidgetAppGroup);
  } catch (_) {}
}

/// Push word-book data to the home screen widget. Preserves KO/JA choice unless unset.
Future<void> syncNotebookToHomeWidget(
  SavedExpressionRepository repo, {
  String defaultLangIfUnset = 'ko',
}) async {
  try {
    final user = AppSupabase.auth.currentUser;
    if (user == null) {
      await HomeWidget.saveWidgetData<String>(_keyPayloadKo, null);
      await HomeWidget.saveWidgetData<String>(_keyPayloadJa, null);
      await HomeWidget.saveWidgetData<String>(_keyLang, null);
      await _reloadWidget();
      return;
    }

    final ko = await repo.listForCurrentUser(notebookLang: 'ko');
    final ja = await repo.listForCurrentUser(notebookLang: 'ja');

    String encodePayload(List<SavedExpression> list) {
      final slice = list.take(_maxItems).map((e) {
        return <String, String>{
          'c': e.content?.trim() ?? '',
          't': e.translation?.trim() ?? '',
        };
      }).toList();
      return jsonEncode(slice);
    }

    await HomeWidget.saveWidgetData<String>(_keyPayloadKo, encodePayload(ko));
    await HomeWidget.saveWidgetData<String>(_keyPayloadJa, encodePayload(ja));

    var lang = await HomeWidget.getWidgetData<String>(_keyLang);
    if (lang != 'ko' && lang != 'ja') {
      lang = defaultLangIfUnset;
      if (lang != 'ko' && lang != 'ja') lang = 'ko';
      if (ja.isNotEmpty && ko.isEmpty) lang = 'ja';
      if (ko.isNotEmpty && ja.isEmpty) lang = 'ko';
      await HomeWidget.saveWidgetData<String>(_keyLang, lang);
    }

    await _reloadWidget();
  } catch (_) {
    // e.g. iOS without App Group / widget target
  }
}

Future<void> _reloadWidget() async {
  await HomeWidget.updateWidget(
    qualifiedAndroidName: 'com.dime.tomotomo.NotebookWidgetProvider',
    iOSName: 'NotebookWidget',
  );
}
