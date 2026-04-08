import '../../domain/entities/character_record.dart';
import '../../domain/repositories/character_record_repository.dart';
import '../../core/supabase/app_supabase.dart';

class CharacterRecordRepositoryImpl implements CharacterRecordRepository {
  @override
  Future<List<CharacterRecord>> getMyCharacters(String userId) async {
    final res = await AppSupabase.client
        .from('characters')
        .select('*')
        .eq('owner_id', userId)
        .order('updated_at', ascending: false);
    return (res as List<dynamic>).map((e) => CharacterRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<CharacterRecord>> getPublicCharacters({String? language}) async {
    var query = AppSupabase.client.from('characters').select('*').eq('is_public', true);
    if (language != null && language.isNotEmpty) {
      query = query.eq('language', language);
    }
    final res = await query.order('download_count', ascending: false);
    return (res as List<dynamic>).map((e) => CharacterRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<CharacterRecord>> searchAccessibleCharacters(String query, {int limit = 20}) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return [];
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];
    final res = await AppSupabase.client.rpc(
      'search_accessible_characters',
      params: {
        'search_query': trimmed,
        'result_limit': limit,
      },
    );
    if (res == null) return [];
    final list = res as List<dynamic>;
    return list.map((e) => CharacterRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<CharacterRecord?> getCharacter(String id) async {
    final res = await AppSupabase.client
        .from('characters')
        .select('*')
        .eq('id', id)
        .maybeSingle();
    if (res == null) return null;
    return CharacterRecord.fromJson(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<CharacterRecord> createCharacter(CharacterRecord character) async {
    final payload = character.toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at')
      ..['updated_at'] = DateTime.now().toIso8601String();
    final res = await AppSupabase.client.from('characters').insert(payload).select('*').single();
    return CharacterRecord.fromJson(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<CharacterRecord> updateCharacter(CharacterRecord character) async {
    final payload = {
      'name': character.name,
      'name_secondary': character.nameSecondary,
      'avatar_url': character.avatarUrl,
      'speech_style': character.speechStyle,
      'language': character.language,
      'is_public': character.isPublic,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await AppSupabase.client
        .from('characters')
        .update(payload)
        .eq('id', character.id)
        .eq('owner_id', character.ownerId);
    final updated = await getCharacter(character.id);
    if (updated == null) throw Exception('Failed to update character');
    return updated;
  }

  @override
  Future<void> deleteCharacter(String id, String ownerId) async {
    await AppSupabase.client
        .from('characters')
        .delete()
        .eq('id', id)
        .eq('owner_id', ownerId);
  }

  @override
  Future<void> incrementDownloadCount(String id) async {
    await AppSupabase.client.rpc(
      'increment_public_character_download_count',
      params: {'target_id': id},
    );
  }
}
