import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/local/hive_boxes.dart';
import 'core/notifications/local_notifications.dart';
import 'data/character/characters_data.dart';
import 'domain/entities/character_record.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Hive.initFlutter();
  await openAllBoxes();

  setupInjection();
  await _seedBuiltInFriends();
  await LocalNotifications.init();
  await onDeviceModelManager.initialize();

  unawaited(_initAds());

  runApp(const App());
}

/// One-time seed of the packaged friends into the local store so they show up
/// as ordinary, editable/deletable records (no built-in/custom split). The
/// persona text is packed into [CharacterRecord.speechStyle] so the friend
/// keeps its personality. Guarded so later deletions stick.
Future<void> _seedBuiltInFriends() async {
  try {
    final now = DateTime.now();
    final seeds = characters.map((c) {
      final persona = [c.description.trim(), c.speechStyle.trim()]
          .where((s) => s.isNotEmpty)
          .join('\n');
      return CharacterRecord(
        id: c.id,
        name: c.displayNamePrimary,
        avatarUrl: c.imagePath.isEmpty ? null : c.imagePath,
        tagline: c.tagline.isEmpty ? null : c.tagline,
        speechStyle: persona.isEmpty ? null : persona,
        language: c.friendLanguage,
        level: c.level,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
    await characterRecordRepository.seedBuiltInsIfNeeded(seeds);
  } catch (_) {
    // Best-effort: a seeding failure must never block app startup.
  }
}

/// Initializes the AdMob SDK without blocking startup or crashing the app if
/// it fails (e.g. offline / no network on first launch).
Future<void> _initAds() async {
  try {
    await rewardedAdService.init();
  } catch (_) {}
}
