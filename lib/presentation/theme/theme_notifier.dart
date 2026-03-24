import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/chat_theme_data.dart';
import '../../domain/entities/user_theme.dart';
import '../../domain/repositories/theme_repository.dart';

/// Holds user theme overrides and builds [ThemeData]. Load/save via [ThemeRepository].
class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier(this._repo);

  final ThemeRepository _repo;
  UserTheme? _overrides;
  String? _userId;

  UserTheme? get overrides => _overrides;

  ThemeData get theme {
    final o = _overrides;
    final seed = (o != null && o.accent != null && o.accent!.trim().isNotEmpty)
        ? AppTheme.parseAccentHex(o.accent)
        : AppTheme.seedColor;
    final chat = ChatThemeData.fromUserTheme(
      chatBubbleUser: o?.chatBubbleUser,
      chatBubbleBot: o?.chatBubbleBot,
      chatBg: o?.chatBg,
    );
    return AppTheme.buildLightTheme(seedColor: seed, chatExtension: chat);
  }

  Future<void> load(String? userId) async {
    _userId = userId;
    if (userId == null) {
      _overrides = null;
      notifyListeners();
      return;
    }
    try {
      _overrides = await _repo.getTheme(userId);
      notifyListeners();
    } catch (_) {
      _overrides = null;
      notifyListeners();
    }
  }

  Future<void> save(UserTheme theme) async {
    final uid = _userId;
    if (uid == null) return;
    await _repo.saveTheme(uid, theme);
    _overrides = theme;
    notifyListeners();
  }

  Future<void> clear() async {
    if (_userId == null) return;
    await _repo.saveTheme(_userId!, const UserTheme());
    _overrides = null;
    notifyListeners();
  }
}
