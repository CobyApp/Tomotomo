import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/user_theme.dart';
import '../../domain/repositories/theme_repository.dart';

/// Holds user theme overrides and builds [ThemeData]. Load/save via [ThemeRepository].
class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier(this._repo);

  final ThemeRepository _repo;
  UserTheme? _overrides;
  String? _userId;

  UserTheme? get overrides => _overrides;

  bool get _hasOverrides =>
      _overrides != null &&
      (_overrides!.accent != null ||
          _overrides!.chatBubbleUser != null ||
          _overrides!.chatBubbleBot != null ||
          _overrides!.chatBg != null);

  ThemeData get theme {
    if (!_hasOverrides) {
      return AppTheme.light;
    }
    return AppTheme.buildWithOverrides(
      AppTheme.light,
      accent: _overrides!.accent,
      chatBubbleUser: _overrides!.chatBubbleUser,
      chatBubbleBot: _overrides!.chatBubbleBot,
      chatBg: _overrides!.chatBg,
    );
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
