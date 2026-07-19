import '../entities/profile.dart';

abstract class ProfileRepository {
  /// The single local profile (created with defaults if absent).
  Future<Profile?> getProfile(String userId);
  Future<Profile> updateProfile(Profile profile);

  /// Whether the first-run onboarding flow has been completed.
  Future<bool> isOnboarded();

  /// Marks first-run onboarding as complete.
  Future<void> setOnboarded();

  /// User nationality picked during onboarding (`ko` | `ja` | `other`), or null.
  Future<String?> getNationality();
  Future<void> setNationality(String? value);

  /// The friend/learning language the user explicitly chose during onboarding
  /// (`ko` | `ja`), or null when never chosen (derive from app language).
  Future<String?> getFriendLanguage();
  Future<void> setFriendLanguage(String code);
}
