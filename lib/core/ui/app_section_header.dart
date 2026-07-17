import 'package:flutter/material.dart';
import 'app_tokens.dart';
import 'holo/holo_tokens.dart';

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(AppRadii.cardSmall),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.sectionLabel(
                      context,
                    ).copyWith(color: Holo.inkPlum),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: Holo.inkPlumSoft,
                  size: 24,
                ),
                const SizedBox(width: 4),
                Text(
                  expanded ? collapseLabel : expandLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Holo.pink,
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
