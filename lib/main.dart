import 'dart:async';
import 'dart:ui';

import 'package:background_downloader/background_downloader.dart'
    show FileDownloader, TaskNotification, PermissionType;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/l10n/app_strings.dart';
import 'core/local/hive_boxes.dart';
import 'core/locale/languages.dart';
import 'core/notifications/local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Hive.initFlutter();
  await openAllBoxes();

  setupInjection();
  await LocalNotifications.init();
  await _configureDownloadNotifications();
  await onDeviceModelManager.initialize();
  // Continue an interrupted download automatically on relaunch.
  unawaited(onDeviceModelManager.resumeIfInterrupted());

  unawaited(_initAds());

  runApp(const App());
}

/// Configures the OS notification (with progress bar) for the model download
/// group so progress shows in the iOS/Android notification shade even when the
/// download auto-starts (onboarding / relaunch), not only from Settings.
Future<void> _configureDownloadNotifications() async {
  try {
    final lang = normalizeLang(PlatformDispatcher.instance.locale.languageCode);
    String t(String k) => AppStrings.of(lang, k);
    unawaited(FileDownloader().permissions.request(PermissionType.notifications));
    FileDownloader().configureNotificationForGroup(
      'smart_downloads',
      running: TaskNotification(
        t('modelNotifRunningTitle'),
        t('modelNotifRunningBody'),
      ),
      complete: TaskNotification(
        t('modelNotifCompleteTitle'),
        t('modelNotifCompleteBody'),
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
