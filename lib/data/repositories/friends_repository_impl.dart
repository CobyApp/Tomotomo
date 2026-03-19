import '../../core/supabase/app_supabase.dart';
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
}
