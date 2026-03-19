import '../../core/supabase/app_supabase.dart';
import '../../domain/entities/user_theme.dart';
import '../../domain/repositories/theme_repository.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  @override
  Future<UserTheme?> getTheme(String userId) async {
    final res = await AppSupabase.client
        .from('themes')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();
    if (res == null) return null;
    return UserTheme.fromRow(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<void> saveTheme(String userId, UserTheme theme) async {
    await AppSupabase.client.from('themes').upsert({
      'user_id': userId,
      ...theme.toRow(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
