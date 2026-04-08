import '../entities/character_record.dart';

abstract class CharacterRecordRepository {
  Future<List<CharacterRecord>> getMyCharacters(String userId);
  Future<List<CharacterRecord>> getPublicCharacters({String? language});
  Future<CharacterRecord?> getCharacter(String id);

  /// My character row forked from [sourceCharacterId], if any (one per source per user).
  Future<CharacterRecord?> getMyCloneOfSource(String sourceCharacterId, String ownerId);

  /// Characters the user may chat with: own + public, name matches [query] (min 2 chars).
  Future<List<CharacterRecord>> searchAccessibleCharacters(String query, {int limit});

  Future<CharacterRecord> createCharacter(CharacterRecord character);
  Future<CharacterRecord> updateCharacter(CharacterRecord character);
  Future<void> deleteCharacter(String id, String ownerId);
  Future<void> incrementDownloadCount(String id);
}
