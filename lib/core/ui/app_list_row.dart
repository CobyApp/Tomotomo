import 'package:flutter/material.dart';
import 'app_tokens.dart';

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
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.38)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          style: AppTextStyles.listTitle(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          SizedBox(height: subtitleMaxLines > 1 ? 4 : 2),
                          Text(
                            subtitle!,
                            style: AppTextStyles.listSubtitle(context),
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
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.38)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: verticalPadding),
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
