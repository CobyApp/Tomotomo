import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Decorative circle used behind auth / shell screens.
class ShellDecoCircle extends StatelessWidget {
  const ShellDecoCircle({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

/// Full-screen backdrop: soft gradient + optional orbs (learning / SNS style).
class AppShellBackground extends StatelessWidget {
  const AppShellBackground({
    super.key,
    required this.child,
    this.showOrbs = true,
    this.gradientPrimaryTop = false,
  });

  final Widget child;
  final bool showOrbs;

  /// Stronger pink-tinted top (login / auth loading). Otherwise uses [AppTheme] shell tones.
  final bool gradientPrimaryTop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = gradientPrimaryTop
        ? [
            scheme.primaryContainer.withValues(alpha: 0.45),
            scheme.surface,
          ]
        : [
            AppTheme.shellGradientTop(scheme),
            Color.lerp(AppTheme.shellGradientBottom(scheme), scheme.surface, 0.55) ?? scheme.surface,
          ];

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: gradientPrimaryTop ? Alignment.topCenter : Alignment.topLeft,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
          ),
        ),
        if (showOrbs) ...[
          Positioned(
            top: -60,
            right: -50,
            child: ShellDecoCircle(size: 220, color: scheme.primary.withValues(alpha: 0.10)),
          ),
          Positioned(
            top: 100,
            left: -80,
            child: ShellDecoCircle(size: 180, color: scheme.tertiary.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: 60,
            right: -40,
            child: ShellDecoCircle(size: 140, color: scheme.secondary.withValues(alpha: 0.07)),
          ),
        ],
        child,
      ],
    );
  }
}

/// Shown while [AppAuthState] is resolving session.
class AppAuthLoadingView extends StatelessWidget {
  const AppAuthLoadingView({super.key, this.brandEmoji = '🌸'});

  final String brandEmoji;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: AppShellBackground(
        gradientPrimaryTop: true,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.tertiary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.28),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(child: Text(brandEmoji, style: const TextStyle(fontSize: 32))),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: scheme.primary,
                    strokeCap: StrokeCap.round,
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
