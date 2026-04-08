/// L10n keys for built-in tutor one-line blurb (~20 chars, [AppStrings] per app language).
String? builtinCharacterShortKey(String characterId) {
  switch (characterId) {
    case 'yuna':
      return 'friendsBuiltinShortYuna';
    case 'junho':
      return 'friendsBuiltinShortJunho';
    default:
      return null;
  }
}
