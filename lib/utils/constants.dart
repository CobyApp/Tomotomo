import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF007AFF);
  static const Color background = Color(0xFFF2F2F7);
  static const Color userBubble = Color(0xFF007AFF);
  static const Color aiBubble = Color(0xFFE5E5EA);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFC6C6C8);
}

class AppTextStyles {
  static const String fontFamily = '.SF Pro Text';
  
  static const TextStyle message = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.normal,
    height: 1.3,
    letterSpacing: -0.41,
    fontFamily: fontFamily,
  );
  
  static const TextStyle input = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.41,
    fontFamily: fontFamily,
  );
  
  static const TextStyle timestamp = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.normal,
    fontFamily: fontFamily,
  );
}

class AppDecorations {
  static BoxDecoration messageBubble({required bool isUser}) => BoxDecoration(
    color: isUser ? AppColors.userBubble : AppColors.aiBubble,
    borderRadius: BorderRadius.circular(18),
  );
  
  static BoxDecoration inputDecoration = BoxDecoration(
    color: AppColors.inputBackground,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
} 