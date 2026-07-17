/// Returns the language the user is studying for the current app language.
///
/// Japanese UI users study Korean; Korean UI users study Japanese.
String studyLanguageForApp(String appLanguageCode) {
  return appLanguageCode == 'ja' ? 'ko' : 'ja';
}
