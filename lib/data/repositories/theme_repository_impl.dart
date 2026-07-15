import 'package:hive_ce/hive.dart';

import '../../domain/entities/user_theme.dart';
import '../../domain/repositories/theme_repository.dart';
import '../local/local_json_store.dart';

/// Local theme persistence in the `settings` box under a single `theme` key.
class ThemeRepositoryImpl implements ThemeRepository {
  ThemeRepositoryImpl(Box box) : _store = LocalJsonStore(box);
  final LocalJsonStore _store;

  static const _key = 'theme';

  @override
  Future<UserTheme?> getTheme(String userId) async {
    final json = _store.getItem(_key);
    if (json == null) return null;
    return UserTheme.fromJson(json);
  }

  @override
  Future<void> saveTheme(String userId, UserTheme theme) async {
    await _store.putItem(_key, theme.toJson());
  }
}
