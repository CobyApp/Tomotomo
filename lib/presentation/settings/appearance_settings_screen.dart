import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_settings_tile.dart';
import '../../core/ui/app_tokens.dart';
import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_tokens.dart';
import '../locale/l10n_context.dart';
import '../theme/theme_notifier.dart';

/// Appearance (theme mode) settings: Light (default) / Dark / System.
class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final notifier = context.watch<ThemeNotifier>();

    Widget tile(String label, ThemeMode value) {
      return AppSettingsNavTile(
        title: label,
        showChevron: false,
        trailing: notifier.mode == value
            ? Icon(Icons.check_circle_rounded, color: p.coral, size: 24)
            : null,
        onTap: () => context.read<ThemeNotifier>().setMode(value),
      );
    }

    return PaperScaffold(
      title: context.tr('appearanceTitle'),
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
              tile(context.tr('appearanceLight'), ThemeMode.light),
              tile(context.tr('appearanceDark'), ThemeMode.dark),
              tile(context.tr('appearanceSystem'), ThemeMode.system),
            ],
          ),
        ],
      ),
    );
  }
}
