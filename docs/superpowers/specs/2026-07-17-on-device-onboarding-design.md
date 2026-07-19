# On-Device Model Onboarding Design

## Goal

Give non-technical users a clear explanation of Tomotomo's on-device AI, then guide first-time users from Gemma installation through learning-language and nickname setup before entering the main app.

## Scope

- Explain local AI chat and learning in approachable Japanese copy.
- Explain that supported AI processing and saved learning data stay on the device.
- Show download, verification, completion, and recoverable error states.
- Require an explicit `はじめる` action after installation.
- Let users choose Japanese or Korean as their learning language.
- Ask for a nickname using copy and examples in the selected learning language.
- Persist profile setup and onboarding completion locally.
- Route completed users directly to the main shell on later launches.
- Add automated coverage for state transitions and onboarding routing.

The design does not claim that every app feature is offline or that no platform service can ever communicate externally. Privacy copy describes the on-device AI and locally persisted learning data specifically.

## User Flow

1. On launch, the app checks the Gemma artifact and local onboarding state.
2. If Gemma is missing, the model setup screen explains the benefits of on-device AI and starts the download.
3. Download progress is shown as a percentage.
4. After the network transfer reaches 100%, the screen changes to a distinct `確認中` state while the 2.59 GB artifact is hashed.
5. When verification succeeds, a completion card and `はじめる` button appear. The app does not navigate automatically.
6. The learning-language screen offers `日本語` and `한국어`.
7. The nickname screen renders its title, guidance, hint, and example in the chosen learning language. Input remains unrestricted so mixed-script names are accepted.
8. Submitting a non-empty nickname updates the local profile, marks onboarding complete, and opens `MainShell`.
9. Later launches with a verified model and completed onboarding open `MainShell` directly.
10. If the model exists but onboarding is incomplete, the app resumes at the first incomplete onboarding step.

## Architecture

### Root gate

Replace the current `manager.isReady ? MainShell : OnDeviceModelSetupScreen` decision with an onboarding coordinator. The coordinator derives the current screen from:

- `OnDeviceModelSnapshot.phase`
- persisted profile values
- a persisted onboarding completion flag
- in-memory onboarding step selection while the flow is active

The coordinator owns transitions; individual screens only report user actions.

### Model lifecycle

Extend `OnDeviceModelPhase` with `verifying`. `OnDeviceModelManager` moves from `downloading` to `verifying` when network transfer completes and before artifact hashing starts. `ready` is published only after verification succeeds.

`FlutterGemmaAiRuntime` reports verification start through an explicit callback. Verification remains off the UI isolate. The runtime does not call `getActiveModel()` during installation or onboarding, preventing download completion from eagerly allocating inference memory.

### Onboarding persistence

The existing local profile remains the source of truth for:

- `learningLanguage`
- `displayName`

Store a dedicated local boolean for onboarding completion. Defaults alone must not count as completion because `ProfileRepositoryImpl` currently creates a profile automatically. Persist the profile first and the completion flag last, so interrupted writes resume onboarding instead of incorrectly opening the main app.

Store a separate language-selection marker after persisting the chosen profile language. This distinguishes an explicit Japanese choice from the repository's Japanese default and allows an interrupted flow to resume at nickname entry.

### Screens

1. `OnDeviceModelSetupScreen`
   - Plain-language privacy and offline capability explanation.
   - Model size and storage requirement.
   - Download progress, verification state, retryable error, and completion CTA.
2. `LearningLanguageScreen`
   - Two large choices: Japanese and Korean.
   - Continue action enabled after selection.
3. `NicknameSetupScreen`
   - Localized from the selected learning language rather than the app locale.
   - Trims input and rejects only empty values.
4. `OnboardingCoordinator`
   - Restores the correct step.
   - Persists final setup.
   - Opens `MainShell` only after all requirements are satisfied.

All user-visible copy is available in Japanese and Korean localization maps. The initial setup UI follows the app's existing paper visual system.

## Error Handling and Stability

- A 100% download is not presented as completed until hashing finishes.
- Verification failures delete the invalid artifact and expose a retry action.
- Late download callbacks after cancellation cannot revive installation state.
- Repeated taps cannot start duplicate downloads or duplicate profile submissions.
- Profile-save failures keep the user on the nickname screen and show a localized recoverable error.
- Root routing waits for both model and onboarding checks, avoiding a transient main-screen render.
- Model and onboarding initialization start after `runApp()`, so a missing verification cache cannot hold the app on the native launch screen while hashing the artifact.
- Native inference loading remains lazy. Diagnostic logging around first model creation distinguishes an OS-level memory termination from an onboarding/navigation failure.

The previously reported post-download failure cannot be conclusively attributed to native out-of-memory behavior without device logs. The confirmed UX defect is the unlabelled full-file hash after 100%, and the confirmed routing risk is automatic root replacement immediately after verification. Both are addressed directly; first-inference device validation remains part of verification.

## Testing

- Model manager tests:
  - publishes `verifying` after download and before `ready`
  - reaches `ready` only after verification succeeds
  - handles verification failure and retry
  - ignores late progress after cancellation
- Coordinator tests:
  - missing model shows setup
  - ready model with incomplete onboarding shows language selection
  - selected language advances to nickname
  - saved nickname and completion open the main shell
  - completed onboarding restores the main shell on relaunch
- Widget tests:
  - privacy explanation and storage size render
  - verification copy renders at 100%
  - completion requires tapping `はじめる`
  - nickname copy follows the selected learning language
  - blank nickname is rejected
- Existing unit and widget suites remain green.
- Real-device checks cover download, verification duration, cancellation/retry, relaunch during verification, onboarding resume, first inference, and memory behavior in profile/release builds.

## Success Criteria

- Users can explain from the setup screen that AI chat and learning run on their device and that supported data stays local.
- The UI never appears frozen at 100%; it explicitly shows verification.
- Download completion never skips directly to the main page.
- Language and nickname setup are required once and restored correctly after interruption.
- Returning configured users do not see onboarding.
- No automated regression is introduced, and first inference is validated on a supported physical device.
