import 'package:hive_ce/hive.dart';

import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../local/local_json_store.dart';

/// Local profile persistence in the `settings` box.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(Box box) : _store = LocalJsonStore(box);
  final LocalJsonStore _store;

  static const _kAppLanguage = 'profile_app_language';
  static const _kLearningLanguage = 'profile_learning_language';
  static const _kDisplayName = 'profile_display_name';
  static const _kAvatarUrl = 'profile_avatar_url';
  static const _kCreatedAt = 'profile_created_at';

  @override
  Future<Profile?> getProfile(String userId) async {
    final createdAtRaw = _store.getValue(_kCreatedAt) as String?;
    if (createdAtRaw == null) {
      // No local profile yet: create and persist defaults.
      final now = DateTime.now();
      final profile = Profile(
        id: userId,
        appLanguage: 'ko',
        learningLanguage: 'ja',
        createdAt: now,
        updatedAt: now,
      );
      await _persist(profile, createdAt: now);
      return profile;
    }
    final createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    return Profile(
      id: userId,
      displayName: _store.getValue(_kDisplayName) as String?,
      avatarUrl: _store.getValue(_kAvatarUrl) as String?,
      appLanguage: (_store.getValue(_kAppLanguage) as String?) ?? 'ko',
      learningLanguage:
          (_store.getValue(_kLearningLanguage) as String?) ?? 'ja',
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Profile> updateProfile(Profile profile) async {
    final createdAtRaw = _store.getValue(_kCreatedAt) as String?;
    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw)
        : null;
    await _persist(profile, createdAt: createdAt ?? profile.createdAt);
    final updated = await getProfile(profile.id);
    return updated ?? profile;
  }

  Future<void> _persist(Profile profile, {required DateTime createdAt}) async {
    await _store.putValue(_kAppLanguage, profile.appLanguage);
    await _store.putValue(_kLearningLanguage, profile.learningLanguage);
    await _store.putValue(_kDisplayName, profile.displayName);
    await _store.putValue(_kAvatarUrl, profile.avatarUrl);
    await _store.putValue(_kCreatedAt, createdAt.toIso8601String());
  }
}
