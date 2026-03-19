import '../entities/friend_summary.dart';

abstract class FriendsRepository {
  Future<List<FriendSummary>> listFriends();
  Future<void> addFriendById(String friendUserId);
  Future<void> removeFriend(String friendUserId);
}
