import '../entities/profile.dart';

abstract class ProfileRepository {
  /// The single local profile (created with defaults if absent).
  Future<Profile?> getProfile(String userId);
  Future<Profile> updateProfile(Profile profile);
}
