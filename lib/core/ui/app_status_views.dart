import 'package:flutter/material.dart';
import 'app_tokens.dart';
import 'holo/holo_tokens.dart';
import 'holo/holo_widgets.dart';

class AppLoadingBody extends StatelessWidget {
  const AppLoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Holo.pink,
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
                color: Holo.pink.withValues(alpha: 0.10),
                border: Border.all(color: Holo.pink.withValues(alpha: 0.16)),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 34,
                color: Holo.pink,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: Holo.inkPlum,
              ),
            ),
            const SizedBox(height: 20),
            HoloButton(
              icon: Icons.refresh_rounded,
              label: retryLabel,
              onPressed: onRetry,
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
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Holo.inkPlumSoft, height: 1.35),
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
                borderRadius: BorderRadius.circular(28),
                gradient: Holo.holoGradient,
                border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
                boxShadow: Holo.cardShadow,
              ),
              child: Center(
                child: emoji != null
                    ? Text(emoji!, style: const TextStyle(fontSize: 38))
                    : Icon(icon, size: 38, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Holo.inkPlum,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Holo.inkPlumSoft,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
