import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/home_widget/notebook_home_widget_sync.dart';
import '../../core/locale/languages.dart';
import '../../core/ui/app_settings_tile.dart';
import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_status_views.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/saved_expression_repository.dart';
import '../locale/l10n_context.dart';
import '../locale/friend_language_notifier.dart';
import '../locale/locale_notifier.dart';

/// Single local user id (no auth).
const String _localUserId = 'local';

/// Combined language settings: the app UI language and the friend language,
/// each as its own section, so both live under one "Language" menu.
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  static const List<String> _languages = kSupportedLanguageList;

  /// Applies the UI language, then re-pushes the home widget's text.
  ///
  /// The widget's chrome is pushed from Dart, and the only other places that
  /// push are MainShell's initState and a word add/delete — so switching
  /// language left the home screen widget in the OLD language until the next
  /// relaunch or word edit.
  Future<void> _selectAppLanguage(
    BuildContext context,
    String code,
    Profile profile,
  ) async {
    final expressions = context.read<SavedExpressionRepository>();
    final friendLanguage = context.read<FriendLanguageNotifier>();
    await context.read<LocaleNotifier>().setAppLanguage(code, profile);
    try {
      await syncNotebookToHomeWidget(
        expressions,
        defaultLangIfUnset: friendLanguage.resolve(code),
      );
    } catch (_) {
      // A stale widget label must never break changing the language.
    }
  }

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
              AppSettingsPanel(
                dividerIndent: 16,
                children: [
                  for (final code in _languages)
                    tile(
                      languageEndonym(code),
                      appLanguage == code,
                      () => _selectAppLanguage(context, code, profile),
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
