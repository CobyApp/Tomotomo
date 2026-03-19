import '../entities/friend_summary.dart';
import '../entities/user_profile_search_result.dart';

abstract class FriendsRepository {
  Future<List<FriendSummary>> listFriends();
  Future<List<UserProfileSearchResult>> searchProfilesByNickname(String query, {int limit});
  Future<void> addFriendById(String friendUserId);
  Future<void> removeFriend(String friendUserId);
}
