import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../../domain/entities/saved_expression.dart';
import '../../domain/repositories/saved_expression_repository.dart';
import '../di/injection.dart';
import '../l10n/app_strings.dart';
import '../locale/languages.dart';
import '../platform/ios_post_layout_frames.dart';

/// iOS: add a Widget Extension in Xcode, enable App Group [kNotebookWidgetAppGroup] on Runner + extension,
/// and use Swift kind `NotebookWidget`. Reference: `ios/NotebookWidgetExtension/NotebookWidget.swift`.
const String kNotebookWidgetAppGroup = 'group.com.dime.tomotomo';

const String _keyLang = 'notebook_widget_lang';

/// One payload per supported language. `ko` / `ja` keep the historical key
/// names, so an already-installed widget keeps reading the same slots.
String _payloadKey(String lang) => 'notebook_widget_payload_$lang';

/// Chrome text pushed from Dart: the widget extension can't reach [AppStrings],
/// so it used to be hardcoded Japanese for every user.
const String _keyTitle = 'notebook_widget_title';
const String _keyEmpty = 'notebook_widget_empty';
const String _keyLangLabel = 'notebook_widget_lang_label';

/// Name + blurb shown in the OS widget gallery. Localizing these natively would
/// mean adding a strings catalog to the extension target; reading them from the
/// App Group keeps it in one place with the rest of the widget's text.
const String _keyGalleryDesc = 'notebook_widget_gallery_desc';

/// Languages the widget's language chip can cycle through, in order, as CSV —
/// the ones that actually have saved words. Pushed from here so the native side
/// never has to know the language list or hardcode a ko/ja pair.
const String _keyLangs = 'notebook_widget_langs';

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

/// Push word-book data to the home screen widget. Preserves the shown language
/// unless it is unset or no longer supported.
Future<void> syncNotebookToHomeWidget(
  SavedExpressionRepository repo, {
  String defaultLangIfUnset = 'ko',
}) async {
  try {
    await _ensureIosAppGroupReady();

    // Every supported language, not just ko/ja: an English or Chinese learner's
    // saved words never reached the widget at all.
    final lists = <String, List<SavedExpression>>{};
    for (final lang in kSupportedLanguages) {
      lists[lang] = await repo.listForCurrentUser(notebookLang: lang);
    }

    String encodePayload(List<SavedExpression> list) {
      final slice = list.take(_maxItems).map((e) {
        return <String, String>{
          'c': e.content?.trim() ?? '',
          't': e.translation?.trim() ?? '',
        };
      }).toList();
      return jsonEncode(slice);
    }

    for (final entry in lists.entries) {
      await HomeWidget.saveWidgetData<String>(
        _payloadKey(entry.key),
        encodePayload(entry.value),
      );
    }

    final withWords = kSupportedLanguages
        .where((l) => lists[l]!.isNotEmpty)
        .toList();

    var lang = await HomeWidget.getWidgetData<String>(_keyLang);
    if (lang == null || !kSupportedLanguages.contains(lang)) {
      lang = normalizeLang(defaultLangIfUnset);
      // If words exist in exactly one language, show that one — the default is
      // only a guess, and an empty widget is worse than the wrong tab. Once the
      // user has picked a language we leave it alone, even when it's empty.
      if (withWords.length == 1) lang = withWords.first;
      await HomeWidget.saveWidgetData<String>(_keyLang, lang);
    }

    await HomeWidget.saveWidgetData<String>(
      _keyLangs,
      (withWords.isEmpty ? kSupportedLanguages.toList() : withWords).join(','),
    );

    // The native widget can't reach AppStrings, so its chrome was hardcoded
    // Japanese for everyone. Push the localized text instead.
    final ui = normalizeLang(appLanguageCode);
    await HomeWidget.saveWidgetData<String>(
      _keyTitle,
      AppStrings.of(ui, 'notebookTitle'),
    );
    await HomeWidget.saveWidgetData<String>(
      _keyEmpty,
      AppStrings.of(ui, 'notebookEmpty'),
    );
    await HomeWidget.saveWidgetData<String>(
      _keyGalleryDesc,
      AppStrings.of(ui, 'widgetGalleryDescription'),
    );
    // Endonym: reads correctly whatever the UI language is.
    await HomeWidget.saveWidgetData<String>(
      _keyLangLabel,
      languageEndonym(lang),
    );

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
