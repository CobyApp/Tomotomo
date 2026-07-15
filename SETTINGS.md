# 토모토모 설정 가이드

현재 앱은 Hive 기반 로컬 앱입니다. 별도 로그인이나 원격 데이터베이스 설정은 필요하지 않습니다.

## 환경 변수

프로젝트 루트에서 예시 파일을 복사합니다.

```bash
cp .env.example .env
```

### Gemini

| 키 | 필수 | 설명 |
|---|---|---|
| `GEMINI_API_KEY` | 예 | Google AI Studio에서 발급한 API 키 |
| `GEMINI_MODEL` | 아니요 | 기본값 `gemini-2.5-flash-lite` |
| `GEMINI_TEMPERATURE` | 아니요 | 기본값 `0.2` |
| `GEMINI_MAX_OUTPUT_TOKENS` | 아니요 | 기본값 `768` |
| `GEMINI_MAX_CHAT_CONTENTS` | 아니요 | 요청에 포함할 최근 대화 수 |

### 리워드 광고

디버그 빌드는 Google 테스트 광고 ID를 사용합니다. 릴리스 광고를 사용하려면 다음 값을 설정하고 네이티브 App ID도 실제 값으로 교체합니다.

| 키 | 설명 |
|---|---|
| `ADMOB_REWARDED_ANDROID` | Android 리워드 광고 단위 ID |
| `ADMOB_REWARDED_IOS` | iOS 리워드 광고 단위 ID |

- Android App ID: `android/app/src/main/AndroidManifest.xml`
- iOS App ID: `ios/Runner/Info.plist`

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
