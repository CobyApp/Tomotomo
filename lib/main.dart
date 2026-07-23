import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/local/hive_boxes.dart';
import 'core/notifications/local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Hive.initFlutter();
  await openAllBoxes();

  setupInjection();
  await LocalNotifications.init();
  await onDeviceModelManager.initialize();

  unawaited(_initAds());

  runApp(const App());
}

/// Initializes the AdMob SDK without blocking startup or crashing the app if
/// it fails (e.g. offline / no network on first launch).
Future<void> _initAds() async {
  try {
    await rewardedAdService.init();
  } catch (_) {}
}
