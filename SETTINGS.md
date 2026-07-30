# 토모토모 설정 가이드

현재 앱은 Hive 기반 로컬 앱입니다. 별도 로그인이나 원격 데이터베이스 설정은 필요하지 않습니다.

## 환경 변수

앱에 넣는 설정 파일은 없습니다. `.env`는 더 이상 읽지 않으며, 비밀값은 빌드 시점에
주입합니다 — 번들에 들어가는 파일에 두면 APK/IPA를 열어 그대로 꺼낼 수 있습니다.

### 온디바이스 AI

AI용 환경 변수나 API 키는 필요하지 않습니다. 최초 실행에서 Gemma 4 E2B 모델(2.59GB)을 설치하며, 설치 파일은 고정 리비전·파일 크기·SHA-256으로 검증합니다. 설치 뒤 캐릭터 채팅, 표현 분석, X 페르소나 생성은 LiteRT-LM을 통해 기기 안에서 실행됩니다.

- Android: API 24 이상, ARM64 기기
- iOS: iOS 16 이상, ARM64 기기
- GPU를 우선 사용하고 사용할 수 없으면 CPU로 폴백합니다.
- 설정의 `온디바이스 AI 모델`에서 모델을 삭제하거나 다시 설치할 수 있습니다.
- 모델 다운로드, X 공개 프로필 가져오기, 리워드 광고에는 네트워크가 필요합니다.

### 리워드 광고

디버그 빌드는 Google 테스트 광고 단위를 사용하므로 설정할 것이 없습니다. 릴리스
빌드는 GitHub Actions가 아래 4개 시크릿을 주입합니다.

| GitHub 시크릿 | 주입 경로 |
|---|---|
| `ADMOB_REWARDED_ANDROID` | `--dart-define` |
| `ADMOB_REWARDED_IOS` | `--dart-define` |
| `ADMOB_APP_ID_ANDROID` | `-PadmobAppId=` → 매니페스트의 `${admobAppId}` |
| `ADMOB_APP_ID_IOS` | `ios/Flutter/AdMob.xcconfig` → Info.plist의 `$(ADMOB_APP_ID)` |

네이티브 App ID를 손으로 바꿀 필요는 없습니다. 두 파일 모두 빌드 시 치환되는
플레이스홀더를 담고 있고, `ios/Flutter/AdMob.xcconfig`는 `.gitignore` 대상입니다.

**시크릿이 없으면 릴리스 빌드도 테스트 광고를 띄우고 수익이 발생하지 않습니다.**
앱은 `AdConfig.usingTestAdUnits`로 이 상태를 알 수 있습니다.

로컬에서 릴리스 광고를 확인하려면 CI와 같은 값을 직접 넘깁니다.

```bash
flutter build ios --release \
  --dart-define=ADMOB_REWARDED_IOS=ca-app-pub-…/…
```

### 포인트

서버가 없으므로 지갑은 기기 안에만 있습니다 (`points` 박스).

| 항목 | 값 |
|---|---|
| 시작 잔액 | 200 |
| 답장 1회 | 5 |
| 친구 새로 만들기 | 10 |
| X 프로필 가져오기 | 10 |
| 광고 1회 보상 | 50 |
| 하루 광고 상한 | 10 |
| 하루 무료 지급 | 50 (첫 실행 시, 광고·네트워크 없이) |

하루 무료 지급이 있는 이유: 광고는 네트워크를 요구하는데 앱의 나머지는 전부
오프라인입니다. 그것만이 충전 수단이면 비행기나 음영 지역에서 잔액이 답장 1회
값 아래로 떨어지는 순간 핵심 기능이 잠깁니다. 값은 모두
`lib/core/ads/ad_config.dart`에 있습니다.

## iPhone 실기기

iOS 26 이상 실기기에서는 debug JIT보다 profile AOT 실행을 권장합니다.

```bash
flutter devices
./run_on_iphone.sh -d <device-id>
```

무선 디바이스에서 VM Service 검색이 실패하지만 설치만 확인하려면 release 모드를 사용합니다.

```bash
RUN_MODE=release ./run_on_iphone.sh -d <device-id>
```

서명 오류가 발생하면 Xcode에서 `ios/Runner.xcworkspace`를 열고 `Runner`와 `NotebookWidgetExtension`에 같은 Team을 지정합니다.

## CocoaPods 재생성

`flutter clean` 이후에는 Flutter 설정 파일을 먼저 생성해야 합니다.

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

## Android 릴리스 서명

`android/key.properties.example`을 `android/key.properties`로 복사한 뒤 실제 키스토어 정보를 입력합니다. 디버그 실행에는 필요하지 않습니다.
