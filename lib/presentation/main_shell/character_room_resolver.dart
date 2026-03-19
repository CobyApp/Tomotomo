import '../../core/supabase/app_supabase.dart';
import '../../data/character/characters_data.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/chat_room_summary.dart';
import '../../domain/repositories/character_record_repository.dart';
import '../../domain/repositories/profile_repository.dart';

/// Resolves a [Character] from a [ChatRoomSummary] for opening [ChatScreen].
Future<Character?> resolveCharacterForRoom(
  ChatRoomSummary room,
  CharacterRecordRepository charRepo,
  ProfileRepository profileRepo,
) async {
  if (room.isDm) {
    final uid = AppSupabase.auth.currentUser?.id;
    if (uid == null) return null;
    final otherId = room.otherParticipantUserId(uid);
    if (otherId == null) return null;
    final p = await profileRepo.getProfile(otherId);
    if (p == null) return null;
    final name = p.displayName?.trim().isNotEmpty == true ? p.displayName! : (p.email ?? otherId);
    return Character.forDirectMessage(
      peerUserId: otherId,
      roomId: room.roomId,
      displayName: name,
      email: p.email,
      avatarUrl: p.avatarUrl,
    );
  }
  if (room.characterIdSupabase != null && room.characterIdSupabase!.isNotEmpty) {
    final r = await charRepo.getCharacter(room.characterIdSupabase!);
    if (r != null) return Character.fromRecord(r);
  }
  if (room.externalCharacterKey != null) {
    for (final c in characters) {
      if (c.id == room.externalCharacterKey) return c;
    }
  }
  return null;
}
