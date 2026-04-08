import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../../domain/entities/saved_expression.dart';
import '../../domain/repositories/saved_expression_repository.dart';
import '../platform/ios_post_layout_frames.dart';
import '../supabase/app_supabase.dart';

/// iOS: add a Widget Extension in Xcode, enable App Group [kNotebookWidgetAppGroup] on Runner + extension,
/// and use Swift kind `NotebookWidget`. Reference: `ios/NotebookWidgetExtension/NotebookWidget.swift`.
const String kNotebookWidgetAppGroup = 'group.com.dime.tomotomo';

const String _keyLang = 'notebook_widget_lang';
const String _keyPayloadKo = 'notebook_widget_payload_ko';
const String _keyPayloadJa = 'notebook_widget_payload_ja';

const int _maxItems = 8;

/// Ensures App Group is set once on iOS. [syncNotebookToHomeWidget] calls this.
Future<void>? _iosAppGroupOnce;

Future<void> _ensureIosAppGroupReady() async {
  if (!Platform.isIOS) return;
  if (_iosAppGroupOnce != null) return _iosAppGroupOnce!;
  _iosAppGroupOnce = () async {
    try {
      await HomeWidget.setAppGroupId(kNotebookWidgetAppGroup);
      await waitIosPostLayoutFrames(frames: 1);
    } catch (_) {
      _iosAppGroupOnce = null;
    }
  }();
  return _iosAppGroupOnce!;
}

/// Optional explicit init; [syncNotebookToHomeWidget] already calls [_ensureIosAppGroupReady].
Future<void> initNotebookHomeWidget() async {
  await _ensureIosAppGroupReady();
}

/// Push word-book data to the home screen widget. Preserves KO/JA choice unless unset.
Future<void> syncNotebookToHomeWidget(
  SavedExpressionRepository repo, {
  String defaultLangIfUnset = 'ko',
}) async {
  try {
    await _ensureIosAppGroupReady();

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
  // WidgetCenter.reloadTimelines in the first few pumps has been linked to EXC_BAD_ACCESS on device.
  await waitIosPostLayoutFrames(frames: 4);
  try {
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'com.dime.tomotomo.NotebookWidgetProvider',
      iOSName: 'NotebookWidget',
    );
  } catch (_) {}
}
