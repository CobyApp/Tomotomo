import '../entities/profile.dart';

abstract class ProfileRepository {
  Future<Profile?> getProfile(String userId);
  Future<Profile> createProfile(String userId, {String? email, String? displayName});
  Future<Profile> updateProfile(Profile profile);
}
