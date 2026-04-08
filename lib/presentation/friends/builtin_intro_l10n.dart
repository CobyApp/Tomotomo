/// L10n keys for built-in character self-intro copy ([AppStrings]).
String? builtinCharacterIntroKey(String characterId) {
  switch (characterId) {
    case 'yuna':
      return 'friendsBuiltinIntroYuna';
    case 'junho':
      return 'friendsBuiltinIntroJunho';
    default:
      return null;
  }
}
