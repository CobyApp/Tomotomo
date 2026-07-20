import 'package:aichat/domain/entities/character_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips en/zh language', () {
    final r = CharacterRecord.fromJson({
      'id': '1',
      'name': 'A',
      'language': 'zh',
      'level': 'intermediate',
      'created_at': '2026-01-01T00:00:00.000',
      'updated_at': '2026-01-01T00:00:00.000',
    });
    expect(r.language, 'zh');
    expect(r.toJson()['language'], 'zh');
    expect(CharacterRecord.draft(name: 'B', language: 'en').language, 'en');
  });
}
