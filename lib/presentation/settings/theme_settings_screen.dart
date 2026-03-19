import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/supabase/app_supabase.dart';
import '../../domain/entities/user_theme.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import '../theme/theme_notifier.dart';

/// Preset theme options; saves to Supabase and updates [ThemeNotifier].
class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  static const List<({String key, String? accent, String? userBubble, String? botBubble})> _presets = [
    (key: 'themePresetDefault', accent: null, userBubble: null, botBubble: null),
    (key: 'themePresetPurple', accent: '6A3EA1', userBubble: '6A3EA1', botBubble: null),
    (key: 'themePresetBlue', accent: '2563EB', userBubble: '2563EB', botBubble: null),
    (key: 'themePresetGreen', accent: '059669', userBubble: '059669', botBubble: null),
    (key: 'themePresetCoral', accent: 'E11D48', userBubble: 'E11D48', botBubble: null),
  ];

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeNotifier>();
    final lang = context.watch<LocaleNotifier>().languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('themeTitle')),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text(
            context.tr('themeSectionTitle'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _presets.map((p) {
              final label = AppStrings.of(lang, p.key);
              final isSelected = _matches(notifier.overrides, p);
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => _apply(context, notifier, p, lang),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              final user = AppSupabase.auth.currentUser;
              if (user == null) return;
              await notifier.clear();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('themeResetDone'))),
                );
              }
            },
            icon: const Icon(Icons.refresh),
            label: Text(context.tr('themeReset')),
          ),
        ],
      ),
    );
  }

  bool _matches(UserTheme? o, ({String key, String? accent, String? userBubble, String? botBubble}) p) {
    if (p.accent == null) {
      return o == null || (o.accent == null && o.chatBubbleUser == null);
    }
    if (o == null) return false;
    return o.accent == p.accent && (o.chatBubbleUser == p.userBubble || p.userBubble == null);
  }

  Future<void> _apply(
    BuildContext context,
    ThemeNotifier notifier,
    ({String key, String? accent, String? userBubble, String? botBubble}) p,
    String lang,
  ) async {
    if (p.accent == null) {
      await notifier.clear();
    } else {
      await notifier.save(UserTheme(
        accent: p.accent,
        chatBubbleUser: p.userBubble,
        chatBubbleBot: p.botBubble,
      ));
    }
    if (context.mounted) {
      final name = AppStrings.of(lang, p.key);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(lang, 'themeAppliedNamed', params: {'name': name}))),
      );
    }
  }
}
