import '../entities/character_record.dart';

abstract class CharacterRecordRepository {
  Future<List<CharacterRecord>> getMyCharacters();
  Future<CharacterRecord?> getCharacter(String id);
  Future<CharacterRecord> createCharacter(CharacterRecord character);
  Future<CharacterRecord> updateCharacter(CharacterRecord character);
  Future<void> deleteCharacter(String id);

  /// One-time seed of the packaged friends into the local store so they become
  /// ordinary, editable/deletable records. Runs its body only on first call
  /// (guarded by a persisted flag), so later deletions are not undone.
  Future<void> seedBuiltInsIfNeeded(List<CharacterRecord> builtIns);
}
