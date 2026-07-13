import 'package:hive_ce/hive.dart';

/// Typed helpers over one Hive [Box]. Item maps are stored under their own key;
/// [listItems] returns every map value in the box (skips scalar settings keys).
class LocalJsonStore {
  LocalJsonStore(this._box);
  final Box _box;

  Future<void> putItem(String id, Map<String, dynamic> json) =>
      _box.put(id, Map<String, dynamic>.from(json));

  Map<String, dynamic>? getItem(String id) {
    final v = _box.get(id);
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  List<Map<String, dynamic>> listItems() {
    return _box.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> deleteItem(String id) => _box.delete(id);

  Future<void> putValue(String key, Object? value) => _box.put(key, value);
  Object? getValue(String key) => _box.get(key);
}
