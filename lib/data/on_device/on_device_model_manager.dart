import 'package:flutter/foundation.dart';

import '../../domain/on_device/on_device_model_snapshot.dart';
import 'on_device_ai_runtime.dart';

class OnDeviceModelManager extends ChangeNotifier {
  OnDeviceModelManager(this._runtime);

  final OnDeviceAiRuntime _runtime;
  bool _installInFlight = false;
  OnDeviceModelSnapshot _snapshot = const OnDeviceModelSnapshot(
    phase: OnDeviceModelPhase.checking,
  );

  OnDeviceModelSnapshot get snapshot => _snapshot;
  bool get isReady => _snapshot.isReady;

  Future<void> initialize() async {
    try {
      await _runtime.initialize();
      final installed = await _runtime.isModelInstalled();
      _setSnapshot(
        OnDeviceModelSnapshot(
          phase: installed
              ? OnDeviceModelPhase.ready
              : OnDeviceModelPhase.notInstalled,
          progress: installed ? 1 : 0,
          backend: _runtime.activeBackend,
        ),
      );
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> install() async {
    if (_installInFlight) return;
    _installInFlight = true;
    _setSnapshot(
      const OnDeviceModelSnapshot(phase: OnDeviceModelPhase.downloading),
    );
    try {
      await _runtime.installModel(
        onProgress: (progress) {
          if (_snapshot.phase != OnDeviceModelPhase.downloading) return;
          _setSnapshot(
            OnDeviceModelSnapshot(
              phase: OnDeviceModelPhase.downloading,
              progress: progress.clamp(0, 1),
            ),
          );
        },
      );
      _setSnapshot(
        OnDeviceModelSnapshot(
          phase: OnDeviceModelPhase.ready,
          progress: 1,
          backend: _runtime.activeBackend,
        ),
      );
    } catch (error) {
      if (_snapshot.phase == OnDeviceModelPhase.notInstalled) return;
      _setError(error);
    } finally {
      _installInFlight = false;
    }
  }

  void cancelInstall() {
    if (_snapshot.phase != OnDeviceModelPhase.downloading) return;
    _runtime.cancelInstall();
    _setSnapshot(
      const OnDeviceModelSnapshot(phase: OnDeviceModelPhase.notInstalled),
    );
  }

  Future<void> deleteModel() async {
    try {
      await _runtime.deleteModel();
      _setSnapshot(
        const OnDeviceModelSnapshot(phase: OnDeviceModelPhase.notInstalled),
      );
    } catch (error) {
      _setError(error);
    }
  }

  void _setError(Object error) {
    _setSnapshot(
      OnDeviceModelSnapshot(
        phase: OnDeviceModelPhase.error,
        errorMessage: error.toString(),
      ),
    );
  }

  void _setSnapshot(OnDeviceModelSnapshot value) {
    _snapshot = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _runtime.dispose();
    super.dispose();
  }
}
