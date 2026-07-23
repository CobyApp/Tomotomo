import 'package:flutter/material.dart';
import 'app_tokens.dart';
import 'paper/paper_tokens.dart';

/// Group of settings rows inside one paper card.
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
    final p = context.paper;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PaperRadii.card),
        color: p.card,
        border: Border.all(color: p.cardEdge, width: 2.5),
        boxShadow: [
          BoxShadow(color: p.hardShadow, offset: const Offset(4, 4)),
        ],
      ),
      child: Column(children: _divided(context, children)),
    );
  }

  List<Widget> _divided(BuildContext context, List<Widget> items) {
    if (items.isEmpty) return items;
    final cardEdge = context.paper.cardEdge;
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i < items.length - 1) {
        out.add(
          Divider(
            height: 1,
            indent: dividerIndent,
            endIndent: 0,
            color: cardEdge,
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
    this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.titleColor,
    this.showChevron = true,
    this.trailing,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final bool showChevron;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final ic = iconColor ?? p.coral;
    final tc = titleColor ?? p.ink;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      minTileHeight: 68,
      leading: icon == null
          ? null
          : Container(
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
              ).copyWith(color: p.inkSoft),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing:
          trailing ??
          (showChevron
              ? Icon(
                  Icons.chevron_right_rounded,
                  color: p.inkSoft.withValues(alpha: 0.7),
                )
              : null),
      onTap: onTap,
    );
  }
}
