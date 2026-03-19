import '../entities/user_theme.dart';

abstract class ThemeRepository {
  Future<UserTheme?> getTheme(String userId);
  Future<void> saveTheme(String userId, UserTheme theme);
}
