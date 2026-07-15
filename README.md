# 토모토모 (Tomotomo)

일본어 학습을 위한 AI 채팅 앱

## 다운로드

[![Google Play](https://img.shields.io/badge/Google_Play-414141?style=for-the-badge&logo=google-play&logoColor=white)](https://play.google.com/store/apps/details?id=com.dime.tomotomo)
[![App Store](https://img.shields.io/badge/App_Store-0D96F6?style=for-the-badge&logo=app-store&logoColor=white)](https://play.google.com/store/apps/details?id=com.dime.tomotomo)

## 주요 기능

- AI 캐릭터와의 자연스러운 일본어 대화
- 대화 내용의 표현 설명 제공
- 단어장과 홈 화면 위젯
- 로컬 커스텀 AI 튜터
- 리워드 광고를 통한 무료 포인트 적립
- 부적절한 표현 신고 기능

## 스크린샷

<img width="800" alt="Screenshot 2025-04-15 at 10 02 09 PM" src="https://github.com/user-attachments/assets/30c60647-e2b7-4573-ba53-d5535f89635b" />


## 기술 스택

- Flutter
- Google Generative AI
- Provider (상태 관리)
- Hive CE (로컬 저장소)
- Google Mobile Ads (리워드 광고)
- URL Launcher (이메일 연동)

## 설치 방법

1. Flutter 개발 환경 설정
   ```bash
   flutter doctor
   ```

2. 의존성 설치
   ```bash
   flutter pub get
   ```

3. 환경 변수 설정
   ```bash
   cp .env.example .env
   ```
   - `GEMINI_API_KEY` 설정
   - 릴리스 광고를 사용할 경우 `ADMOB_REWARDED_ANDROID`와 `ADMOB_REWARDED_IOS` 설정

4. 앱 실행
   - iPhone 실기기는 profile 모드를 사용합니다.
     ```bash
     ./run_on_iphone.sh
     ```
   - 시뮬레이터와 Android는 `flutter run`을 사용할 수 있습니다.

## 빌드 방법

### Android
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ipa --release
```

## 버전 정보

- 현재 버전: 1.0.3+4

## 라이선스

© 2024 토모토모. All rights reserved.
