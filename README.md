# 토모토모 (Tomotomo)

일본어 학습을 위한 AI 채팅 앱

## 주요 기능

- AI 캐릭터와의 자연스러운 일본어 대화
- 대화 내용의 표현 설명 제공
- 단어와 문법 학습 지원
- 부적절한 표현 신고 기능

## 기술 스택

- Flutter
- Google Generative AI
- Provider (상태 관리)
- Shared Preferences (로컬 저장소)
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
   - `.env` 파일을 프로젝트 루트에 생성
   - Google AI API 키 설정

4. 앱 실행
   ```bash
   flutter run
   ```

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
- 주요 변경사항:
  - 신고 기능 추가
  - UI/UX 개선
  - 버그 수정

## 라이선스

© 2024 토모토모. All rights reserved.
