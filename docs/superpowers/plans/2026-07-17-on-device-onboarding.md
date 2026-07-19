# On-Device Model Onboarding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a stable Gemma installation-to-onboarding flow that explains local privacy, exposes artifact verification, collects a learning language and nickname, and enters the main app only after setup is complete.

**Architecture:** Keep model lifecycle in `OnDeviceModelManager`, profile/onboarding persistence in `ProfileRepository`, and first-run transitions in a focused `OnboardingController`. A root `OnboardingGate` derives the visible screen from model state plus onboarding state, while inference model allocation remains lazy.

**Tech Stack:** Flutter, Provider, Hive CE, flutter_gemma, flutter_test

---

## File Map

- Modify `lib/domain/on_device/on_device_model_snapshot.dart`: add the verification phase.
- Modify `lib/data/on_device/on_device_ai_runtime.dart`: expose verification-start notification.
- Modify `lib/data/on_device/flutter_gemma_ai_runtime.dart`: notify before full-file hashing and add diagnostic model-load logs.
- Modify `lib/data/on_device/on_device_model_manager.dart`: publish verification state.
- Modify `test/data/on_device/on_device_model_manager_test.dart`: cover download-to-verification transitions.
- Modify `lib/domain/repositories/profile_repository.dart`: expose onboarding persistence operations.
- Modify `lib/data/repositories/profile_repository_impl.dart`: store selected-language and completion markers.
- Modify `test/data/repositories/profile_repository_impl_test.dart`: cover interrupted and completed setup.
- Create `lib/presentation/onboarding/onboarding_controller.dart`: own the onboarding state machine.
- Create `test/presentation/onboarding/onboarding_controller_test.dart`: cover state restoration and submission.
- Modify `lib/presentation/on_device/on_device_model_setup_screen.dart`: add privacy explanation, verification UI, and explicit start action.
- Create `lib/presentation/onboarding/learning_language_screen.dart`: select Japanese or Korean.
- Create `lib/presentation/onboarding/nickname_setup_screen.dart`: collect a nickname using selected-language copy.
- Create `lib/presentation/onboarding/onboarding_flow.dart`: switch between language and nickname screens.
- Create `lib/presentation/onboarding/onboarding_gate.dart`: root routing from model and onboarding state.
- Modify `lib/core/l10n/app_strings.dart`: add Japanese and Korean user-visible copy.
- Modify `lib/core/di/injection.dart`: register the onboarding controller.
- Modify `lib/app.dart`: provide the controller and use the root gate.
- Modify `lib/main.dart`: render before long model verification begins.
- Create `test/presentation/onboarding/onboarding_gate_test.dart`: cover root routing.
- Create `test/presentation/onboarding/onboarding_screens_test.dart`: cover visible copy and form behavior.

### Task 1: Persist onboarding progress with the local profile

- [ ] Write failing repository tests in `test/data/repositories/profile_repository_impl_test.dart` proving:
  - a new profile is not complete and has no explicit learning-language selection;
  - saving `ja` or `ko` marks language selection without completing onboarding;
  - saving a trimmed nickname marks onboarding complete;
  - profile data is persisted before each progress marker.

Use the public API:

```dart
expect(await repository.hasSelectedLearningLanguage(), isFalse);
expect(await repository.isOnboardingComplete(), isFalse);

final selected = await repository.selectLearningLanguage('local', 'ko');
expect(selected.learningLanguage, 'ko');
expect(await repository.hasSelectedLearningLanguage(), isTrue);

final completed = await repository.completeOnboarding('local', ' 토모 ');
expect(completed.displayName, '토모');
expect(await repository.isOnboardingComplete(), isTrue);
```

- [ ] Run the focused test and verify RED:

```bash
flutter test test/data/repositories/profile_repository_impl_test.dart
```

Expected: compilation fails because the onboarding methods do not exist.

- [ ] Add these methods to `ProfileRepository`:

```dart
Future<bool> hasSelectedLearningLanguage();
Future<bool> isOnboardingComplete();
Future<Profile> selectLearningLanguage(String userId, String languageCode);
Future<Profile> completeOnboarding(String userId, String displayName);
```

- [ ] Implement them in `ProfileRepositoryImpl` using:

