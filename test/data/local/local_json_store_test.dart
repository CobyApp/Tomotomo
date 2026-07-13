import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:aichat/data/local/local_json_store.dart';

void main() {
  late Box box;
  setUp(() async {
    Hive.init('./.dart_tool/hive_test_1_3');
    box = await Hive.openBox('t');
  });
  tearDown(() async => Hive.deleteFromDisk());

  test('putItem/listItems round-trips by id', () async {
    final store = LocalJsonStore(box);
    await store.putItem('a', {'id': 'a', 'name': 'x'});
    await store.putItem('b', {'id': 'b', 'name': 'y'});
    final all = store.listItems();
    expect(all.length, 2);
    expect(store.getItem('a')!['name'], 'x');
    await store.deleteItem('a');
    expect(store.getItem('a'), isNull);
  });

  test('putValue/getValue for scalar settings', () async {
    final store = LocalJsonStore(box);
    await store.putValue('lang', 'ja');
    expect(store.getValue('lang'), 'ja');
  });
}
