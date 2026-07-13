import '../entities/character_record.dart';

abstract class CharacterRecordRepository {
  Future<List<CharacterRecord>> getMyCharacters();
  Future<CharacterRecord?> getCharacter(String id);
  Future<CharacterRecord> createCharacter(CharacterRecord character);
  Future<CharacterRecord> updateCharacter(CharacterRecord character);
  Future<void> deleteCharacter(String id);
}
