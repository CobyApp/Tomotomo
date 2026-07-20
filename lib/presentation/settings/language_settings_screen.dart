import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/app_settings_tile.dart';
import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_status_views.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../core/ui/paper/paper_widgets.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../locale/friend_language_notifier.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';

/// Single local user id (no auth).
const String _localUserId = 'local';

/// Combined language settings: the app UI language and the friend language,
/// each as its own section, so both live under one "Language" menu.
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  static const List<(String, String)> _languages = [
    ('ko', 'friendLangKo'),
    ('ja', 'friendLangJa'),
    ('en', 'friendLangEn'),
    ('zh', 'friendLangZh'),
  ];

  @override
  Widget build(BuildContext context) {
    return PaperScaffold(
      title: context.tr('languageMenuTitle'),
      transparentBackground: false,
      body: FutureBuilder<Profile?>(
        future: context.read<ProfileRepository>().getProfile(_localUserId),
        builder: (context, snap) {
          if (!snap.hasData) return const PaperLoadingBody();
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
          final appLanguage = context.watch<LocaleNotifier>().languageCode;
          final friendLanguage = context
              .watch<FriendLanguageNotifier>()
              .resolve(appLanguage);

          Widget tile(
            String label,
            bool selected,
            VoidCallback onTap,
          ) {
            return AppSettingsNavTile(
              title: label,
              showChevron: false,
              trailing: selected
                  ? Icon(Icons.check_circle_rounded, color: p.coral, size: 24)
                  : null,
              onTap: onTap,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageH,
              AppSpacing.pageTop,
              AppSpacing.pageH,
              AppSpacing.pageBottom,
            ),
            children: [
              PaperSectionLabel(context.tr('settingsAppLanguage')),
              AppSettingsPanel(
                dividerIndent: 16,
                children: [
                  for (final (code, key) in _languages)
                    tile(
                      context.tr(key),
                      appLanguage == code,
                      () => context.read<LocaleNotifier>().setAppLanguage(
                        code,
                        profile,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              PaperSectionLabel(context.tr('friendLanguageTitle')),
              AppSettingsPanel(
                dividerIndent: 16,
                children: [
                  for (final (code, key) in _languages)
                    tile(
                      context.tr(key),
                      friendLanguage == code,
                      () => context.read<FriendLanguageNotifier>().setLanguage(
                        code,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