```dart
static const _kLearningLanguageSelected =
    'profile_learning_language_selected';
static const _kOnboardingComplete = 'profile_onboarding_complete';
```

`selectLearningLanguage` must validate `ja` or `ko`, persist the copied profile, then write `_kLearningLanguageSelected = true`. `completeOnboarding` must reject an empty trimmed value, persist the copied profile, then write `_kOnboardingComplete = true`.

- [ ] Re-run the focused test and verify GREEN.

### Task 2: Expose download verification as a real model state

- [ ] Extend `_FakeRuntime` and add a failing manager test:

```dart
test('install publishes verifying before ready', () async {
  final runtime = _FakeRuntime();
  final manager = OnDeviceModelManager(runtime);
  final phases = <OnDeviceModelPhase>[];
  manager.addListener(() => phases.add(manager.snapshot.phase));

  await manager.initialize();
  await manager.install();

  expect(
    phases,
    containsAllInOrder([
      OnDeviceModelPhase.downloading,
      OnDeviceModelPhase.verifying,
      OnDeviceModelPhase.ready,
    ]),
  );
});
```

- [ ] Run:

```bash
flutter test test/data/on_device/on_device_model_manager_test.dart
```

Expected: RED because `verifying` and `onVerificationStarted` do not exist.

- [ ] Add `verifying` to `OnDeviceModelPhase`.

- [ ] Change the runtime interface to:

```dart
Future<void> installModel({
  required void Function(double progress) onProgress,
  required VoidCallback onVerificationStarted,
});
```

- [ ] In `FlutterGemmaAiRuntime.installModel`, call `onVerificationStarted()` after `.install()` returns and immediately before `_verifyInstalledArtifact(forceHash: true)`.

- [ ] In `OnDeviceModelManager.install`, publish:

```dart
onVerificationStarted: () {
  if (_snapshot.phase != OnDeviceModelPhase.downloading) return;
  _setSnapshot(
    const OnDeviceModelSnapshot(
      phase: OnDeviceModelPhase.verifying,
      progress: 1,
    ),
  );
},
```

Update cancellation guards so verification cannot be cancelled through the download cancel button and late callbacks cannot change a cancelled state.

- [ ] Re-run the manager tests and verify GREEN.

### Task 3: Build and test the onboarding state machine

- [ ] Create `test/presentation/onboarding/onboarding_controller_test.dart` with a fake `ProfileRepository`. Cover:
  - incomplete fresh profile initializes to `language`;
  - selected language initializes to `nickname`;
  - completed profile initializes to `complete`;
  - selecting a language persists before moving to nickname;
  - blank nickname is rejected;
  - a save error remains on nickname and exposes an error;
  - repeated submission is ignored while saving.

- [ ] Run:

```bash
flutter test test/presentation/onboarding/onboarding_controller_test.dart
```

Expected: RED because the controller does not exist.

- [ ] Create `lib/presentation/onboarding/onboarding_controller.dart` with:

```dart
enum OnboardingStep { checking, language, nickname, complete, error }

class OnboardingController extends ChangeNotifier {
  OnboardingController(this._profiles);

  final ProfileRepository _profiles;
  OnboardingStep step = OnboardingStep.checking;
  Profile? profile;
  bool saving = false;
  String? errorMessage;

  bool get isComplete => step == OnboardingStep.complete;

  Future<void> initialize() async { /* restore markers and profile */ }
  Future<void> selectLanguage(String languageCode) async { /* persist */ }
  Future<bool> submitNickname(String value) async { /* trim and persist */ }
}
```

All state transitions notify listeners. `submitNickname` returns `false` for blank input or persistence errors and `true` only after completion is durable.

- [ ] Re-run the controller tests and verify GREEN.

### Task 4: Add privacy, completion, language, and nickname screens

- [ ] Add failing widget tests in `test/presentation/onboarding/onboarding_screens_test.dart` for:
  - Japanese setup copy includes `端末内`, `プライバシー`, and `2.59 GB`;
  - verification state displays `ダウンロードを確認しています`;
  - ready state displays `はじめる` and invokes `onStart`;
  - language screen offers `日本語` and `한국어`;
  - Japanese nickname screen shows `日本語でニックネームを決めましょう`;
  - Korean nickname screen shows `한국어로 닉네임을 정해 주세요`;
  - empty nickname does not submit.

