import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../local/hive_boxes.dart';

/// Directories under the app documents dir that hold user-picked images copied
/// out of the photo library.
const List<String> kManagedImageDirs = ['avatars', 'chat_backgrounds'];

/// Deletes files in [directories] that nothing in [referenced] points at, and
/// returns how many were removed.
///
/// Every pick copies the chosen photo under a fresh name, so replacing a friend's
/// avatar, replacing a chat background, or picking one and then backing out left
/// the previous copy on disk forever. Deleting a friend left theirs too. Those
/// files are full-resolution photos in the app documents dir, which on iOS is
/// backed up to iCloud and counts against the user's storage — in an app that
/// already stores a 2.6 GB model.
///
/// Membership is decided by path string, and callers collect those strings by
/// scanning stored values rather than by naming fields, so a new feature that
/// stores an image path cannot silently make its files collectable.
Future<int> pruneOrphanImages({
  required List<Directory> directories,
  required Set<String> referenced,
}) async {
  var removed = 0;
  for (final dir in directories) {
    if (!await dir.exists()) continue;
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      if (referenced.contains(entity.path)) continue;
      try {
        await entity.delete();
        removed++;
      } catch (e) {
        debugPrint('Could not delete orphan image ${entity.path}: $e');
      }
    }
  }
  return removed;
}

/// Every string anywhere in [value] — walking maps and lists — that starts with
/// one of [roots].
///
/// Deliberately schema-blind: it does not know which field of which record holds
/// an image path, so adding one needs no change here.
Set<String> collectReferencedPaths(Object? value, List<String> roots) {
  final found = <String>{};
  void walk(Object? v) {
    if (v is String) {
      if (roots.any(v.startsWith)) found.add(v);
    } else if (v is Map) {
      for (final e in v.values) {
        walk(e);
      }
    } else if (v is Iterable) {
      for (final e in v) {
        walk(e);
      }
    }
  }

  walk(value);
  return found;
}

/// Startup-only sweep of the managed image directories.
///
/// Must run at startup and nowhere else: a picker holds a freshly copied file
/// that is not referenced by anything until the user taps Apply, so a sweep
/// while one is open would delete the image being chosen. At startup no picker
/// can be open.
Future<void> pruneOrphanImagesAtStartup() async {
  try {
    final docs = await getApplicationDocumentsDirectory();
    final dirs = kManagedImageDirs
        .map((name) => Directory('${docs.path}/$name'))
        .toList();
    final roots = dirs.map((d) => d.path).toList();

    // If reference collection cannot run, every file looks orphaned and this
    // becomes "delete all of the user's photos". Abort instead: the caller runs
    // after openAllBoxes(), so a closed box means the call order changed.
    final open = HiveBoxes.all.where(Hive.isBoxOpen).toList();
    if (open.length != HiveBoxes.all.length) {
      debugPrint('Skipping the orphan image prune: boxes are not all open');
      return;
    }

    final referenced = <String>{};
    for (final name in open) {
      final box = Hive.box<dynamic>(name);
      for (final key in box.keys) {
        referenced.addAll(collectReferencedPaths(box.get(key), roots));
      }
    }

    final removed = await pruneOrphanImages(
      directories: dirs,
      referenced: referenced,
    );
    if (removed > 0) debugPrint('Pruned $removed orphaned image(s)');
  } catch (e) {
    // Best-effort housekeeping: never block startup.
    debugPrint('Orphan image prune failed: $e');
  }
}
