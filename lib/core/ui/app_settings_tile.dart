import 'package:flutter/material.dart';
import 'app_tokens.dart';

/// Group of settings rows inside one frosted card.
class AppSettingsPanel extends StatelessWidget {
  const AppSettingsPanel({
    super.key,
    required this.children,
    this.dividerIndent = 56,
  });

  final List<Widget> children;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        color: scheme.surfaceContainerLow.withValues(alpha: 0.92),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(children: _divided(children, scheme)),
    );
  }

  List<Widget> _divided(List<Widget> items, ColorScheme scheme) {
    if (items.isEmpty) return items;
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i < items.length - 1) {
        out.add(Divider(
          height: 1,
          indent: dividerIndent,
          endIndent: 0,
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ));
      }
    }
    return out;
  }
}

class AppSettingsNavTile extends StatelessWidget {
  const AppSettingsNavTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.titleColor,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ic = iconColor ?? scheme.primary;
    final tc = titleColor ?? scheme.onSurface;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: ic.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: ic, size: 22),
      ),
      title: Text(
        title,
        style: AppTextStyles.listTitle(context).copyWith(color: tc, fontSize: 16),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.listSubtitle(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: showChevron ? Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant) : null,
      onTap: onTap,
    );
  }
}
