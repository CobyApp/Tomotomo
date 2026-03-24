import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/supabase/app_supabase.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../domain/entities/user_theme.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import '../theme/theme_notifier.dart';

/// Preset themes (accent + chat bubbles + chat background); saves to Supabase and updates [ThemeNotifier].
class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  static const List<
      ({
        String key,
        String? accent,
        String? userBubble,
        String? botBubble,
        String? chatBg,
      })> _presets = [
    (key: 'themePresetDefault', accent: null, userBubble: null, botBubble: null, chatBg: null),
    (key: 'themePresetPurple', accent: '7C3AED', userBubble: '7C3AED', botBubble: 'EDE9FE', chatBg: 'F5F3FF'),
    (key: 'themePresetBlue', accent: '2563EB', userBubble: '2563EB', botBubble: 'DBEAFE', chatBg: 'EFF6FF'),
    (key: 'themePresetGreen', accent: '059669', userBubble: '059669', botBubble: 'D1FAE5', chatBg: 'ECFDF5'),
    (key: 'themePresetCoral', accent: 'F43F5E', userBubble: 'F43F5E', botBubble: 'FFE4E6', chatBg: 'FFF1F2'),
  ];

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeNotifier>();
    final lang = context.watch<LocaleNotifier>().languageCode;
    final scheme = Theme.of(context).colorScheme;
    return AppPageScaffold(
      title: context.tr('themeTitle'),
      transparentBackground: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, 8, AppSpacing.pageH, AppSpacing.pageBottom),
        children: [
          Text(
            context.tr('themeSectionTitle'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('themeSectionSubtitle'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final cross = w > 520 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cross,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                itemCount: _presets.length,
                itemBuilder: (context, i) {
                  final p = _presets[i];
                  final label = AppStrings.of(lang, p.key);
                  final selected = _matches(notifier.overrides, p);
                  return _PresetCard(
                    label: label,
                    preset: p,
                    selected: selected,
                    onTap: () => _apply(context, notifier, p, lang),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
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
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(context.tr('themeReset')),
            ),
          ),
        ],
      ),
    );
  }

  bool _matches(
    UserTheme? o,
    ({
      String key,
      String? accent,
      String? userBubble,
      String? botBubble,
      String? chatBg,
    }) p,
  ) {
    if (p.accent == null) {
      return o == null ||
          ((o.accent == null || o.accent!.isEmpty) &&
              (o.chatBubbleUser == null || o.chatBubbleUser!.isEmpty) &&
              (o.chatBubbleBot == null || o.chatBubbleBot!.isEmpty) &&
              (o.chatBg == null || o.chatBg!.isEmpty));
    }
    if (o == null) return false;
    return o.accent == p.accent &&
        o.chatBubbleUser == p.userBubble &&
        o.chatBubbleBot == p.botBubble &&
        o.chatBg == p.chatBg;
  }

  Future<void> _apply(
    BuildContext context,
    ThemeNotifier notifier,
    ({
      String key,
      String? accent,
      String? userBubble,
      String? botBubble,
      String? chatBg,
    }) p,
    String lang,
  ) async {
    if (p.accent == null) {
      await notifier.clear();
    } else {
      await notifier.save(UserTheme(
        accent: p.accent,
        chatBubbleUser: p.userBubble,
        chatBubbleBot: p.botBubble,
        chatBg: p.chatBg,
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

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.label,
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final ({
    String key,
    String? accent,
    String? userBubble,
    String? botBubble,
    String? chatBg,
  }) preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = preset.accent != null ? AppTheme.parseAccentHex(preset.accent) : scheme.primary;
    final soft = preset.chatBg != null ? AppTheme.parseAccentHex(preset.chatBg) : scheme.surfaceContainerHigh;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? accent : scheme.outlineVariant.withValues(alpha: 0.35),
              width: selected ? 2.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (preset.accent == null)
                    Icon(Icons.auto_awesome_rounded, color: scheme.onSurfaceVariant, size: 28)
                  else
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [accent, Color.alphaBlend(accent.withValues(alpha: 0.55), soft)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  if (selected) ...[
                    const Spacer(),
                    Icon(Icons.check_circle_rounded, color: accent, size: 22),
                  ],
                ],
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
