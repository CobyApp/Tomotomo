import 'dart:async';

import 'package:flutter/foundation.dart';

/// Tracks in-flight AI reply generations by room id (== character id) so a
/// reply keeps generating and is persisted even after the user leaves the chat
/// screen, and a returning [ChatViewModel] can observe/await it.
///
/// It is also a [Listenable]: leaving the room mid-generation used to produce no
/// signal at all when the reply landed — the notification is deliberately
/// suppressed while the app is in the foreground, and the chat list only
/// reloaded on tab selection or app resume. The reply was on disk and the list
/// still showed the learner's own message.
class ChatGenerationRegistry extends ChangeNotifier {
  ChatGenerationRegistry._();

  static final ChatGenerationRegistry instance = ChatGenerationRegistry._();

  final Map<String, Future<void>> _inFlight = {};

  /// The in-flight generation for [roomId], or null if none is running.
  Future<void>? inFlight(String roomId) => _inFlight[roomId];

  bool isGenerating(String roomId) => _inFlight.containsKey(roomId);

  /// Room ids currently generating a reply.
  Set<String> get generatingRooms => _inFlight.keys.toSet();

  /// Increments every time a generation finishes, so a listener can tell a
  /// completion from a start without tracking the key set itself.
  int get completions => _completions;
  int _completions = 0;

  /// Runs [task] for [roomId], deduplicating concurrent sends for the same room.
  /// The future runs to completion independent of any widget lifecycle.
  Future<void> run(String roomId, Future<void> Function() task) {
    final existing = _inFlight[roomId];
    if (existing != null) return existing;
    final future = task();
    _inFlight[roomId] = future;
    notifyListeners();
    // `.ignore()` because this derived future is bookkeeping only: a failing
    // generation's error belongs to the caller, who gets `future` itself. Left
    // unignored it counted as a second, unhandled copy of the same error.
    future
        .whenComplete(() {
          if (identical(_inFlight[roomId], future)) {
            _inFlight.remove(roomId);
            _completions++;
            notifyListeners();
          }
        })
        .ignore();
    return future;
  }

  /// The singleton outlives every widget; disposing it would break later rooms.
  @override
  void dispose() {
    assert(false, 'the generation registry singleton must not be disposed');
    super.dispose();
  }
}
