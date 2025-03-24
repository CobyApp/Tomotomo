import 'package:flutter/material.dart';

class AppTheme {
  // 메인 컬러 팔레트
  static const Color primary = Color(0xFFFF6B98);    // 모에 핑크
  static const Color secondary = Color(0xFF8B7BFF);  // 소프트 퍼플
  static const Color accent = Color(0xFFFFD93D);     // 파스텔 옐로우
  static const Color subAccent = Color(0xFF6FEDD6);  // 민트 그린
  
  // 배경 그라데이션
  static const List<Color> backgroundGradient = [
    Color(0xFFFFE6F0),  // 연한 핑크
    Color(0xFFF0E6FF),  // 연한 퍼플
  ];

  // 앱 이름 관련
  static const String appNameKo = 'モエチャット';
  static const String appNameEn = 'MoeChat';
  static const String appNameJa = 'モエチャット';

  // 앱 테마 데이터
  static ThemeData get theme => ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Quicksand',  // 나중에 더 귀여운 폰트로 변경 가능
    
    // AppBar 테마
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      iconTheme: IconThemeData(color: primary),
      titleTextStyle: TextStyle(
        color: primary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    // 버튼 테마
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    ),

    // 입력창 테마
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),

    // 카드 테마
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
    ),
  );

  // 귀여운 아이콘 이모티콘
  static const List<String> moeEmoticons = ['♪', '♡', '☆', '✿', '❀', '💕', '✨'];

  // 랜덤 이모티콘 가져오기
  static String getRandomEmoticon() {
    return moeEmoticons[DateTime.now().millisecond % moeEmoticons.length];
  }
} 