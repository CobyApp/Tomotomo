import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:background_downloader/background_downloader.dart'
    show FileDownloader;
import 'package:crypto/crypto.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'on_device_ai_runtime.dart';
import 'on_device_model_config.dart';

final class FlutterGemmaAiRuntime implements OnDeviceAiRuntime {
  CancelToken? _cancelToken;
  InferenceModel? _model;
  Future<void> _queue = Future<void>.value();
  String? _activeBackend;
  static const _verifiedPreference = 'gemma4_e2b_artifact_verified';
  // Download group used by flutter_gemma's SmartDownloader.
  static const _downloadGroup = 'smart_downloads';

  @override
  String? get activeBackend => _activeBackend;

  @override
  Future<void> initialize() async {
    FlutterGemma.logLevel = GemmaLogLevel.none;
    await FlutterGemma.initialize(
      inferenceEngines: const [LiteRtLmEngine()],
      maxDownloadRetries: 5,
    );
  }

  @override
  Future<bool> isModelInstalled() async {
    if (!await FlutterGemma.isModelInstalled(OnDeviceModelConfig.fileName)) {
      return false;
    }
    return _verifyInstalledArtifact();
  }

  @override
  Future<void> installModel({
    required void Function(double progress) onProgress,
    void Function()? onVerifying,
  }) async {
    _cancelToken = CancelToken();
    // Resume, don't restart. iOS runs the download in a background URLSession
    // that keeps going while the app is backgrounded or even after it's killed,
    // and flutter_gemma's SmartDownloader reattaches to that still-running task
    // by its deterministic id. So if a live task exists (app backgrounded /
    // relaunched mid-download), we must NOT wipe it — otherwise the 2.59GB
    // download starts over from 0%. Only clear when there's nothing live to
    // attach to (a genuinely dead/absent task), which also avoids the
    // stuck-at-0% orphan-task case the clear originally guarded against.
    // Always drop the abandoned self-managed task first (see below) so it can
    // never keep re-pulling 2.59GB alongside the real download.
    await _clearAbandonedSelfManagedTask();
    if (!await _hasLiveDownloadTask()) {
      await _clearStaleDownloadState();
    }
    try {
      await FlutterGemma.installModel(
            modelType: ModelType.gemma4,
            fileType: ModelFileType.litertlm,
          )
          .fromNetwork(
            OnDeviceModelConfig.downloadUri.toString(),
            foreground: true,
          )
          .withCancelToken(_cancelToken!)
          .withProgress((value) => onProgress(value / 100))
          .install();
      // The download is complete; hashing the ~2.59GB artifact takes tens of
      // seconds. Signal the UI so 100% isn't perceived as a frozen download.
      onVerifying?.call();
      if (!await _verifyInstalledArtifact(forceHash: true)) {
        await _deleteInstalledArtifact();
        throw const FormatException('다운로드한 대화 엔진의 무결성 검증에 실패했습니다.');
      }
    } finally {
      _cancelToken = null;
    }
  }

  @override
  void cancelInstall() {
    _cancelToken?.cancel('사용자가 다운로드를 취소했습니다.');
    // Remove the task so the next attempt starts a fresh download.
    unawaited(_clearStaleDownloadState());
  }

