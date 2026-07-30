import 'package:hive_ce/hive.dart';

import 'chat_background.dart';

/// Local per-room chat background persistence in the `settings` box.
///
/// Each room's background is stored under `chat_bg/<characterId>` so every
/// chat room can have its own selection. Missing entries fall back to the
/// neutral default. Follows the same box-in-constructor pattern as the other
/// local stores (e.g. `LocalPointsRepositoryImpl`).
class ChatBackgroundStore {
  ChatBackgroundStore(this._box);
  final Box _box;

  String _key(String characterId) => 'chat_bg/$characterId';

  /// Returns this room's saved background, or [ChatBackground.defaultBg] when
  /// nothing has been saved yet.
  ChatBackground get(String characterId) {
    final v = _box.get(_key(characterId));
    if (v is! Map) return const ChatBackground.defaultBg();
    return ChatBackground.fromJson(Map<String, dynamic>.from(v));
  }

  /// Persists [bg] for this room.
  Future<void> set(String characterId, ChatBackground bg) =>
      _box.put(_key(characterId), bg.toJson());

  /// Drops this room's background. Called when a friend is deleted, whose entry
  /// otherwise stayed in the box forever — and kept its image file alive, since
  /// the orphan-image sweep treats any stored path as a live reference.
  Future<void> remove(String characterId) => _box.delete(_key(characterId));
}
