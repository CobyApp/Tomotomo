import 'dart:async';

import 'package:background_downloader/background_downloader.dart'
    show FileDownloader, PermissionType;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/locale/languages.dart';
import '../../core/notifications/local_notifications.dart';
import '../../domain/on_device/on_device_model_snapshot.dart';
import 'on_device_ai_runtime.dart';

class OnDeviceModelManager extends ChangeNotifier {
  OnDeviceModelManager(this._runtime);

  final OnDeviceAiRuntime _runtime;
  bool _installInFlight = false;

  /// Persisted intent: true once a download has been requested, false once the
  /// user deletes the model. Lets an interrupted download auto-resume on the
  /// next launch without re-downloading a model the user deliberately removed.
  static const _installDesiredKey = 'model_install_desired';

  Future<void> _setInstallDesired(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_installDesiredKey, value);
    } catch (_) {}
  }

  /// If a download was previously started but never finished, continue it.
  Future<void> resumeIfInterrupted() async {
    if (isReady || _installInFlight) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_installDesiredKey) ?? false) {
        await install();
      }
    } catch (_) {}
  }
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
    unawaited(_setInstallDesired(true));
    // First meaningful moment for the notification permission: the user just
    // started a multi-minute download, so "may we notify you about progress /
    // completion?" now has context (never asked at cold start).
    unawaited(_requestNotificationPermission());
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
        // Download finished; artifact integrity is being verified (slow hash).
        // Move off `downloading` so late progress updates are ignored and the
        // UI shows a finalizing indicator instead of a stuck 100% bar.
        onVerifying: () => _setSnapshot(
          const OnDeviceModelSnapshot(
            phase: OnDeviceModelPhase.finalizing,
            progress: 1,
          ),
        ),
      );
      _setSnapshot(
        OnDeviceModelSnapshot(
          phase: OnDeviceModelPhase.ready,
          progress: 1,
          backend: _runtime.activeBackend,
        ),
      );
      // Only now — download + integrity verify both done — tell the user the
      // engine is truly ready (useful when they left the app during the wait).
      unawaited(_notifyReady());
    } catch (error) {
      if (_snapshot.phase == OnDeviceModelPhase.notInstalled) return;
      // Leave no broken task behind: a failed/half-finished download would
      // otherwise be picked up as "live" next time and stay stuck forever.
      try {
        await _runtime.resetDownloadState();
      } catch (_) {}
      _setError(error);
    } finally {
      _installInFlight = false;
    }
  }

  /// User-initiated recovery: wipe every trace of the previous attempt and
  /// download again from scratch.
  Future<void> retryInstall() async {
    if (_installInFlight) return;
    try {
      await _runtime.resetDownloadState();
    } catch (_) {}
    _setSnapshot(
      const OnDeviceModelSnapshot(phase: OnDeviceModelPhase.notInstalled),
    );
    await install();
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
      await _setInstallDesired(false);
      await _runtime.deleteModel();
      _setSnapshot(
        const OnDeviceModelSnapshot(phase: OnDeviceModelPhase.notInstalled),
      );
    } catch (error) {
      _setError(error);
    }
  }

  /// Best-effort OS notification permission (download progress + "ready").
  Future<void> _requestNotificationPermission() async {
    try {
      await FileDownloader().permissions.request(PermissionType.notifications);
    } catch (_) {}
  }

  Future<void> _notifyReady() async {
    try {
      final lang = normalizeLang(
        PlatformDispatcher.instance.locale.languageCode,
      );
      await LocalNotifications.showModelReady(
        title: AppStrings.of(lang, 'modelNotifCompleteTitle'),
        body: AppStrings.of(lang, 'modelNotifCompleteBody'),
      );
    } catch (_) {}
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
