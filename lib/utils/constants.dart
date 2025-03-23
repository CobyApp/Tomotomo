import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF6EB0);
  static const Color primaryDark = Color(0xFFE94D89);
  static const Color accent = Color(0xFFFFB0D8);
  static const Color background = Color(0xFFFFF0F7);
  static const Color userBubble = Color(0xFFFF6EB0);
  static const Color userBubbleText = Colors.white;
  static const Color botBubble = Color(0xFFFFE6F3);
  static const Color botBubbleText = Color(0xFF333333);
  static const Color botBubbleBorder = Color(0xFFFFB0D8);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color inputBackground = Colors.white;
  static const Color divider = Color(0xFFC6C6C8);
  static const Color sendButton = Color(0xFFFF6EB0);
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
    color: isUser ? AppColors.userBubble : AppColors.botBubble,
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

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          fontFamily: 'Nunito',
        ),
      ),
      fontFamily: 'Nunito',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF333333)),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF333333)),
      ),
    );
  }
} 