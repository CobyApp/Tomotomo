import 'package:flutter/material.dart';
import 'holo_tokens.dart';

class HoloButton extends StatelessWidget {
  const HoloButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : Holo.holoGradient,
        color: onPressed == null ? Holo.inkPlumSoft.withValues(alpha: 0.3) : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: Holo.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 18, color: Colors.white), const SizedBox(width: 6)],
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
            ]),
          ),
        ),
      ),
    );
  }
}

class HoloChip extends StatelessWidget {
  const HoloChip({super.key, required this.child, this.filled = true});
  final Widget child;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: filled ? Holo.holoGradient : null,
        color: filled ? null : Holo.surfaceCard,
        borderRadius: BorderRadius.circular(999),
        border: filled ? null : Border.all(color: Holo.cyan, width: 2),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: filled ? Colors.white : Holo.inkPlum,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
        child: child,
      ),
    );
  }
}

class HoloCard extends StatelessWidget {
  const HoloCard({super.key, required this.child, this.dashed = false, this.padding});
  final Widget child;
  final bool dashed;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Holo.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dashed ? Holo.cyan : Holo.pink.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: Holo.cardShadow,
      ),
      child: child,
    );
  }
}

class HoloGradientRing extends StatelessWidget {
  const HoloGradientRing({super.key, required this.child, this.size = 44});
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: Holo.holoGradient),
      child: ClipOval(child: child),
    );
  }
}
