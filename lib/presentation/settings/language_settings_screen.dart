import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/supabase/app_supabase.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('languageTitle')),
        centerTitle: false,
      ),
      body: FutureBuilder<Profile?>(
        future: _loadProfile(context),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snap.data;
          if (profile == null) {
            return Center(child: Text(context.tr('loginRequired')));
          }
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  context.tr('languageSubtitle'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                ),
              ),
              ListTile(
                title: Text(context.tr('langKorean')),
                trailing: profile.appLanguage == 'ko' ? const Icon(Icons.check) : null,
                onTap: () => _set(context, 'ko', profile),
              ),
              ListTile(
                title: Text(context.tr('langJapanese')),
                trailing: profile.appLanguage == 'ja' ? const Icon(Icons.check) : null,
                onTap: () => _set(context, 'ja', profile),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<Profile?> _loadProfile(BuildContext context) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) return null;
    return context.read<ProfileRepository>().getProfile(user.id);
  }

  Future<void> _set(BuildContext context, String? code, Profile profile) async {
    if (code == null) return;
    await context.read<LocaleNotifier>().setAppLanguage(code, profile);
    if (context.mounted) Navigator.pop(context);
  }
}
