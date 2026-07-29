import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../di/injection.dart';
import '../l10n/app_strings.dart';
import '../locale/languages.dart';

/// Thin wrapper around local notifications, used to tell the user a friend's
/// reply finished while the app was in the background. Best-effort: every call
/// is guarded so a notification failure never affects chat.
/// Android channel names appear in the OS notification settings, so they are
/// localized like any other user-facing label. Note Android caches a channel's
/// name at creation time, so an existing install keeps the name it was created
/// with even after the user switches language.
String _channelName(String key) =>
    AppStrings.of(normalizeLang(appLanguageCode), key);

abstract final class LocalNotifications {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _permissionRequested = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        settings: const InitializationSettings(iOS: ios, android: android),
      );
      _initialized = true;
    } catch (_) {}
  }

  /// Requests notification permission once per app run (safe to call often).
  static Future<void> ensurePermission() async {
    if (_permissionRequested) return;
    _permissionRequested = true;
    try {
      await init();
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  /// Shows a "chat engine is ready" notification, sent once the download AND
  /// the post-download integrity verify have both finished.
  static Future<void> showModelReady({
    required String title,
    required String body,
  }) async {
    try {
      await ensurePermission();
      final details = NotificationDetails(
        iOS: const DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'model_ready',
          _channelName('notifChannelModelReady'),
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      await _plugin.show(
        id: 1002,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (_) {}
  }

  /// Shows a "your friend replied" notification.
  static Future<void> showChatReply({
    required String title,
    required String body,
  }) async {
    try {
      await init();
      final details = NotificationDetails(
        iOS: const DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'chat_replies',
          _channelName('notifChannelChatReplies'),
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      await _plugin.show(
        id: 1001,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (_) {}
  }
}
