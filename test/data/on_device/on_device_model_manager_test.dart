import 'dart:async';

import 'package:aichat/data/on_device/on_device_ai_runtime.dart';
import 'package:aichat/data/on_device/on_device_model_manager.dart';
import 'package:aichat/domain/on_device/on_device_model_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeRuntime implements OnDeviceAiRuntime {
  bool installed = false;
  bool initialized = false;
  bool cancelled = false;
  int resetCount = 0;
  bool failInstall = false;
  Completer<void>? installBlock;
  void Function(double progress)? progressCallback;

  @override
  String? get activeBackend => installed ? 'gpu' : null;

  @override
  void cancelInstall() => cancelled = true;

  @override
  Future<void> deleteModel() async => installed = false;

  @override
  Future<void> resetDownloadState() async => resetCount++;

  @override
  Future<void> dispose() async {}

  @override
  Future<String> generateText({
    required String systemInstruction,
    required String prompt,
    double temperature = 0.2,
    int maxTokens = 4096,
  }) async => '{}';

  @override
  Future<void> initialize() async => initialized = true;

  @override
  Future<void> installModel({
    required void Function(double progress) onProgress,
    void Function()? onVerifying,
  }) async {
    progressCallback = onProgress;
    onProgress(0.5);
    await installBlock?.future;
    if (failInstall) throw StateError('download failed');
    onVerifying?.call();
    installed = true;
  }

  @override
  Future<bool> isModelInstalled() async => installed;
}

void main() {
  test('initialize reports whether the model is installed', () async {
    final runtime = _FakeRuntime()..installed = true;
    final manager = OnDeviceModelManager(runtime);

    await manager.initialize();

    expect(runtime.initialized, isTrue);
    expect(manager.snapshot.phase, OnDeviceModelPhase.ready);
    expect(manager.snapshot.backend, 'gpu');
  });

  test('install publishes progress and becomes ready', () async {
    final runtime = _FakeRuntime();
    final manager = OnDeviceModelManager(runtime);
    final phases = <OnDeviceModelPhase>[];
    manager.addListener(() => phases.add(manager.snapshot.phase));

    await manager.initialize();
    await manager.install();

    expect(phases, contains(OnDeviceModelPhase.downloading));
    expect(manager.snapshot.phase, OnDeviceModelPhase.ready);
    expect(manager.snapshot.progress, 1);
  });

  test('delete returns manager to not-installed state', () async {
    final runtime = _FakeRuntime()..installed = true;
    final manager = OnDeviceModelManager(runtime);
    await manager.initialize();

    await manager.deleteModel();

    expect(runtime.installed, isFalse);
    expect(manager.snapshot.phase, OnDeviceModelPhase.notInstalled);
  });

  test('a failed install clears download state and reports the error', () async {
    final runtime = _FakeRuntime()..failInstall = true;
    final manager = OnDeviceModelManager(runtime);
    await manager.initialize();

    await manager.install();

    // The broken task must not survive: left behind it looks "live" next time
    // and the download stays stuck forever.
    expect(runtime.resetCount, 1);
    expect(manager.snapshot.phase, OnDeviceModelPhase.error);
  });

  test('retryInstall resets state and downloads again', () async {
    final runtime = _FakeRuntime()..failInstall = true;
    final manager = OnDeviceModelManager(runtime);
    await manager.initialize();
    await manager.install();
    expect(manager.snapshot.phase, OnDeviceModelPhase.error);

    runtime.failInstall = false;
    await manager.retryInstall();

    // reset on failure + reset before the retry.
    expect(runtime.resetCount, 2);
    expect(manager.snapshot.phase, OnDeviceModelPhase.ready);
    expect(runtime.installed, isTrue);
  });

  test('late progress cannot revive a cancelled download', () async {
    final runtime = _FakeRuntime()..installBlock = Completer<void>();
    final manager = OnDeviceModelManager(runtime);
    await manager.initialize();

    final install = manager.install();
    await Future<void>.delayed(Duration.zero);
    manager.cancelInstall();
    runtime.progressCallback?.call(0.9);

    expect(runtime.cancelled, isTrue);
    expect(manager.snapshot.phase, OnDeviceModelPhase.notInstalled);
    runtime.installBlock!.completeError(StateError('cancelled'));
    await install;
    expect(manager.snapshot.phase, OnDeviceModelPhase.notInstalled);
  });
}
