import 'dart:async';
import '../../core/ui/paper/paper_loading.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui/paper/paper_status_views.dart';
import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../locale/l10n_context.dart';

/// Single local user id (no auth).
const String _localUserId = 'local';

/// Quiet paper-card field decoration shared by every text input on this form.
InputDecoration _paperFieldDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
}) {
  final p = context.paper;
  final radius = BorderRadius.circular(PaperRadii.button);
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    filled: true,
    fillColor: p.card,
    labelStyle: TextStyle(color: p.ink, fontWeight: FontWeight.w700),
    floatingLabelStyle: TextStyle(color: p.ink, fontWeight: FontWeight.w800),
    hintStyle: TextStyle(color: p.inkSoft),
    border: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: p.cardEdge),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: p.cardEdge),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: p.coral, width: 2),
    ),
  );
}

/// Edit the local profile display name.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _displayNameController = TextEditingController();

  Profile? _profile;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<ProfileRepository>();
      final p = await repo.getProfile(_localUserId);
      if (!mounted) return;
      if (p == null) {
        setState(() {
          _profile = null;
          _loading = false;
          _error = 'missing';
        });
        return;
      }
      _displayNameController.text = p.displayName ?? '';
      setState(() {
        _profile = p;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _save() async {
    final profile = _profile;
    if (profile == null) return;
    final name = _displayNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.trRead('displayNameRequired'));
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final repo = context.read<ProfileRepository>();
      final updated = Profile(
        id: profile.id,
        displayName: name,
        // The app never displays a user avatar, so the profile is name-only.
        avatarUrl: null,
        appLanguage: profile.appLanguage,
        learningLanguage: profile.learningLanguage,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      );
      await repo.updateProfile(updated);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('profileEditSaved'))),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final Widget body;
    final List<Widget>? actions;

    if (_loading) {
      body = const PaperLoadingBody();
      actions = null;
    } else if (_profile == null) {
      body = PaperErrorBody(
        message: _error == 'missing'
            ? context.tr('profileEditLoadError')
            : (_error ?? context.tr('profileEditLoadError')),
        onRetry: () => unawaited(_load()),
        retryLabel: context.tr('retry'),
      );
      actions = null;
    } else {
      actions = [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _saving
              ? PaperLoading(size: 9)
              : PaperButton(
                  expand: false,
                  icon: Icons.check_rounded,
                  label: context.tr('save'),
                  onPressed: _save,
                ),
        ),
      ];
      body = ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          AppSpacing.pageTop,
          AppSpacing.pageH,
          AppSpacing.pageBottom,
        ),
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.coral.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(PaperRadii.card),
                border: Border.all(
                  color: p.coral.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Text(_error!, style: TextStyle(color: p.ink)),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 28),
          TextFormField(
            controller: _displayNameController,
            decoration: _paperFieldDecoration(
              context,
              labelText: context.tr('displayNameLabel'),
              hintText: context.tr('displayNameHint'),
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ],
      );
    }

    return PaperScaffold(
      title: context.tr('profileEditTitle'),
      transparentBackground: false,
      actions: actions,
      body: body,
    );
  }
}
