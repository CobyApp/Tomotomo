import '../entities/block_relation.dart';
import '../entities/blocked_user_summary.dart';
import '../entities/friend_summary.dart';
import '../entities/user_profile_search_result.dart';

abstract class FriendsRepository {
  Future<List<FriendSummary>> listFriends();
  Future<List<UserProfileSearchResult>> searchProfilesByNickname(String query, {int limit});
  Future<void> addFriendById(String friendUserId);
  Future<void> removeFriend(String friendUserId);

  /// True if the current user has a `friends` row toward [friendUserId] (outgoing).
  Future<bool> isOutgoingFriend(String friendUserId);

  /// Block state between me and [peerUserId] (either direction).
  Future<BlockRelation> blockRelationWith(String peerUserId);

  Future<List<BlockedUserSummary>> listBlockedUsers();
  Future<void> blockUser(String targetUserId);
  Future<void> unblockUser(String targetUserId);
}
