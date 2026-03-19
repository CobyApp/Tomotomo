/// Friend row joined with profile (from RPC `list_my_friends`).
class FriendSummary {
  final String friendId;
  final String? displayName;
  final String? email;

  const FriendSummary({
    required this.friendId,
    this.displayName,
    this.email,
  });

  String get title => displayName?.trim().isNotEmpty == true ? displayName! : (email ?? friendId);

  factory FriendSummary.fromRpcRow(Map<String, dynamic> row) {
    final id = row['friend_id'];
    return FriendSummary(
      friendId: id is String ? id : id.toString(),
      displayName: row['display_name'] as String?,
      email: row['email'] as String?,
    );
  }
}
