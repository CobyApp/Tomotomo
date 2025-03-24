import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class L10n extends ChangeNotifier {
  static final L10n _instance = L10n._internal();
  
  factory L10n() => _instance;
  
  L10n._internal();
  
  static L10n of(BuildContext context) {
    return Provider.of<L10n>(context, listen: false);
  }
  
  static final Map<String, Map<String, String>> _localizedValues = {
    'ko': {
      'settings': '설정',
      'language': '언어',
      'chat': '채팅',
      'send': '보내기',
      'typing': '입력 중...',
      'selectCharacter': '캐릭터 선택',
    },
    'ja': {
      'settings': '設定',
      'language': '言語',
      'chat': 'チャット',
      'send': '送信',
      'typing': '入力中...',
      'selectCharacter': 'キャラクター選択',
    },
    'en': {
      'settings': 'Settings',
      'language': 'Language',
      'chat': 'Chat',
      'send': 'Send',
      'typing': 'Typing...',
      'selectCharacter': 'Select Character',
    },
  };
  
  String get settings => _localizedValues[_currentLanguage]!['settings']!;
  String get language => _localizedValues[_currentLanguage]!['language']!;
  String get chat => _localizedValues[_currentLanguage]!['chat']!;
  String get send => _localizedValues[_currentLanguage]!['send']!;
  String get typing => _localizedValues[_currentLanguage]!['typing']!;
  String get selectCharacter => _localizedValues[_currentLanguage]!['selectCharacter']!;
  
  String _currentLanguage = 'ko';
  String get currentLanguage => _currentLanguage;
  
  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
    notifyListeners();
  }
} 