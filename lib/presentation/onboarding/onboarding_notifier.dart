import 'package:flutter/material.dart';
import '../../domain/repositories/character_record_repository.dart';
import '../../domain/repositories/profile_repository.dart';

/// Drives the first-run gate in [App]. `onboarded == null` means "still
/// resolving"; the gate shows a light loading state until it settles.
class OnboardingNotifier extends ChangeNotifier {
  OnboardingNotifier(this._profileRepo, this._characterRepo);

  final ProfileRepository _profileRepo;
  final CharacterRecordRepository _characterRepo;

  bool? _onboarded;
  bool? get onboarded => _onboarded;
  bool get isLoading => _onboarded == null;

  /// Resolves whether onboarding should be shown.
  ///
  /// A user counts as already onboarded when either the explicit flag is set,
  /// or (backward-compatible for installs that predate onboarding) they already
  /// have at least one custom friend saved locally.
  Future<void> load() async {
    try {
      if (await _profileRepo.isOnboarded()) {
        _onboarded = true;
        notifyListeners();
        return;
      }
      final myCharacters = await _characterRepo.getMyCharacters();
      _onboarded = myCharacters.isNotEmpty;
    } catch (_) {
      _onboarded = false;
    }
    notifyListeners();
  }

  /// Marks onboarding complete and flips the gate to the main app.
  Future<void> complete() async {
    await _profileRepo.setOnboarded();
    _onboarded = true;
    notifyListeners();
  }
}
