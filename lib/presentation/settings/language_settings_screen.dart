import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/supabase/app_supabase.dart';
import '../../core/ui/ui.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: context.tr('languageTitle'),
      subtitle: context.tr('languageSubtitle'),
      transparentBackground: false,
      body: FutureBuilder<Profile?>(
        future: _loadProfile(context),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const AppLoadingBody();
          }
          final profile = snap.data;
          if (profile == null) {
            return Center(child: Text(context.tr('loginRequired')));
          }
          final scheme = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, 16, AppSpacing.pageH, AppSpacing.pageBottom),
            children: [
              AppSettingsPanel(
                dividerIndent: 16,
                children: [
                  AppSettingsNavTile(
                    icon: Icons.translate_rounded,
                    title: context.tr('langKorean'),
                    showChevron: false,
                    trailing: profile.appLanguage == 'ko'
                        ? Icon(Icons.check_circle_rounded, color: scheme.primary, size: 24)
                        : null,
                    onTap: () => _set(context, 'ko', profile),
                  ),
                  AppSettingsNavTile(
                    icon: Icons.language_rounded,
                    title: context.tr('langJapanese'),
                    showChevron: false,
                    trailing: profile.appLanguage == 'ja'
                        ? Icon(Icons.check_circle_rounded, color: scheme.primary, size: 24)
                        : null,
                    onTap: () => _set(context, 'ja', profile),
                  ),
                ],
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
