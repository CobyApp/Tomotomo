import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around local notifications, used to tell the user a friend's
/// reply finished while the app was in the background. Best-effort: every call
/// is guarded so a notification failure never affects chat.
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

  /// Shows a "your friend replied" notification.
  static Future<void> showChatReply({
    required String title,
    required String body,
  }) async {
    try {
      await init();
      const details = NotificationDetails(
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'chat_replies',
          'Chat replies',
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
