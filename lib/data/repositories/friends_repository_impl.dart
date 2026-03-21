import '../../core/supabase/app_supabase.dart';
import '../../domain/entities/block_relation.dart';
import '../../domain/entities/blocked_user_summary.dart';
import '../../domain/entities/friend_summary.dart';
import '../../domain/entities/user_profile_search_result.dart';
import '../../domain/repositories/friends_repository.dart';

class FriendsRepositoryImpl implements FriendsRepository {
  @override
  Future<List<FriendSummary>> listFriends() async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return [];
    final res = await AppSupabase.client.rpc('list_my_friends');
    if (res == null) return [];
    final list = res as List<dynamic>;
    return list
        .map((e) => FriendSummary.fromRpcRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<UserProfileSearchResult>> searchProfilesByNickname(String query, {int limit = 20}) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return [];
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];
    final res = await AppSupabase.client.rpc(
      'search_profiles_by_nickname',
      params: {
        'search_query': trimmed,
        'result_limit': limit,
      },
    );
    if (res == null) return [];
    final list = res as List<dynamic>;
    return list
        .map((e) => UserProfileSearchResult.fromRpcRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> addFriendById(String friendUserId) async {
    await AppSupabase.client.rpc('add_friend', params: {'target_id': friendUserId});
  }

  @override
  Future<void> removeFriend(String friendUserId) async {
    await AppSupabase.client.rpc('remove_friend', params: {'target_id': friendUserId});
  }

  @override
  Future<bool> isOutgoingFriend(String friendUserId) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return false;
    final row = await AppSupabase.client
        .from('friends')
        .select('friend_id')
        .eq('user_id', user.id)
        .eq('friend_id', friendUserId)
        .maybeSingle();
    return row != null;
  }

  @override
  Future<BlockRelation> blockRelationWith(String peerUserId) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return BlockRelation.none;
    final me = user.id;
    final iBlocked = await AppSupabase.client
        .from('user_blocks')
        .select('blocker_id')
        .eq('blocker_id', me)
        .eq('blocked_id', peerUserId)
        .maybeSingle();
    if (iBlocked != null) {
      return const BlockRelation(anyBlock: true, iBlockedThem: true, theyBlockedMe: false);
    }
    final theyBlocked = await AppSupabase.client
        .from('user_blocks')
        .select('blocker_id')
        .eq('blocker_id', peerUserId)
        .eq('blocked_id', me)
        .maybeSingle();
    if (theyBlocked != null) {
      return const BlockRelation(anyBlock: true, iBlockedThem: false, theyBlockedMe: true);
    }
    return BlockRelation.none;
  }

  @override
  Future<List<BlockedUserSummary>> listBlockedUsers() async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return [];
    final raw = await AppSupabase.client.rpc('list_blocked_users');
    if (raw == null) return [];
    final list = raw as List<dynamic>;
    return list.map((e) => BlockedUserSummary.fromRpcRow(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<void> blockUser(String targetUserId) async {
    await AppSupabase.client.rpc('block_user', params: {'target_id': targetUserId});
  }

  @override
  Future<void> unblockUser(String targetUserId) async {
    await AppSupabase.client.rpc('unblock_user', params: {'target_id': targetUserId});
  }
}
