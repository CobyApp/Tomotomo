import 'dart:async';

/// Tracks in-flight AI reply generations by room id (== character id) so a
/// reply keeps generating and is persisted even after the user leaves the chat
/// screen, and a returning [ChatViewModel] can observe/await it.
class ChatGenerationRegistry {
  ChatGenerationRegistry._();

  static final ChatGenerationRegistry instance = ChatGenerationRegistry._();

  final Map<String, Future<void>> _inFlight = {};

  /// The in-flight generation for [roomId], or null if none is running.
  Future<void>? inFlight(String roomId) => _inFlight[roomId];

  bool isGenerating(String roomId) => _inFlight.containsKey(roomId);

  /// Runs [task] for [roomId], deduplicating concurrent sends for the same room.
  /// The future runs to completion independent of any widget lifecycle.
  Future<void> run(String roomId, Future<void> Function() task) {
    final existing = _inFlight[roomId];
    if (existing != null) return existing;
    final future = task();
    _inFlight[roomId] = future;
    future.whenComplete(() {
      if (identical(_inFlight[roomId], future)) _inFlight.remove(roomId);
    });
    return future;
  }
}
