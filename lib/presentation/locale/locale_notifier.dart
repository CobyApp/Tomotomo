import 'package:flutter/material.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// UI language from profile `app_language` (`ko` | `ja`).
class LocaleNotifier extends ChangeNotifier {
  LocaleNotifier(this._profileRepo);

  final ProfileRepository _profileRepo;
  String _languageCode = 'ko';

  String get languageCode => _languageCode;
  Locale get locale => Locale(_languageCode);

  Future<void> loadFromProfile(String userId) async {
    try {
      final p = await _profileRepo.getProfile(userId);
      if (p != null && (p.appLanguage == 'ko' || p.appLanguage == 'ja')) {
        _languageCode = p.appLanguage;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Persists to Supabase and updates in-memory locale.
  Future<void> setAppLanguage(String code, Profile profile) async {
    if (code != 'ko' && code != 'ja') return;
    final updated = profile.copyWith(appLanguage: code);
    await _profileRepo.updateProfile(updated);
    _languageCode = code;
    notifyListeners();
  }
}
