import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/local/hive_boxes.dart';
import 'domain/entities/chat_message.dart';
import 'domain/entities/character.dart';
import 'domain/entities/character_record.dart';
import 'domain/entities/saved_expression.dart';
import 'store_shots/demo_content.dart';

/// Entry point used only to capture App Store / Play Store screenshots.
///
/// Not referenced by any release build — `flutter build` targets `lib/main.dart`
/// unless `-t` says otherwise — so nothing here ships.
///
/// It exists because the real launch path cannot produce a usable screenshot on
/// a simulator: chat needs the 2.6 GB on-device model, which no simulator has,
/// so every chat screen would show the "preparing" bar; a fresh install starts
/// in onboarding; and the debug banner sits over the top-right corner.
///
/// Build once, then drive each capture by writing `shot_config.json` into the
/// app's documents directory and relaunching — no rebuild per language or
/// screen:
/// ```
/// flutter build ios --simulator --debug -t lib/main_store_shots.dart
/// echo '{"lang":"ja","screen":"words"}' > "$(xcrun simctl get_app_container \
///   <dev> com.dime.tomotomo data)/Documents/shot_config.json"
/// ```
/// A plain file rather than shared_preferences: `simctl spawn … defaults write`
/// lands in the simulator's own preferences directory, not the app container, so
/// the app never saw it. See `tool/store_shots.sh`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await openAllBoxes();
  setupInjection();

  final config = await _readConfig();
  final lang = config['lang'] as String? ?? 'ko';
  final screen = config['screen'] as String? ?? 'friends';
  appLanguageCode = lang;

  // The script wipes the container between languages, so an empty store means
  // this language has not been seeded yet.
  final seeded = Hive.box(HiveBoxes.settings).get('shot_seeded_lang');
  if (seeded != lang) {
    await _seed(lang);
    await Hive.box(HiveBoxes.settings).put('shot_seeded_lang', lang);
  }

  // No notification prompt, no model download, no ad SDK: each would put
  // something over the screen that does not belong in a store listing.
  onDeviceModelManager.debugMarkReadyForScreenshots();

  runApp(
    _ShotApp(screen: screen),
  );
}

/// Reads `<documents>/shot_config.json`, or an empty map when absent.
Future<Map<String, dynamic>> _readConfig() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/shot_config.json');
    if (!await file.exists()) return const {};
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  } catch (e) {
    debugPrint('No screenshot config: $e');
    return const {};
  }
}

/// Opens the app straight onto the screen named by the config.
class _ShotApp extends StatelessWidget {
  const _ShotApp({required this.screen});

  final String screen;

  /// `chat` opens the Chats tab; the capture script taps its single row to enter
  /// the room. Pushing the route from here would mean adding a navigator
  /// callback to the production App for a screenshot-only need, and one tap is
  /// cheaper than that.
  static const _tabs = {
    'friends': 0,
    'chats': 1,
    'chat': 1,
    'words': 2,
    'settings': 3,
  };

  @override
  Widget build(BuildContext context) =>
      App(showDebugBanner: false, initialTab: _tabs[screen] ?? 0);
}

/// Fills the local stores with the demo content a listing should show.
Future<void> _seed(String lang) async {
  final demo = demoContentFor(lang);
  final now = DateTime(2026, 5, 14, 21, 12);

  await profileRepository.setOnboarded();
  final profile = await profileRepository.getProfile('local');
  if (profile != null) {
    await profileRepository.updateProfile(
      profile.copyWith(
        displayName: demo.learnerName,
        appLanguage: lang,
        learningLanguage: demo.studyLanguage,
      ),
    );
  }
  await profileRepository.setFriendLanguage(demo.studyLanguage);

  // A wallet that looks lived-in rather than freshly seeded.
  await Hive.box(HiveBoxes.points).put('balance', 480);

  // The list shows newest first, so seed in reverse to keep the intended order
  // — the conversation partner belongs at the top.
  for (final friend in demo.friends.reversed) {
    await characterRecordRepository.createCharacter(
      CharacterRecord(
        id: friend.id,
        name: friend.name,
        tagline: friend.tagline,
        speechStyle: friend.speechStyle,
        language: friend.language,
        level: friend.level,
        avatarUrl: friend.avatarAsset,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  // The conversation shown in the chat screenshot. Saved through the repository
  // so it lands in the same layout the app reads back.
  final lead = demo.friends.first;
  final character = Character.fromRecord(
    CharacterRecord(
      id: lead.id,
      name: lead.name,
      tagline: lead.tagline,
      language: demo.studyLanguage,
      level: lead.level,
      avatarUrl: lead.avatarAsset,
      createdAt: now,
      updatedAt: now,
    ),
  );
  var stamp = now.subtract(Duration(minutes: demo.conversation.length * 2));
  for (final turn in demo.conversation) {
    stamp = stamp.add(const Duration(minutes: 2));
    await chatRepository.saveMessage(
      character,
      ChatMessage(
        content: turn.text,
        role: turn.fromLearner ? 'user' : 'assistant',
        timestamp: stamp,
        lineTranslation: turn.translation,
        explanation: turn.explanation,
      ),
    );
  }

  for (final word in demo.words) {
    await savedExpressionRepository.add(
      SavedExpressionDraft(
        notebookLang: demo.studyLanguage,
        content: word.term,
        reading: word.reading,
        translation: word.meaning,
        roomId: lead.id,
      ),
    );
  }
}
