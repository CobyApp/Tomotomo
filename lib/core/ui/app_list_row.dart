import 'package:flutter/material.dart';
import 'app_tokens.dart';
import 'paper/paper_tokens.dart';

/// Primary list row: avatar / leading + text column + optional trailing (AI badge, etc.).
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.subtitleMaxLines = 2,
    this.trailing,
    this.onTap,
    this.marginBottom = AppSpacing.listGap,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final int subtitleMaxLines;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double marginBottom;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom),
      child: Material(
        color: p.card,
        borderRadius: BorderRadius.circular(PaperRadii.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(PaperRadii.card),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PaperRadii.card),
              border: Border.all(color: p.cardEdge),
              boxShadow: [
                BoxShadow(color: p.hardShadow, offset: const Offset(0, 3)),
                BoxShadow(
                  color: p.softShadow,
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.listTitle(
                            context,
                          ).copyWith(color: p.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          SizedBox(height: subtitleMaxLines > 1 ? 4 : 2),
                          Text(
                            subtitle!,
                            style: AppTextStyles.listSubtitle(
                              context,
                            ).copyWith(color: p.inkSoft),
                            maxLines: subtitleMaxLines,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Same chrome as [AppListRow] but custom [middle] (e.g. chat row with time on title line).
class AppListRowCustom extends StatelessWidget {
  const AppListRowCustom({
    super.key,
    required this.leading,
    required this.middle,
    this.trailing,
    this.onTap,
    this.marginBottom = AppSpacing.listGap,
    this.verticalPadding = 12,
  });

  final Widget leading;
  final Widget middle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double marginBottom;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom),
      child: Material(
        color: p.card,
        borderRadius: BorderRadius.circular(PaperRadii.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(PaperRadii.card),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PaperRadii.card),
              border: Border.all(color: p.cardEdge),
              boxShadow: [
                BoxShadow(color: p.hardShadow, offset: const Offset(0, 3)),
                BoxShadow(
                  color: p.softShadow,
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: verticalPadding,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Expanded(child: middle),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
