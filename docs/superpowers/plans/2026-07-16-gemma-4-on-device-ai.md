# Gemma 4 E2B On-Device AI Implementation Plan

## Completed implementation

- Add the pinned Gemma 4 E2B artifact configuration and an injectable on-device runtime.
- Integrate the LiteRT-LM `.litertlm` path through the Google-documented Flutter package.
- Add model download, cancellation, exact size/SHA-256 verification, ready/error state, and deletion.
- Replace character chat and expression analysis with `LiteRtLmAiRepositoryImpl`.
- Move X-profile persona generation to the same local runtime.
- Gate first launch on model setup and add model management to Settings.
- Remove the cloud generative-AI package, repository, retry helper, API keys, and current documentation.
- Raise platform requirements to Android API 24/ARM64 and iOS 16/ARM64 and add GPU runtime declarations/entitlements.
- Add model-manager and repository tests.

## Verification checklist

- [x] `flutter analyze`
- [x] `flutter test`
- [x] Android ARM64 build
- [x] iOS no-codesign build
- [ ] Real Android installation/download/inference in airplane mode
- [ ] Real iPhone installation/download/inference in airplane mode
- [ ] Download cancel/retry, corrupt-file recovery, model deletion, and GPU-to-CPU fallback
- [ ] Twenty-turn chat and repeated expression/persona requests without monotonic memory growth
