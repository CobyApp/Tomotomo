# Gemma 4 E2B On-Device AI Design

## Goal

Run character chat, expression analysis, and X-profile persona generation locally with Gemma 4 E2B. After the user installs the model once, inference must not send prompts to a cloud model or silently fall back to one.

## Runtime

The app uses the modular `flutter_gemma` and `flutter_gemma_litertlm` 1.0.0-rc.1 packages, the newest modular release compatible with the repository's Flutter 3.41/Dart 3.11 toolchain. This is the Flutter integration linked by Google's LiteRT-LM Flutter guide. Only the `.litertlm` engine is included; MediaPipe, embeddings, RAG, and image-generation runtimes are not shipped. The engine provides Android and iOS inference, serialized generation, download cancellation, an Android foreground downloader, and GPU-to-CPU fallback.

The app targets ARM64 only for Android LiteRT-LM and raises the platform minimums to Android API 24 and iOS 16. iOS receives the extended virtual-addressing and increased-memory entitlements recommended for large models. Android declares optional OpenCL libraries.

## Model artifact

The single supported artifact is:

- repository: `litert-community/gemma-4-E2B-it-litert-lm`
- revision: `9262660a1676eed6d0c477ab1a86344430854664`
- file: `gemma-4-E2B-it.litertlm`
- size: `2,588,147,712` bytes
- SHA-256: `181938105e0eefd105961417e8da75903eacda102c4fce9ce90f50b97139a63c`

The model is usable only after exact size and SHA-256 verification. A successful digest is persisted so later launches only need the cheap file and size checks. Deleting the model clears both the artifact and verification marker.

## Flutter architecture

`OnDeviceAiRuntime` isolates the third-party runtime behind an injectable interface. `FlutterGemmaAiRuntime` initializes the plugin, installs and verifies the artifact, lazily loads one model, serializes requests, and exposes text generation. The model tries GPU first and falls back locally to CPU.

`OnDeviceModelManager` owns user-visible checking, not-installed, downloading, ready, and error states. The first app screen blocks AI use until the model is ready. Settings exposes the same screen for status and deletion.

`LiteRtLmAiRepositoryImpl` keeps the existing `AiChatRepository` boundary and prompt/JSON parser. It sends a bounded recent transcript on every request, so a short-lived inference chat can be recreated without losing the product conversation. Expression analysis uses a separate one-shot prompt and never mutates that history.

`CelebrityPersonaSuggester` still lets `XProfileReader` fetch a public X page or accepts pasted text. Only the source fetch uses the network; persona extraction runs through `OnDeviceAiRuntime`. Dart validates the returned names, language, tagline, speech style, and avatar allow-list.

## Product behavior

The setup screen explains the 2.59GB download and offline behavior, displays progress, and supports cancellation. Model installation is explicit and never starts in the background without user action. A generation failure does not append successful history or charge points.

Network access remains only for model download, X source retrieval, rewarded ads, and existing non-AI features. The environment file remains solely for production AdMob IDs; AI keys and cloud-AI dependencies are removed.

## Verification

- `flutter analyze`
- all Dart unit/widget tests
- Android ARM64 debug build
- iOS no-codesign device build
- real-device model installation, checksum verification, GPU/CPU selection, airplane-mode chat, cancellation, deletion, and memory testing

The repository tests use an injected fake runtime. Full inference cannot be validated on a simulator alone and remains a required release acceptance step on representative iPhone and Android ARM64 hardware.
