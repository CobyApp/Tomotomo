import 'package:flutter/material.dart';

import 'holo/holo_tokens.dart';

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

/// Full-screen backdrop with a pastel wash and optional ambient color orbs.
class AppShellBackground extends StatelessWidget {
  const AppShellBackground({
    super.key,
    required this.child,
    this.showOrbs = true,
    this.gradientPrimaryTop = false,
  });

  final Widget child;
  final bool showOrbs;

  /// Stronger pink-tinted top (login / auth loading). Otherwise uses the plain [Holo.pageGradient].
  final bool gradientPrimaryTop;

  @override
  Widget build(BuildContext context) {
    final colors = gradientPrimaryTop
        ? [Holo.pink.withValues(alpha: 0.14), Holo.surface]
        : Holo.pageGradient.colors;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
          ),
        ),
        if (showOrbs) ...[
          Positioned(
            top: -60,
            right: -50,
            child: ShellDecoCircle(
              size: 220,
              color: Holo.pink.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: 100,
            left: -80,
            child: ShellDecoCircle(
              size: 180,
              color: Holo.lilac.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -40,
            child: ShellDecoCircle(
              size: 140,
              color: Holo.cyan.withValues(alpha: 0.06),
            ),
          ),
        ],
        child,
      ],
    );
  }
}
