# Gemma 4 E2B On-Device AI Design

## Goal

Replace every Gemini-backed AI operation with Gemma 4 E2B IT running locally through LiteRT-LM on iOS and Android. After a one-time model download, character chat and expression analysis must work without a network connection. No cloud-AI fallback is allowed.

The first release is text-only. Gemma 4 image and audio inputs are outside this scope.

## Product Decisions

- Use the instruction-tuned Gemma 4 E2B mobile LiteRT-LM artifact.
- Download the approximately 2.6 GB model after explicit user consent on first launch.
- Use the official LiteRT-LM Kotlin API on Android and Swift API on iOS.
- Keep the existing `AiChatRepository` boundary and structured chat response contract.
- Move character chat, expression analysis, and X-profile persona generation to the local model.
- Preserve the existing local points and rewarded-ad behavior.
- Do not send prompts to Gemini or another cloud model when local inference is unavailable.
- X-profile URL import still needs a network connection to retrieve public source text. Its AI transformation runs locally.

## Architecture

### Flutter layer

`OnDeviceModelManager` owns the user-visible model lifecycle:

- unsupported, not installed, downloading, verifying, ready, and failed states;
- download progress, cancellation, and resumption;
- installed model version and file size;
- model deletion and reinstallation;
- free-space and runtime compatibility checks.

`LiteRtLmAiRepositoryImpl` implements the existing `AiChatRepository`. It builds the current character system prompts, sends requests through the native bridge, keeps a bounded recent-history window, parses the existing JSON response, and maps native failures to application errors.

The current Gemini-specific celebrity persona service becomes a local persona service that reuses `XProfileReader`, sends the fetched or pasted profile text to Gemma, and validates the returned persona JSON in Dart.

### Native bridge

A Method Channel exposes infrequent commands:

- inspect compatibility and installation state;
- start, resume, cancel, or delete a model download;
- load and unload the model;
- create, reset, or dispose a generation session;
- generate structured text;
- cancel active generation.

An Event Channel publishes download, verification, model-loading, completion, and failure events. Channel payloads use stable string enum values and JSON-compatible primitives.

Android integrates the official LiteRT-LM Kotlin API. iOS integrates the official LiteRT-LM Swift package. Both implementations use GPU acceleration first and local CPU execution as the fallback. They never use a network inference service.

### Model artifact

The app downloads the official `litert-community/gemma-4-E2B-it-litert-lm` artifact from a version-pinned immutable Hugging Face CDN URL. Release configuration contains the artifact revision, expected byte count, and SHA-256 checksum. A model becomes usable only after all three values match.

The temporary download and installed model live in app-private storage. iOS marks the model as excluded from iCloud backup. Android uses internal app storage and requests no broad storage permission.

The installer requires enough free space for the complete model, the temporary partial file, and safety overhead. It therefore requires at least twice the artifact size plus 512 MB before a fresh download. A resumed download only requires the remaining bytes plus 512 MB.

## User Flow

On first launch, an in-app Japanese setup screen explains:

- `オンデバイスAIモデル`
- the approximately 2.6 GB download size;
- that Wi-Fi is recommended;
- that chat works offline after installation;
- that unsupported devices cannot use AI features.

The user starts the download with `ダウンロード`. The screen shows progress and offers cancel and resume actions. AI entry points remain disabled until verification and a model-load smoke test succeed.

Settings gains a model-management destination showing model name, version, size, and status. It provides `再ダウンロード` and `モデルを削除`. Destructive deletion requires confirmation.

Unsupported hardware, insufficient storage, download failure, checksum mismatch, and runtime-load failure each receive a specific Japanese explanation and an actionable retry or storage-management path. No error path silently switches to cloud AI.

## Inference Flow

### Character chat

1. Flutter verifies that the model is ready.
2. The repository builds the existing character and UI-language system prompt.
3. It sends the system prompt, recent conversation window, and user message to the native session.
4. LiteRT-LM uses constrained JSON generation when available.
5. Dart extracts and validates the existing response fields: content, translation, learning note, and vocabulary.
6. Only a valid successful response is added to history and charged according to the existing one-point policy.

The first implementation targets a 4,096-token context budget and a 768-token output budget. History is trimmed from the oldest complete user/model pair while always retaining the system prompt and current user message.

### Expression analysis

Expression analysis uses a separate short-lived local session so it cannot mutate character-chat history. Existing cached analysis remains valid. A cache miss invokes Gemma locally and stores only a successfully parsed result.

### X-profile persona generation

`XProfileReader` continues to normalize and retrieve the public profile page. Pasted profile text remains available when crawling fails. The local persona prompt requests the current persona schema, and Dart validates language, names, tagline, speech style, and avatar URL allow-listing. This feature reports that source retrieval needs internet; it does not describe itself as fully offline.

## Lifecycle and Concurrency

Only one generation runs at a time per native model instance. Additional requests receive a busy result rather than starting competing high-memory sessions.

Moving the app to the background cancels active generation and preserves completed model downloads. Native download facilities support resumption after interruption. The model remains unloaded until an AI feature needs it and may be released after sustained inactivity or a memory-pressure callback.

Model installation uses an atomic rename after verification. Partial and invalid files are never exposed as installed models.

## Compatibility Policy

Both platforms require a 64-bit ARM device. iOS keeps its existing 15.0 minimum. Android raises its minimum API level to 24, which is the LiteRT-LM Kotlin runtime minimum. Compatibility checks consider:

- runtime and backend availability;
- available storage;
- available memory reported by the platform where reliable;
- a lightweight model-load smoke test after installation.

The app does not claim support based only on OS version or device marketing name. If GPU initialization fails, it tries local CPU execution. If both fail, AI features remain unavailable with a local diagnostic message.

## Error Handling

Errors are mapped into stable application categories:

- unsupported device;
- model not installed;
- insufficient storage;
- network interrupted during model download;
- artifact integrity failure;
- model load failure;
- generation busy;
- generation cancelled;
- invalid structured response;
- native runtime failure.

Downloads retry only transient network failures with bounded exponential backoff. Integrity and runtime failures require an explicit user retry. A generation failure does not consume points or append chat history.

## Privacy and Networking

After model installation, character chat and expression-analysis prompts do not leave the device. Gemini dependencies, API keys, configuration, retry code, and documentation are removed.

Network access remains for:

- the one-time model download and later user-requested re-downloads;
- X-profile source retrieval;
- rewarded ads and other existing non-AI network features.

The UI distinguishes these network operations from local AI inference.

## Testing

### Dart tests

- model-state transitions and persisted installation metadata;
- download progress, cancellation, resumption, and integrity failures;
- native error-to-domain error mapping;
- bounded history behavior;
- chat and persona structured-response parsing;
- points charged only after successful chat generation;
- no Gemini configuration or dependency remains.

### Native tests

- channel request and event payload contracts;
- storage-path and backup-exclusion behavior;
- artifact verification and atomic installation;
- session creation, cancellation, and disposal;
- GPU-to-CPU local fallback;
- memory-pressure and background lifecycle handling.

### Integration and device tests

- clean installation and interrupted/resumed model download;
- insufficient-storage and corrupt-artifact recovery;
- real iPhone and Galaxy model load and text generation;
- character chat and expression analysis in airplane mode;
- app backgrounding during generation;
- X-profile import network messaging;
- release builds on both platforms.

## Rollout Boundary

This change ships as a complete replacement rather than a user-selectable backend. It does not include cloud fallback, multimodal prompts, background prefetch without consent, model fine-tuning, multiple downloadable models, or automatic model updates. A newer model requires a deliberate app release that changes the pinned artifact metadata.
