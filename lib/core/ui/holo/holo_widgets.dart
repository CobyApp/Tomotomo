import 'package:flutter/material.dart';
import '../app_tokens.dart';
import 'holo_tokens.dart';

class HoloButton extends StatelessWidget {
  const HoloButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : Holo.holoGradient,
        color: onPressed == null ? Holo.surfaceMuted : null,
        borderRadius: BorderRadius.circular(AppRadii.cardSmall),
        boxShadow: onPressed == null ? null : Holo.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.cardSmall),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                      color: onPressed == null
                          ? Holo.inkPlumSoft
                          : Colors.white,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: onPressed == null
                          ? Holo.inkPlumSoft
                          : Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? Holo.pink.withValues(alpha: 0.11) : Holo.surfaceCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: filled ? Holo.pink.withValues(alpha: 0.18) : Holo.border,
        ),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          color: Holo.inkPlum,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        child: child,
      ),
    );
  }
}

class HoloCard extends StatelessWidget {
  const HoloCard({
    super.key,
    required this.child,
    this.dashed = false,
    this.padding,
  });
  final Widget child;
  final bool dashed;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Holo.surfaceCard.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: dashed
              ? Holo.cyan.withValues(alpha: 0.42)
              : Holo.pink.withValues(alpha: 0.14),
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
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: Holo.holoGradient,
      ),
      child: ClipOval(child: child),
    );
  }
}
