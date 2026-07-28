import 'package:flutter/material.dart';
import '../../core/di/injection.dart';
import '../../core/locale/languages.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// UI language from profile `app_language` (`ko` | `ja` | `en` | `zh`).
class LocaleNotifier extends ChangeNotifier {
  LocaleNotifier(this._profileRepo);

  final ProfileRepository _profileRepo;
  String _languageCode = 'ko';

  String get languageCode => _languageCode;
  Locale get locale => Locale(_languageCode);

  Future<void> loadFromProfile(String userId) async {
    try {
      final p = await _profileRepo.getProfile(userId);
      if (p != null && kSupportedLanguages.contains(p.appLanguage)) {
        _languageCode = p.appLanguage;
        appLanguageCode = _languageCode;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Persists locally and updates the in-memory locale.
  Future<void> setAppLanguage(String code, Profile profile) async {
    if (!kSupportedLanguages.contains(code)) return;
    final updated = profile.copyWith(appLanguage: code);
    await _profileRepo.updateProfile(updated);
    _languageCode = code;
    appLanguageCode = _languageCode;
    notifyListeners();
  }
}
