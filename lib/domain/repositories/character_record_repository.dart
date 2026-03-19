import '../entities/character_record.dart';

abstract class CharacterRecordRepository {
  Future<List<CharacterRecord>> getMyCharacters(String userId);
  Future<List<CharacterRecord>> getPublicCharacters({String? language});
  Future<CharacterRecord?> getCharacter(String id);
  Future<CharacterRecord> createCharacter(CharacterRecord character);
  Future<CharacterRecord> updateCharacter(CharacterRecord character);
  Future<void> deleteCharacter(String id, String ownerId);
  Future<void> incrementDownloadCount(String id);
}
