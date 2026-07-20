import 'package:aichat/data/character/characters_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('has at least one built-in friend per language', () {
    final langs = characters.map((c) => c.friendLanguage).toSet();
    expect(langs.containsAll({'ko', 'ja', 'en', 'zh'}), isTrue);
  });

  test('every built-in friend has a non-empty avatar path and unique id', () {
    final ids = <String>{};
    for (final c in characters) {
      expect(c.imagePath.isNotEmpty, isTrue, reason: '${c.id} has no image');
      expect(ids.add(c.id), isTrue, reason: 'duplicate id ${c.id}');
    }
  });
}
