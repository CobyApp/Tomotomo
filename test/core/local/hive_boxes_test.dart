import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:aichat/core/local/hive_boxes.dart';

void main() {
  setUp(() => Hive.init('./.dart_tool/hive_test_1_2'));
  tearDown(() async => Hive.deleteFromDisk());

  test('openAllBoxes opens every declared box', () async {
    await openAllBoxes();
    for (final name in HiveBoxes.all) {
      expect(Hive.isBoxOpen(name), isTrue, reason: name);
    }
  });
}
