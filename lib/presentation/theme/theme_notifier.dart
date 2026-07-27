import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/ui/paper/paper_theme.dart';

/// Provides the app-wide paper-cartoon theme (light + dark) and the user's
/// appearance choice. The soft-cyber look is designed light-first, so the
/// DEFAULT stays light — dark is opt-in from Settings (or follow the system).
class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier() {
    unawaited(_load());
  }

  static const _prefKey = 'app_theme_mode';

  ThemeMode _mode = ThemeMode.light;

  ThemeData get theme => PaperTheme.light;
  ThemeData get darkTheme => PaperTheme.dark;
  ThemeMode get mode => _mode;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      final restored = switch (saved) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        'light' => ThemeMode.light,
        _ => null,
      };
      if (restored != null && restored != _mode) {
        _mode = restored;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setMode(ThemeMode value) async {
    if (value == _mode) return;
    _mode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, switch (value) {
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
      });
    } catch (_) {}
  }
}
