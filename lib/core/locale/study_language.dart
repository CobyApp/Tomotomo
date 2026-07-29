import 'languages.dart';

/// The language a user is assumed to be studying, from their app UI language.
///
/// This is only a FALLBACK. Onboarding asks outright and persists the answer
/// (`FriendLanguageNotifier`), so this applies to installs made before that
/// question existed and to the moment before onboarding finishes. Japanese UI →
/// Korean; every other UI → Japanese, which is what the app launched as.
String studyLanguageForApp(String appLanguageCode) =>
    normalizeLang(appLanguageCode) == 'ja' ? 'ko' : 'ja';
