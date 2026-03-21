/// Whether the current user and [peerUserId] have any block row between them.
class BlockRelation {
  const BlockRelation({
    required this.anyBlock,
    required this.iBlockedThem,
    required this.theyBlockedMe,
  });

  final bool anyBlock;
  final bool iBlockedThem;
  final bool theyBlockedMe;

  static const none = BlockRelation(anyBlock: false, iBlockedThem: false, theyBlockedMe: false);
}
