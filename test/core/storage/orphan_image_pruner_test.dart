import 'dart:io';

import 'package:aichat/core/storage/orphan_image_pruner.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every photo pick copies the chosen image under a fresh name, so replacing an
/// avatar, replacing a chat background, or picking one and then backing out left
/// the previous copy in the app documents dir forever — as did deleting the
/// friend it belonged to. These are full-resolution photos, in a directory iOS
/// backs up to iCloud, in an app that already stores a 2.6 GB model.
void main() {
  late Directory root;
  late Directory avatars;
  late Directory backgrounds;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('prune_test');
    avatars = await Directory('${root.path}/avatars').create();
    backgrounds = await Directory('${root.path}/chat_backgrounds').create();
  });
  tearDown(() async => root.delete(recursive: true));

  Future<File> write(Directory dir, String name) async {
    final f = File('${dir.path}/$name');
    await f.writeAsString('x');
    return f;
  }

  test('it keeps referenced files and deletes the rest', () async {
    final kept = await write(avatars, 'avatar_1.jpg');
    final replaced = await write(avatars, 'avatar_2.jpg');
    final keptBg = await write(backgrounds, 'bg_1.jpg');
    final abandonedBg = await write(backgrounds, 'bg_2.jpg');

    final removed = await pruneOrphanImages(
      directories: [avatars, backgrounds],
      referenced: {kept.path, keptBg.path},
    );

    expect(removed, 2);
    expect(kept.existsSync(), isTrue);
    expect(keptBg.existsSync(), isTrue);
    expect(replaced.existsSync(), isFalse);
    expect(abandonedBg.existsSync(), isFalse);
  });

  test('an empty reference set means everything goes — the caller must guard',
      () async {
    // Documents the sharp edge that makes pruneOrphanImagesAtStartup abort when
    // the boxes are not all open: with no references collected, this is "delete
    // all of the user's photos".
    await write(avatars, 'avatar_1.jpg');
    final removed = await pruneOrphanImages(
      directories: [avatars, backgrounds],
      referenced: const {},
    );
    expect(removed, 1);
  });

  test('a missing directory is not an error', () async {
    final never = Directory('${root.path}/nope');
    expect(
      await pruneOrphanImages(directories: [never], referenced: const {}),
      0,
    );
  });

  test('subdirectories are left alone', () async {
    final nested = await Directory('${avatars.path}/keep').create();
    final inside = await write(nested, 'deep.jpg');

    await pruneOrphanImages(directories: [avatars], referenced: const {});

    expect(nested.existsSync(), isTrue, reason: 'a directory was deleted');
    expect(inside.existsSync(), isTrue);
  });

  group('reference collection', () {
    const roots = ['/docs/avatars', '/docs/chat_backgrounds'];

    test('it finds paths nested in maps and lists', () {
      final stored = {
        'id': 'c1',
        'image_path': '/docs/avatars/a.jpg',
        'history': [
          {'bg': '/docs/chat_backgrounds/b.jpg'},
          {'bg': 'assets/images/preset.png'},
        ],
        'name': 'Sam',
      };
      expect(collectReferencedPaths(stored, roots), {
        '/docs/avatars/a.jpg',
        '/docs/chat_backgrounds/b.jpg',
      });
    });

    test('it is schema-blind, so a new field needs no change here', () {
      // The whole point: nobody has to remember to register a field.
      expect(
        collectReferencedPaths({
          'some_future_field': '/docs/avatars/new.jpg',
        }, roots),
        {'/docs/avatars/new.jpg'},
      );
    });

    test('unrelated strings are not collected', () {
      expect(
        collectReferencedPaths({
          'asset': 'assets/characters/yuki.png',
          'remote': 'https://example.com/a.jpg',
          'other': '/docs/models/gemma.task',
          'empty': '',
        }, roots),
        isEmpty,
      );
    });

    test('null and scalars are handled', () {
      expect(collectReferencedPaths(null, roots), isEmpty);
      expect(collectReferencedPaths(42, roots), isEmpty);
    });
  });
}
