import 'character_record.dart';
import 'user_profile_search_result.dart';

/// Result of the combined "people / character" search dialog on the friends tab.
sealed class FriendSearchPick {}

final class FriendSearchPickUser extends FriendSearchPick {
  FriendSearchPickUser(this.profile);
  final UserProfileSearchResult profile;
}

final class FriendSearchPickCharacter extends FriendSearchPick {
  FriendSearchPickCharacter(this.record);
  final CharacterRecord record;
}
