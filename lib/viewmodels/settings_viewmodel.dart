import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_language.dart';
import '../utils/localization.dart';
import 'package:flutter/material.dart';

class SettingsViewModel extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  AppLanguage _currentLanguage = AppLanguage.korean;
  
  AppLanguage get currentLanguage => _currentLanguage;
  
  SettingsViewModel() {
    _loadLanguage();
  }
  
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'ko';
    _currentLanguage = AppLanguage.values.firstWhere(
      (lang) => lang.code == languageCode,
      orElse: () => AppLanguage.korean,
    );
    notifyListeners();
  }
  
  Future<void> setLanguage(AppLanguage language, BuildContext context) async {
    if (_currentLanguage == language) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);
    _currentLanguage = language;
    
    // L10n 업데이트
    L10n().setLanguage(language.code);
    
    notifyListeners();
  }
} 