  @override
  Future<void> resetDownloadState() async {
    _cancelToken?.cancel('다운로드를 초기화합니다.');
    _cancelToken = null;
    await _clearStaleDownloadState();
    // Drop a half-written artifact too, so the retry can't trip over it.
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_verifiedPreference);
      await FlutterGemmaPlugin.instance.modelManager.clearModelCache();
    } catch (_) {}
  }

  /// True when a download task is still enqueued/running in the background
  /// downloader (e.g. the app was backgrounded or relaunched mid-download).
  /// In that case we reattach and continue instead of restarting.
  ///
  /// `includeTasksWaitingToRetry` is deliberately FALSE: a task stuck in
  /// waitingToRetry counts as "active" by default, which made us attach to a
  /// dead task forever instead of clearing it — the download then sits frozen
  /// and never recovers. A retry-waiting task is treated as not live so the
  /// next attempt starts clean.
  Future<bool> _hasLiveDownloadTask() async {
    try {
      final tasks = await FileDownloader().allTasks(
        group: _downloadGroup,
        includeTasksWaitingToRetry: false,
      );
      return tasks.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Removes any orphaned/stale download task left by a previous interrupted
  /// download so a re-download starts cleanly (prevents the stuck-at-0% bug).
  Future<void> _clearStaleDownloadState() async {
    try {
      await FileDownloader().reset(group: _downloadGroup);
      await FileDownloader().database.deleteAllRecords(group: _downloadGroup);
    } catch (_) {
      // Best-effort: an empty/absent group is fine.
    }
    await _clearAbandonedSelfManagedTask();
  }

  /// One-time cleanup for builds that briefly downloaded the model through our
  /// own `tomotomo_model` group: an abandoned task there can sit in
  /// waitingToRetry and keep pulling 2.59GB in the background forever.
  Future<void> _clearAbandonedSelfManagedTask() async {
    const abandonedGroup = 'tomotomo_model';
    try {
      await FileDownloader().cancelAll(group: abandonedGroup);
      await FileDownloader().database.deleteAllRecords(group: abandonedGroup);
    } catch (_) {}
  }

  @override
  Future<void> deleteModel() async {
    await _model?.close();
    _model = null;
    _activeBackend = null;
    await _deleteInstalledArtifact();
  }

  Future<void> _deleteInstalledArtifact() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_verifiedPreference);
    if (await FlutterGemma.isModelInstalled(OnDeviceModelConfig.fileName)) {
      await FlutterGemma.uninstallModel(OnDeviceModelConfig.fileName);
      await FlutterGemmaPlugin.instance.modelManager.clearModelCache();
    }
  }

  Future<bool> _verifyInstalledArtifact({bool forceHash = false}) async {
    final manager = FlutterGemmaPlugin.instance.modelManager;
    final spec = manager.activeInferenceModel;
    if (spec == null) return false;
    final paths = await manager.getModelFilePaths(spec);
    final path = paths?.values
        .where((value) => value.endsWith(OnDeviceModelConfig.fileName))
        .firstOrNull;
    if (path == null) return false;
    final file = File(path);
    if (!await file.exists() ||
        await file.length() != OnDeviceModelConfig.byteCount) {
      return false;
    }

    final preferences = await SharedPreferences.getInstance();
    if (!forceHash &&
        preferences.getString(_verifiedPreference) ==
            OnDeviceModelConfig.sha256) {
      return true;
    }
    final digest = await Isolate.run(() async {
      final value = await sha256.bind(File(path).openRead()).first;
      return value.toString();
    });
    final valid = digest == OnDeviceModelConfig.sha256;
    if (valid) {
      await preferences.setString(
        _verifiedPreference,
        OnDeviceModelConfig.sha256,
      );
    }
    return valid;
  }

  Future<InferenceModel> _getModel(int maxTokens) async {
    final existing = _model;
    if (existing != null && existing.maxTokens == maxTokens) return existing;
    await existing?.close();
    final model = await FlutterGemma.getActiveModel(
      maxTokens: maxTokens,
      preferredBackend: PreferredBackend.gpu,
      enableSpeculativeDecoding: true,
      maxConcurrentSessions: 1,
    );
    _model = model;
    _activeBackend = model.activeBackend?.name;
    return model;
  }

  @override
  Future<String> generateText({
    required String systemInstruction,
    required String prompt,
    double temperature = 0.2,
    int maxTokens = 2048,
  }) {
    final result = Completer<String>();
    _queue = _queue.catchError((_) {}).then((_) async {
      try {
        if (!await isModelInstalled()) {
          throw StateError('대화 엔진이 아직 준비되지 않았습니다.');
        }
        final model = await _getModel(maxTokens);
        final chat = await model.createChat(
          temperature: temperature,
          topK: 40,
          topP: 0.95,
          tokenBuffer: 128,
          modelType: ModelType.gemma4,
          systemInstruction: systemInstruction,
        );
        await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
        final response = await chat.generateChatResponse();
        final text = switch (response) {
          TextResponse(:final token) => token,
          ThinkingResponse(:final content) => content,
          _ => throw const FormatException('대화 엔진이 텍스트가 아닌 응답을 반환했습니다.'),
        };
        if (text.trim().isEmpty) {
          throw const FormatException('대화 엔진 응답이 비어 있습니다.');
        }
        result.complete(text.trim());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  @override
  Future<void> dispose() async {
    cancelInstall();
    await _model?.close();
    _model = null;
  }
}
