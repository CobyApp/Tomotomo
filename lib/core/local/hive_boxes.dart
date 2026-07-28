import 'package:hive_ce_flutter/hive_flutter.dart';

/// Central registry of Hive box names + one-shot opener. All app data lives here.
class HiveBoxes {
  static const characters = 'characters';
  static const chats = 'chats';
  static const wordbook = 'wordbook';
  static const points = 'points';
  static const settings = 'settings';

  static const List<String> all = [characters, chats, wordbook, points, settings];
}

/// Opens every box as an untyped `Box` of JSON-serializable values.
Future<void> openAllBoxes() async {
  for (final name in HiveBoxes.all) {
    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox<dynamic>(name);
    }
  }

  // Seed the starting points balance the first time the wallet is opened.
  final pts = Hive.box(HiveBoxes.points);
  if (pts.get('balance') == null) await pts.put('balance', 200);
}
