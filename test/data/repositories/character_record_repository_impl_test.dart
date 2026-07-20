import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:aichat/data/repositories/character_record_repository_impl.dart';
import 'package:aichat/domain/entities/character_record.dart';

void main() {
  late Box box;
  late CharacterRecordRepositoryImpl repo;

  setUp(() async {
    Hive.init('./.dart_tool/hive_test_char');
    box = await Hive.openBox('characters');
    repo = CharacterRecordRepositoryImpl(box);
  });
  tearDown(() async => Hive.deleteFromDisk());

  test('create generates an id, then list/get/delete round-trip', () async {
    final draft = CharacterRecord.draft(
      name: 'さくら',
      nameSecondary: '사쿠라',
      language: 'ja',
    );
    final created = await repo.createCharacter(draft);
    expect(created.id, isNotEmpty);
    expect(created.name, 'さくら');

    final all = await repo.getMyCharacters();
    expect(all.length, 1);
    expect(all.first.id, created.id);

    final fetched = await repo.getCharacter(created.id);
    expect(fetched, isNotNull);
    expect(fetched!.nameSecondary, '사쿠라');

    await repo.deleteCharacter(created.id);
    expect(await repo.getCharacter(created.id), isNull);
    expect((await repo.getMyCharacters()).isEmpty, isTrue);
  });

  test('create persists the speaking level', () async {
    final created = await repo.createCharacter(
      CharacterRecord.draft(name: 'Riku', language: 'ja', level: 'business'),
    );
    expect(created.level, 'business');
    final fetched = await repo.getCharacter(created.id);
    expect(fetched!.level, 'business');
  });

  test('update preserves the speaking level', () async {
    final created = await repo.createCharacter(
      CharacterRecord.draft(name: 'Riku', level: 'beginner'),
    );
    final updated = await repo.updateCharacter(
      CharacterRecord(
        id: created.id,
        name: 'Riku',
        level: 'advanced',
        createdAt: created.createdAt,
        updatedAt: created.updatedAt,
      ),
    );
    expect(updated.level, 'advanced');
    final fetched = await repo.getCharacter(created.id);
    expect(fetched!.level, 'advanced');
  });

  test('update preserves createdAt and rewrites fields', () async {
    final created = await repo.createCharacter(
      CharacterRecord.draft(name: 'first'),
    );
    final updated = await repo.updateCharacter(
      CharacterRecord(
        id: created.id,
        name: 'second',
        createdAt: created.createdAt,
        updatedAt: created.updatedAt,
      ),
    );
    expect(updated.name, 'second');
    expect(updated.createdAt, created.createdAt);
    final fetched = await repo.getCharacter(created.id);
    expect(fetched!.name, 'second');
  });
}
