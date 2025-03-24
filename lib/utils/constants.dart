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

class AppConstants {
  // 앱 이름
  static const String appNameKo = '모에톡';
  static const String appNameEn = 'MoeTalk';
  static const String appNameJa = 'モエトーク';

  // 라우트
  static const String initialRoute = '/';
  static const String chatRoute = '/chat';
  static const String settingsRoute = '/settings';

  // 애셋 경로
  static const String patternPath = 'assets/images/patterns/moe_pattern.png';
}

class Constants {
  // API 관련 상수
  static const String apiBaseUrl = 'https://api.example.com';
  
  // 저장소 키
  static const String storageKeyLanguage = 'selected_language';
  static const String storageKeyTheme = 'selected_theme';
  
  // 기타 상수
  static const int maxMessageLength = 500;
  static const Duration typingDelay = Duration(milliseconds: 800);
} 