- [ ] Run:

```bash
flutter test test/presentation/onboarding/onboarding_screens_test.dart
```

Expected: RED because the new screens and copy do not exist.

- [ ] Add localized keys to both maps in `lib/core/l10n/app_strings.dart`. Japanese setup copy should communicate:

```text
AIとのチャットや学習は、この端末の中で処理されます。
会話や学習データも端末内に保存されるため、
プライバシーを守りながら安心して自由に使えます。
```

Include accurate storage/download wording and avoid claiming unrelated network features are offline.

- [ ] Update `OnDeviceModelSetupScreen` to accept:

```dart
final VoidCallback? onStart;
```

Render privacy benefit cards, a `verifying` status with indeterminate progress, and a ready-state `PaperButton` labelled `はじめる` when `requiredSetup` is true.

- [ ] Create `LearningLanguageScreen` as a paper-style screen with two selectable cards and a disabled-until-selected continue action.

- [ ] Create `NicknameSetupScreen` with a `TextEditingController`, selected-language-specific text, blank validation, save progress, and inline recoverable errors.

- [ ] Create `OnboardingFlow` that watches `OnboardingController` and renders the language or nickname screen without Navigator races.

- [ ] Re-run the screen widget tests and verify GREEN.

### Task 5: Integrate a deterministic root gate

- [ ] Add failing tests in `test/presentation/onboarding/onboarding_gate_test.dart` proving:
  - checking model state displays setup checking UI;
  - missing model displays download UI;
  - ready model plus incomplete onboarding still displays the ready screen;
  - tapping `はじめる` opens the restored onboarding step;
  - completed onboarding plus ready model displays a supplied main child;
  - model errors remain recoverable and never briefly render the main child.

- [ ] Run:

```bash
flutter test test/presentation/onboarding/onboarding_gate_test.dart
```

Expected: RED because `OnboardingGate` does not exist.

- [ ] Create `OnboardingGate` with injectable `mainChild` for tests. It watches `OnDeviceModelManager` and `OnboardingController`, keeps an in-memory `started` flag, and follows:

```dart
if (!model.isReady) return const OnDeviceModelSetupScreen(requiredSetup: true);
if (onboarding.isComplete) return mainChild;
if (!started) {
  return OnDeviceModelSetupScreen(
    requiredSetup: true,
    onStart: () => setState(() => started = true),
  );
}
return const OnboardingFlow();
```

- [ ] Register `OnboardingController(profileRepository)` in `setupInjection` and provide it from `App`.

- [ ] Convert `App` to a `StatefulWidget`. In `initState`, schedule model and onboarding initialization after the first frame so native launch is not held while a missing hash cache triggers full verification.

- [ ] Remove `await onDeviceModelManager.initialize()` from `main.dart`; keep Hive and DI ready before `runApp`.

- [ ] Replace the current `Consumer<OnDeviceModelManager>` home logic in `app.dart` with `OnboardingGate(mainChild: const MainShell())`.

- [ ] Re-run gate tests and verify GREEN.

### Task 6: Add runtime diagnostics and complete verification

- [ ] Add lifecycle diagnostics around `_getModel` without logging prompts, responses, nicknames, or other personal content. Log only model-load start, selected backend, elapsed time, and caught error type in debug builds.

- [ ] Run formatting and static analysis:

```bash
dart format lib test
flutter analyze
```

Expected: no analyzer errors.

- [ ] Run all automated tests:

```bash
flutter test
```

Expected: all tests pass with no uncaught asynchronous errors.

- [ ] Run a supported physical-device profile/release check:
  1. Fresh install.
  2. Start download, cancel, and retry.
  3. Confirm 100% changes to `確認中`.
  4. Kill and relaunch during verification.
  5. Confirm `はじめる` opens language selection.
  6. Select each language and verify nickname copy.
  7. Kill and relaunch at nickname entry; confirm it resumes there.
  8. Submit nickname and confirm later launches open `MainShell`.
  9. Send the first chat message and record model-load backend, duration, and whether the OS terminates the process.

If the process terminates during step 9, collect the iOS crash report or Android logcat before changing token limits, speculative decoding, or backend preference. Treat native memory mitigation as a separate evidence-driven fix.
