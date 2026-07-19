import 'package:flutter/material.dart';
import '../../core/locale/study_language.dart';
import '../../domain/repositories/profile_repository.dart';

/// Resolves which language's friends the user practices with.
///
/// Onboarding lets the user pick this explicitly (Japanese vs Korean friend).
/// When a choice was made it wins; otherwise we fall back to deriving the
/// target language from the app UI language (backward-compatible for users
/// who existed before onboarding shipped).
class FriendLanguageNotifier extends ChangeNotifier {
  FriendLanguageNotifier(this._profileRepo);

  final ProfileRepository _profileRepo;

  /// Explicitly chosen friend language (`ko` | `ja`), or null when unset.
  String? _chosen;
  String? get chosen => _chosen;

  /// Effective friend/target language for [appLanguageCode].
  String resolve(String appLanguageCode) =>
      _chosen ?? studyLanguageForApp(appLanguageCode);

  /// Loads the persisted choice (call once at startup).
  Future<void> load() async {
    try {
      _chosen = await _profileRepo.getFriendLanguage();
      notifyListeners();
    } catch (_) {}
  }

  /// Persists a new friend-language choice and updates the in-memory value.
  Future<void> setLanguage(String code) async {
    if (code != 'ko' && code != 'ja') return;
    await _profileRepo.setFriendLanguage(code);
    _chosen = code;
    notifyListeners();
  }
}
