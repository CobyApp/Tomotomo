/// Row from RPC `list_blocked_users`.
class BlockedUserSummary {
  const BlockedUserSummary({
    required this.userId,
    this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String? displayName;
  final String? avatarUrl;

  String get title =>
      displayName?.trim().isNotEmpty == true ? displayName!.trim() : userId;

  factory BlockedUserSummary.fromRpcRow(Map<String, dynamic> row) {
    final id = row['blocked_id'];
    return BlockedUserSummary(
      userId: id is String ? id : id.toString(),
      displayName: row['display_name'] as String?,
      avatarUrl: row['avatar_url'] as String?,
    );
  }
}
