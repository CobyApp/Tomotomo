enum AppLanguage {
  korean,
  japanese,
  english;
  
  String get code {
    switch (this) {
      case AppLanguage.korean:
        return 'ko';
      case AppLanguage.japanese:
        return 'ja';
      case AppLanguage.english:
        return 'en';
    }
  }
  
  String get displayName {
    switch (this) {
      case AppLanguage.korean:
        return '한국어';
      case AppLanguage.japanese:
        return '日本語';
      case AppLanguage.english:
        return 'English';
    }
  }
} 