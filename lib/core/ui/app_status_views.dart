import 'package:flutter/material.dart';
import 'app_tokens.dart';

class AppLoadingBody extends StatelessWidget {
  const AppLoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              color: seed,
              strokeCap: StrokeCap.round,
            ),
          ),
        ],
      ),
    );
  }
}

class AppErrorBody extends StatelessWidget {
  const AppErrorBody({super.key, required this.message, required this.onRetry, required this.retryLabel});

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                color: scheme.errorContainer.withValues(alpha: 0.45),
              ),
              child: Icon(Icons.cloud_off_rounded, size: 36, color: scheme.error),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45, color: scheme.onSurface),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: Text(retryLabel)),
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final scheme = Theme.of(context).colorScheme;
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
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primaryContainer,
                    scheme.secondaryContainer,
                  ],
                ),
              ),
              child: Center(
                child: emoji != null
                    ? Text(emoji!, style: const TextStyle(fontSize: 38))
                    : Icon(icon, size: 40, color: scheme.primary),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
