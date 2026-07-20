import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/app_settings_tile.dart';
import '../../core/ui/paper/paper_status_views.dart';
import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';

/// Single local user id (no auth).
const String _localUserId = 'local';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PaperScaffold(
      title: context.tr('languageTitle'),
      transparentBackground: false,
      body: FutureBuilder<Profile?>(
        future: _loadProfile(context),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const PaperLoadingBody();
          }
          final profile = snap.data;
          if (profile == null) {
            return Center(
              child: Text(
                context.tr('profileEditLoadError'),
                style: TextStyle(color: context.paper.inkSoft),
              ),
            );
          }
          final p = context.paper;
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, AppSpacing.pageTop, AppSpacing.pageH, AppSpacing.pageBottom),
            children: [
              AppSettingsPanel(
                dividerIndent: 16,
                children: [
                  AppSettingsNavTile(
                    icon: Icons.translate_rounded,
                    title: context.tr('langKorean'),
                    showChevron: false,
                    trailing: profile.appLanguage == 'ko'
                        ? Icon(Icons.check_circle_rounded, color: p.coral, size: 24)
                        : null,
                    onTap: () => _set(context, 'ko', profile),
                  ),
                  AppSettingsNavTile(
                    icon: Icons.language_rounded,
                    title: context.tr('langJapanese'),
                    showChevron: false,
                    trailing: profile.appLanguage == 'ja'
                        ? Icon(Icons.check_circle_rounded, color: p.coral, size: 24)
                        : null,
                    onTap: () => _set(context, 'ja', profile),
                  ),
                  AppSettingsNavTile(
                    icon: Icons.language_rounded,
                    title: context.tr('langEnglish'),
                    showChevron: false,
                    trailing: profile.appLanguage == 'en'
                        ? Icon(Icons.check_circle_rounded, color: p.coral, size: 24)
                        : null,
                    onTap: () => _set(context, 'en', profile),
                  ),
                  AppSettingsNavTile(
                    icon: Icons.language_rounded,
                    title: context.tr('langChinese'),
                    showChevron: false,
                    trailing: profile.appLanguage == 'zh'
                        ? Icon(Icons.check_circle_rounded, color: p.coral, size: 24)
                        : null,
                    onTap: () => _set(context, 'zh', profile),
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
    return context.read<ProfileRepository>().getProfile(_localUserId);
  }

  Future<void> _set(BuildContext context, String? code, Profile profile) async {
    if (code == null) return;
    await context.read<LocaleNotifier>().setAppLanguage(code, profile);
    if (context.mounted) Navigator.pop(context);
  }
}
