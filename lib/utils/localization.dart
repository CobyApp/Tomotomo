import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class L10n extends ChangeNotifier {
  static final L10n _instance = L10n._internal();
  
  factory L10n() => _instance;
  
  L10n._internal();
  
  String _currentLocale = 'ko';

  String get currentLocale => _currentLocale;

  void setLocale(String locale) {
    if (_currentLocale != locale) {
      _currentLocale = locale;
      notifyListeners();
    }
  }

  static L10n of(BuildContext context) {
    return context.read<L10n>();
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
  
  String get settings => _localizedValues[_currentLocale]!['settings']!;
  String get language => _localizedValues[_currentLocale]!['language']!;
  String get chat => _localizedValues[_currentLocale]!['chat']!;
  String get send => _localizedValues[_currentLocale]!['send']!;
  String get typing => _localizedValues[_currentLocale]!['typing']!;
  String get selectCharacter => _localizedValues[_currentLocale]!['selectCharacter']!;
  
  void setLanguage(String languageCode) {
    _currentLocale = languageCode;
    notifyListeners();
  }

  String messageHint(String characterName) {
    switch (_currentLocale) {
      case 'ja':
        return '$characterNameにメッセージを送る...';
      case 'en':
        return 'Message to $characterName...';
      default:
        return '$characterName에게 메시지...';
    }
  }
} 