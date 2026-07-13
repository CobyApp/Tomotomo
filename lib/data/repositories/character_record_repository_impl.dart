import 'package:hive_ce/hive.dart';

import '../../domain/entities/character_record.dart';
import '../../domain/repositories/character_record_repository.dart';
import '../local/local_json_store.dart';

/// Local character persistence in the `characters` box. One map per character,
/// keyed by [CharacterRecord.id].
class CharacterRecordRepositoryImpl implements CharacterRecordRepository {
  CharacterRecordRepositoryImpl(Box box) : _store = LocalJsonStore(box);
  final LocalJsonStore _store;

  @override
  Future<List<CharacterRecord>> getMyCharacters() async {
    final list = _store.listItems().map(CharacterRecord.fromJson).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<CharacterRecord?> getCharacter(String id) async {
    final json = _store.getItem(id);
    if (json == null) return null;
    return CharacterRecord.fromJson(json);
  }

  @override
  Future<CharacterRecord> createCharacter(CharacterRecord character) async {
    final now = DateTime.now();
    final id = character.id.isEmpty
        ? now.microsecondsSinceEpoch.toString()
        : character.id;
    final record = CharacterRecord(
      id: id,
      ownerId: character.ownerId,
      name: character.name,
      nameSecondary: character.nameSecondary,
      avatarUrl: character.avatarUrl,
      tagline: character.tagline,
      speechStyle: character.speechStyle,
      language: character.language,
      isPublic: character.isPublic,
      clonedFromId: character.clonedFromId,
      downloadCount: character.downloadCount,
      createdAt: now,
      updatedAt: now,
    );
    await _store.putItem(id, record.toJson());
    return record;
  }

  @override
  Future<CharacterRecord> updateCharacter(CharacterRecord character) async {
    final record = CharacterRecord(
      id: character.id,
      ownerId: character.ownerId,
      name: character.name,
      nameSecondary: character.nameSecondary,
      avatarUrl: character.avatarUrl,
      tagline: character.tagline,
      speechStyle: character.speechStyle,
      language: character.language,
      isPublic: character.isPublic,
      clonedFromId: character.clonedFromId,
      downloadCount: character.downloadCount,
      createdAt: character.createdAt,
      updatedAt: DateTime.now(),
    );
    await _store.putItem(character.id, record.toJson());
    return record;
  }

  @override
  Future<void> deleteCharacter(String id) async {
    await _store.deleteItem(id);
  }
}
