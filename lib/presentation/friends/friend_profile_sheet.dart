import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/friend_summary.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../locale/l10n_context.dart';

/// LINE / Kakao-style profile popup for a friend.
Future<void> showFriendProfileSheet(
  BuildContext context, {
  required FriendSummary friend,
  required Future<void> Function() onOpenChat,
  required Future<void> Function() onRemoveFriend,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _FriendProfileSheet(
      friend: friend,
      onOpenChat: onOpenChat,
      onRemoveFriend: onRemoveFriend,
    ),
  );
}

class _FriendProfileSheet extends StatefulWidget {
  const _FriendProfileSheet({
    required this.friend,
    required this.onOpenChat,
    required this.onRemoveFriend,
  });

  final FriendSummary friend;
  final Future<void> Function() onOpenChat;
  final Future<void> Function() onRemoveFriend;

  @override
  State<_FriendProfileSheet> createState() => _FriendProfileSheetState();
}

class _FriendProfileSheetState extends State<_FriendProfileSheet> {
  Profile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final p = await context.read<ProfileRepository>().getProfile(widget.friend.friendId);
      if (!mounted) return;
      setState(() {
        _profile = p;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String get _displayName {
    final p = _profile;
    if (p?.displayName?.trim().isNotEmpty == true) return p!.displayName!.trim();
    return widget.friend.title;
  }

  String? get _avatarUrl {
    final u = _profile?.avatarUrl?.trim();
    if (u != null && u.isNotEmpty) return u;
    final f = widget.friend.avatarUrl?.trim();
    if (f != null && f.isNotEmpty) return f;
    return null;
  }

  String? get _email {
    final e = _profile?.email?.trim();
    if (e != null && e.isNotEmpty) return e;
    final fe = widget.friend.email?.trim();
    if (fe != null && fe.isNotEmpty) return fe;
    return null;
  }

  String get _statusMessage {
    final s = _profile?.statusMessage?.trim();
    if (s != null && s.isNotEmpty) return s;
    final fs = widget.friend.statusMessage?.trim();
    if (fs != null && fs.isNotEmpty) return fs;
    return '';
  }

  String _learningLine(BuildContext context) {
    final code = _profile?.learningLanguage ?? 'ja';
    if (code == 'ko') {
      return context.tr('friendsProfileLearningLine', params: {'lang': context.tr('langKo')});
    }
    return context.tr('friendsProfileLearningLine', params: {'lang': context.tr('langJa')});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final h = MediaQuery.sizeOf(context).height;
    final sheetH = h * 0.78;

    return Padding(
      padding: EdgeInsets.only(top: h * 0.06),
      child: SizedBox(
        height: sheetH,
        child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(22, 20, 22, 20 + bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: _Avatar(url: _avatarUrl, name: _displayName, radius: 52),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _displayName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                      if (_loading) ...[
                        const SizedBox(height: 24),
                        Center(child: CircularProgressIndicator(color: scheme.primary, strokeWidth: 2)),
                      ] else if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.error, fontSize: 13),
                        ),
                      ],
                      if (_email != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _email!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, size: 18, color: scheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.tr('profileStatusMessageLabel'),
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _statusMessage.isEmpty ? context.tr('friendsSheetStatusEmpty') : _statusMessage,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      height: 1.45,
                                      color: _statusMessage.isEmpty ? scheme.onSurfaceVariant : scheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_profile != null && !_loading) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.school_outlined, size: 16, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _learningLine(context),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await widget.onOpenChat();
                        },
                        icon: const Icon(Icons.chat_rounded, size: 22),
                        label: Text(context.tr('friendsSheetOpenChat')),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await widget.onRemoveFriend();
                        },
                        icon: Icon(Icons.person_remove_outlined, color: scheme.error),
                        label: Text(context.tr('friendsSearchRemoveFriend')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: scheme.error.withValues(alpha: 0.45)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name, required this.radius});

  final String? url;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final u = url?.trim();
    if (u != null && u.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: scheme.primaryContainer,
        foregroundImage: NetworkImage(u),
      );
    }
    final initial = name.trim().isNotEmpty ? name.trim().characters.first : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.85,
          fontWeight: FontWeight.w700,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
