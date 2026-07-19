import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:aichat/data/chat_background/chat_background.dart';
import 'package:aichat/data/chat_background/chat_background_store.dart';

void main() {
  late Box box;
  late ChatBackgroundStore store;

  setUp(() async {
    Hive.init('./.dart_tool/hive_test_chat_bg');
    box = await Hive.openBox('settings');
    store = ChatBackgroundStore(box);
  });
  tearDown(() async => Hive.deleteFromDisk());

  test('get returns the default background when nothing is saved', () {
    final bg = store.get('char-1');
    expect(bg, const ChatBackground.defaultBg());
    expect(bg.presetId, 'paper');
  });

  test('set then get round-trips a background for a room', () async {
    await store.set(
      'char-1',
      const ChatBackground(presetId: 'mint', intensity: 0.8),
    );
    final bg = store.get('char-1');
    expect(bg.presetId, 'mint');
    expect(bg.intensity, 0.8);
  });

  test('backgrounds are scoped per room', () async {
    await store.set(
      'char-1',
      const ChatBackground(presetId: 'blush', intensity: 0.3),
    );
    await store.set(
      'char-2',
      const ChatBackground(presetId: 'sky', intensity: 0.9),
    );

    expect(store.get('char-1').presetId, 'blush');
    expect(store.get('char-2').presetId, 'sky');
    // A room that was never set still returns the default.
    expect(store.get('char-3'), const ChatBackground.defaultBg());
  });

  test('fromJson clamps out-of-range intensity', () {
    final bg = ChatBackground.fromJson({'presetId': 'peach', 'intensity': 5.0});
    expect(bg.intensity, 1.0);
    expect(bg.presetId, 'peach');
  });
}
