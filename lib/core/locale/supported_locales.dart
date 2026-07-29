import 'dart:ui' show Locale;

import 'languages.dart';

/// Locales handed to `MaterialApp.supportedLocales`.
///
/// Derived from [kSupportedLanguages] on purpose: Flutter resolves a `locale`
/// that is absent from this list to `supportedLocales.first`, so a language the
/// user can pick in Settings but that is missing here would show every
/// OS-supplied string (text selection toolbar, default dialog buttons, semantic
/// labels) in the first listed language instead. Keeping the two in sync by
/// construction means adding a language can't reintroduce that drift.
final List<Locale> kAppSupportedLocales = List.unmodifiable(
  kSupportedLanguageList.map(Locale.new),
);
