import 'dart:async';

import 'package:background_downloader/background_downloader.dart'
    show FileDownloader, TaskNotification;
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/l10n/app_strings.dart';
import 'core/local/hive_boxes.dart';
import 'core/locale/languages.dart';
import 'core/notifications/local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await openAllBoxes();

  setupInjection();
  await _primeAppLanguage();
  await LocalNotifications.init();
  await _configureDownloadNotifications();
  await onDeviceModelManager.initialize();
  // Continue an interrupted download automatically on relaunch.
  unawaited(onDeviceModelManager.resumeIfInterrupted());

  unawaited(_initAds());

  runApp(const App());
}

/// Loads the saved UI language into [appLanguageCode] before anything that has
/// to localize without a BuildContext runs.
///
/// `LocaleNotifier` reads the same value, but only once the widget tree is up —
/// too late for the download notification, which is configured here at startup.
/// Reading the device locale instead (what this used to do) showed the
/// notification in a language the user never picked, and fell all the way back
/// to Korean on any unsupported device locale.
Future<void> _primeAppLanguage() async {
  try {
    final profile = await profileRepository.getProfile('local');
    final code = profile?.appLanguage;
    if (code != null && kSupportedLanguages.contains(code)) {
      appLanguageCode = code;
    }
  } catch (_) {
    // Keep the default; a mislocalized notification must not block startup.
  }
}

/// Configures the OS notification (with progress bar) for the model download
/// group so progress shows in the iOS/Android notification shade even when the
/// download auto-starts (onboarding / relaunch), not only from Settings.
Future<void> _configureDownloadNotifications() async {
  try {
    final lang = normalizeLang(appLanguageCode);
    String t(String k) => AppStrings.of(lang, k);
    // NOTE: the notification PERMISSION is requested when a download actually
    // starts (OnDeviceModelManager.install) — never at cold start with no
    // context. This only configures what the notification will say.
    FileDownloader().configureNotificationForGroup(
      'smart_downloads',
      running: TaskNotification(
        t('modelNotifRunningTitle'),
        t('modelNotifRunningBody'),
      ),
      // The task "complete" fires when the DOWNLOAD finishes, but the engine
      // still needs a ~tens-of-seconds integrity verify. Say "finalizing" here;
      // the real "ready" alert is sent from OnDeviceModelManager after verify.
      complete: TaskNotification(
        t('modelNotifFinalizingTitle'),
        t('modelNotifFinalizingBody'),
      ),
      error: TaskNotification(
        t('modelNotifErrorTitle'),
        t('modelNotifErrorBody'),
      ),
      progressBar: true,
    );
  } catch (_) {
    // Best-effort: notifications must never block startup.
  }
}

/// Initializes the AdMob SDK without blocking startup or crashing the app if
/// it fails (e.g. offline / no network on first launch).
Future<void> _initAds() async {
  try {
    await rewardedAdService.init();
  } catch (_) {}
}
