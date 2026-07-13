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

/// Faint repeating horizontal scanlines over the holo wash — CRT/hologram flavor.
/// Non-interactive; sits between the gradient wash and the orbs/content.
class _ScanlineOverlay extends StatelessWidget {
  const _ScanlineOverlay();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        painter: _ScanlinePainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  const _ScanlinePainter();

  static const double _lineGap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Holo.inkPlum.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += _lineGap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) => false;
}

/// Full-screen backdrop: pastel HOLO-KITSCH gradient wash + scanline overlay +
/// optional gradient orbs (learning / SNS style).
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
        ? [Holo.pink.withValues(alpha: 0.35), Holo.surface]
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
        const _ScanlineOverlay(),
        if (showOrbs) ...[
          Positioned(
            top: -60,
            right: -50,
            child: ShellDecoCircle(size: 220, color: Holo.pink.withValues(alpha: 0.14)),
          ),
          Positioned(
            top: 100,
            left: -80,
            child: ShellDecoCircle(size: 180, color: Holo.lilac.withValues(alpha: 0.12)),
          ),
          Positioned(
            bottom: 60,
            right: -40,
            child: ShellDecoCircle(size: 140, color: Holo.cyan.withValues(alpha: 0.10)),
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
                    gradient: Holo.holoGradient,
                    boxShadow: Holo.cardShadow,
                  ),
                  child: Center(child: Text(brandEmoji, style: const TextStyle(fontSize: 32))),
                ),
                const SizedBox(height: 28),
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
          ),
        ),
      ),
    );
  }
}
