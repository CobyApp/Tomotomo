/// Friend row joined with profile (from RPC `list_my_friends`).
class FriendSummary {
  final String friendId;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final String? statusMessage;

  const FriendSummary({
    required this.friendId,
    this.displayName,
    this.email,
    this.avatarUrl,
    this.statusMessage,
  });

  String get title => displayName?.trim().isNotEmpty == true ? displayName! : (email ?? friendId);

  String get subtitleLine {
    final s = statusMessage?.trim();
    if (s != null && s.isNotEmpty) return s;
    return email ?? friendId;
  }

  factory FriendSummary.fromRpcRow(Map<String, dynamic> row) {
    final id = row['friend_id'];
    return FriendSummary(
      friendId: id is String ? id : id.toString(),
      displayName: row['display_name'] as String?,
      email: row['email'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      statusMessage: row['status_message'] as String?,
    );
  }
}
