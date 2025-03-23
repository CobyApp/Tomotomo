import 'package:flutter/material.dart';

class BubbleAnimation {
  static SlideTransition buildSlideTransition({
    required Animation<double> animation,
    required Widget child,
    required bool isUser,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(isUser ? 1.0 : -1.0, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
          reverseCurve: Curves.easeOut,
        ),
      ),
      child: child,
    );
  }

  static Animation<double> createScaleAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
  }
} 