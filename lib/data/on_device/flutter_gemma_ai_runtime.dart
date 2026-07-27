import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'on_device_ai_runtime.dart';
import 'on_device_model_config.dart';
import 'resumable_model_download.dart';

final class FlutterGemmaAiRuntime implements OnDeviceAiRuntime {
  InferenceModel? _model;
  Future<void> _queue = Future<void>.value();
  String? _activeBackend;
  final _download = ResumableModelDownload();
  static const _verifiedPreference = 'gemma4_e2b_artifact_verified';

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
    // Download ourselves so the transfer can RESUME (see
    // ResumableModelDownload) instead of restarting from 0% whenever iOS drops
    // it, then hand the finished file to flutter_gemma for registration.
    final path = await _download.download(onProgress: onProgress);

    // Download done; hashing the ~2.59GB artifact takes tens of seconds.
    // Signal the UI so 100% isn't perceived as a frozen download.
    onVerifying?.call();
    if (!await _fileMatchesExpectedHash(path)) {
      await _download.clear();
      throw const FormatException('다운로드한 대화 엔진의 무결성 검증에 실패했습니다.');
    }

    // Registration only — `fromFile` records the path, it does not copy.
    await FlutterGemma.installModel(
      modelType: ModelType.gemma4,
      fileType: ModelFileType.litertlm,
    ).fromFile(path).install();

    if (!await _verifyInstalledArtifact(forceHash: false)) {
      await _deleteInstalledArtifact();
      throw const FormatException('대화 엔진 등록에 실패했습니다.');
    }
  }

  @override
  void cancelInstall() {
    unawaited(_download.cancel());
  }

  /// Streams the file through sha256 on a background isolate.
  Future<bool> _fileMatchesExpectedHash(String path) async {
    final file = File(path);
    if (!await file.exists() ||
        await file.length() != OnDeviceModelConfig.byteCount) {
      return false;
    }
    final digest = await Isolate.run(() async {
      final value = await sha256.bind(File(path).openRead()).first;
      return value.toString();
    });
    if (digest != OnDeviceModelConfig.sha256) return false;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _verifiedPreference,
      OnDeviceModelConfig.sha256,
    );
    return true;
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
    // `fromFile` only registers the path, so uninstalling does not remove the
    // file we downloaded — drop it (and its task record) ourselves.
    await _download.clear();
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
