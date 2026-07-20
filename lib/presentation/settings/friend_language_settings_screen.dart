import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/app_settings_tile.dart';
import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../locale/l10n_context.dart';
import '../locale/friend_language_notifier.dart';
import '../locale/locale_notifier.dart';

/// Lets the user choose which language's friends they practice with. The choice
/// persists via [FriendLanguageNotifier] and drives the friends-list filter on
/// the main screen (which watches the same notifier).
class FriendLanguageSettingsScreen extends StatelessWidget {
  const FriendLanguageSettingsScreen({super.key});

  static const List<(String, String)> _languages = [
    ('ko', 'friendLangKo'),
    ('ja', 'friendLangJa'),
    ('en', 'friendLangEn'),
    ('zh', 'friendLangZh'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final friend = context.watch<FriendLanguageNotifier>();
    final appLanguage = context.watch<LocaleNotifier>().languageCode;
    final current = friend.resolve(appLanguage);

    return PaperScaffold(
      title: context.tr('friendLanguageTitle'),
      transparentBackground: false,
      body: ListView(
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
              for (final (code, key) in _languages)
                AppSettingsNavTile(
                  icon: Icons.people_alt_rounded,
                  title: context.tr(key),
                  showChevron: false,
                  trailing: current == code
                      ? Icon(Icons.check_circle_rounded, color: p.coral, size: 24)
                      : null,
                  onTap: () => _set(context, code),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _set(BuildContext context, String code) async {
    await context.read<FriendLanguageNotifier>().setLanguage(code);
    if (context.mounted) Navigator.pop(context);
  }
}
