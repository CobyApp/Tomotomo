import 'dart:async';

import 'package:background_downloader/background_downloader.dart'
    show FileDownloader, TaskNotification;
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/l10n/app_strings.dart';
import 'core/local/hive_boxes.dart';
import 'core/startup/startup_failure_app.dart';
import 'core/storage/orphan_image_pruner.dart';
import 'core/locale/languages.dart';
import 'core/notifications/local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _startApp();
}

/// Initializes everything the app needs, then runs it.
///
/// A failure here used to propagate out of `main`, so `runApp` was never reached
/// and the launch died on a blank screen with nothing said. The likeliest causes
/// — a corrupted box, a full disk — are also the ones a user cannot diagnose, and
/// the only recovery they can think of is deleting the app, which takes the
/// 2.6 GB model and every saved conversation with it.
Future<void> _startApp() async {
  try {
    // Each step runs at most once across retries: re-initializing the ad SDK or
    // the model manager because a *later* step failed would trade one problem
    // for another.
    await _once('hive', () async {
      await Hive.initFlutter();
      await openAllBoxes();
    });
    await _once('injection', () async {
      setupInjection();
      await _primeAppLanguage();
    });
    await _once('notifications', () async {
      await LocalNotifications.init();
      await _configureDownloadNotifications();
    });
    await _once('model', () async {
      await onDeviceModelManager.initialize();
      // Continue an interrupted download automatically on relaunch.
      unawaited(onDeviceModelManager.resumeIfInterrupted());
    });
    await _once('ads', () async => unawaited(_initAds()));
    // Housekeeping, not startup work: reclaims photo copies left behind by
    // replaced avatars/backgrounds, abandoned picks and deleted friends. Startup
    // is the only safe moment — see the function's docs.
    await _once('prune', () async => unawaited(pruneOrphanImagesAtStartup()));
  } on _StartupStepError catch (e, st) {
    debugPrint('Startup failed at ${e.step}: ${e.cause}\n$st');
    runApp(
      StartupFailureApp(
        onRetry: () => unawaited(_startApp()),
        detail: '${e.step}: ${e.cause}',
      ),
    );
    return;
  } catch (e, st) {
    debugPrint('Startup failed: $e\n$st');
    runApp(
      StartupFailureApp(
        onRetry: () => unawaited(_startApp()),
        detail: '$e',
      ),
    );
    return;
  }

  runApp(const App());
}

/// Startup steps that have already succeeded, so a retry does not repeat them.
final Set<String> _completedStartupSteps = <String>{};

Future<void> _once(String step, Future<void> Function() body) async {
  if (_completedStartupSteps.contains(step)) return;
  try {
    await body();
  } catch (e) {
    // Tagged with the step: a bare exception here leaves whoever has to fix it
    // guessing, since the app never got far enough to log anything else.
    throw _StartupStepError(step, e);
  }
  _completedStartupSteps.add(step);
}

/// A startup failure, carrying which step it came from.
class _StartupStepError implements Exception {
  _StartupStepError(this.step, this.cause);
  final String step;
  final Object cause;

  @override
  String toString() => 'startup step "$step" failed: $cause';
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
