import 'package:flutter/material.dart';
import 'app_tokens.dart';
import 'holo/holo_tokens.dart';

/// Group of settings rows inside one holo card.
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
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        color: Holo.surfaceCard.withValues(alpha: 0.82),
        border: Border.all(color: Holo.pink.withValues(alpha: 0.14)),
        boxShadow: Holo.cardShadow,
      ),
      child: Column(children: _divided(children)),
    );
  }

  List<Widget> _divided(List<Widget> items) {
    if (items.isEmpty) return items;
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i < items.length - 1) {
        out.add(
          Divider(
            height: 1,
            indent: dividerIndent,
            endIndent: 0,
            color: Holo.border,
          ),
        );
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
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final bool showChevron;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ic = iconColor ?? Holo.pink;
    final tc = titleColor ?? Holo.inkPlum;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      minTileHeight: 68,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: ic.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: ic, size: 22),
      ),
      title: Text(
        title,
        style: AppTextStyles.listTitle(
          context,
        ).copyWith(color: tc, fontSize: 15.5),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.listSubtitle(
                context,
              ).copyWith(color: Holo.inkPlumSoft),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing:
          trailing ??
          (showChevron
              ? Icon(
                  Icons.chevron_right_rounded,
                  color: Holo.inkPlumSoft.withValues(alpha: 0.7),
                )
              : null),
      onTap: onTap,
    );
  }
}
