import 'dart:async';

import 'package:aichat/presentation/chat/chat_generation_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Leaving a room mid-generation produced no signal anywhere: the reply
/// notification is deliberately suppressed while the app is in the foreground,
/// and the chat list only reloaded on tab selection or app resume. So the reply
/// was on disk while the row still showed the learner's own message. The
/// registry now reports starts and completions so the list can react.
void main() {
  final registry = ChatGenerationRegistry.instance;

  test('it reports the start and the completion separately', () async {
    final completer = Completer<void>();
    final events = <({bool generating, int completions})>[];
    void listener() => events.add((
      generating: registry.isGenerating('room-a'),
      completions: registry.completions,
    ));
    registry.addListener(listener);
    addTearDown(() => registry.removeListener(listener));

    final before = registry.completions;
    final run = registry.run('room-a', () => completer.future);

    expect(events.length, 1, reason: 'the start was not announced');
    expect(events.single.generating, isTrue);
    expect(events.single.completions, before,
        reason: 'a start was counted as a completion');

    completer.complete();
    await run;

    expect(events.length, 2, reason: 'the completion was not announced');
    expect(events.last.generating, isFalse);
    expect(events.last.completions, before + 1);
  });

  test('a failed generation still announces completion', () async {
    // Otherwise a room that errored would keep showing "typing…" forever.
    final before = registry.completions;
    var notified = 0;
    void listener() => notified++;
    registry.addListener(listener);
    addTearDown(() => registry.removeListener(listener));

    await registry.run('room-b', () async => throw StateError('boom'))
        .catchError((_) {});

    expect(registry.isGenerating('room-b'), isFalse);
    expect(registry.completions, before + 1);
    expect(notified, 2);
  });

  test('a duplicate send for the same room does not double-announce', () async {
    final completer = Completer<void>();
    var notified = 0;
    void listener() => notified++;
    registry.addListener(listener);
    addTearDown(() => registry.removeListener(listener));

    final a = registry.run('room-c', () => completer.future);
    final b = registry.run('room-c', () async => fail('ran twice'));
    expect(identical(a, b), isTrue);
    expect(notified, 1);

    completer.complete();
    await a;
    expect(notified, 2);
  });

  test('rooms report independently', () async {
    final one = Completer<void>();
    final two = Completer<void>();
    final a = registry.run('room-d', () => one.future);
    final b = registry.run('room-e', () => two.future);

    expect(registry.generatingRooms, containsAll(['room-d', 'room-e']));
    one.complete();
    await a;
    expect(registry.isGenerating('room-d'), isFalse);
    expect(registry.isGenerating('room-e'), isTrue,
        reason: 'one room finishing cleared another');
    two.complete();
    await b;
  });
}
