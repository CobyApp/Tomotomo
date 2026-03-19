import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../core/supabase/app_supabase.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  @override
  Future<Profile?> getProfile(String userId) async {
    final res = await AppSupabase.client
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();
    if (res == null) return null;
    return Profile.fromJson(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<Profile> createProfile(String userId, {String? email, String? displayName}) async {
    await AppSupabase.client.from('profiles').insert({
      'id': userId,
      'email': email,
      'display_name': displayName ?? email?.split('@').first,
    });
    final p = await getProfile(userId);
    if (p == null) throw Exception('Failed to create profile');
    return p;
  }

  @override
  Future<Profile> updateProfile(Profile profile) async {
    await AppSupabase.client.from('profiles').update({
      'display_name': profile.displayName,
      'avatar_url': profile.avatarUrl,
      'status_message': profile.statusMessage,
      'app_language': profile.appLanguage,
      'learning_language': profile.learningLanguage,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', profile.id);
    final p = await getProfile(profile.id);
    if (p == null) throw Exception('Failed to update profile');
    return p;
  }
}
