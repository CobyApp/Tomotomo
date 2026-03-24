import 'package:flutter/material.dart';
import 'app_tokens.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    required this.expanded,
    required this.expandLabel,
    required this.collapseLabel,
    required this.onToggle,
  });

  final String title;
  final bool expanded;
  final String expandLabel;
  final String collapseLabel;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text(title, style: AppTextStyles.sectionLabel(context))),
                Icon(
                  expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: scheme.onSurfaceVariant,
                  size: 26,
                ),
                const SizedBox(width: 4),
                Text(
                  expanded ? collapseLabel : expandLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
