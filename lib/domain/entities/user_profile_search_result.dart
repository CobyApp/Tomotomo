/// Public profile row from RPC `search_profiles_by_nickname` (no email).
class UserProfileSearchResult {
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final String? statusMessage;

  const UserProfileSearchResult({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.statusMessage,
  });

  String get title =>
      displayName?.trim().isNotEmpty == true ? displayName!.trim() : userId;

  factory UserProfileSearchResult.fromRpcRow(Map<String, dynamic> row) {
    final id = row['user_id'];
    return UserProfileSearchResult(
      userId: id is String ? id : id.toString(),
      displayName: row['display_name'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      statusMessage: row['status_message'] as String?,
    );
  }
}
