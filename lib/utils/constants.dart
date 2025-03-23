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
  // 앱 기본 색상
  static const Color primaryColor = Color(0xFF6A3EA1);
  static const Color secondaryColor = Color(0xFFEFE9F7);
  static const Color accentColor = Color(0xFFFF8FAB);
  
  // 텍스트 색상
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  
  // 배경 색상
  static const Color background = Color(0xFFFCFCFC);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // 그라데이션
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8A4FFF),
      Color(0xFF6A3EA1),
    ],
  );
  
  // 그림자
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  // 모서리 둥글기
  static const double borderRadius = 16.0;
  static BorderRadius defaultBorderRadius = BorderRadius.circular(borderRadius);
  
  // 애니메이션 지속 시간
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  // 텍스트 스타일
  static TextStyle get headingLarge => const TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: textPrimary,
  );
  
  static TextStyle get headingMedium => const TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 20,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: textPrimary,
  );
  
  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: textPrimary,
  );
  
  static TextStyle get bodyMedium => const TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: textPrimary,
  );
  
  static TextStyle get bodySmall => const TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: textSecondary,
  );
  
  static TextStyle get buttonText => const TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  // 버튼 스타일
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    elevation: 0,
  );
  
  // 입력창 장식
  static InputDecoration get inputDecoration => InputDecoration(
    filled: true,
    fillColor: cardBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: const BorderSide(color: primaryColor),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: bodyMedium.copyWith(color: textLight),
  );

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