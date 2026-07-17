import 'package:flutter/material.dart';
import 'app_tokens.dart';
import 'paper/paper_tokens.dart';
import 'paper/paper_widgets.dart';

/// Paper-styled loading state. Kept as a distinct type (rather than a
/// re-export of [PaperLoadingBody]) so callers unaffected by this migration
/// keep referencing a stable name.
class AppLoadingBody extends StatelessWidget {
  const AppLoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: p.coral,
              strokeCap: StrokeCap.round,
            ),
          ),
        ],
      ),
    );
  }
}

class AppErrorBody extends StatelessWidget {
  const AppErrorBody({
    super.key,
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pageH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.coral.withValues(alpha: 0.10),
                border: Border.all(color: p.coral.withValues(alpha: 0.30)),
              ),
              child: Icon(Icons.error_outline_rounded, size: 34, color: p.coral),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.45, color: p.ink),
            ),
            const SizedBox(height: 20),
            PaperButton(
              icon: Icons.refresh_rounded,
              label: retryLabel,
              onPressed: onRetry,
              expand: false,
            ),
          ],
        ),
      ),
    );
  }
}

class AppEmptyHint extends StatelessWidget {
  const AppEmptyHint({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: context.paper.inkSoft,
          height: 1.35,
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.emoji,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: p.card,
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
              child: Center(
                child: emoji != null
                    ? Text(emoji!, style: const TextStyle(fontSize: 38))
                    : Icon(icon, size: 38, color: p.coral),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: p.inkSoft, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
