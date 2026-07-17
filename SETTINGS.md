# 토모토모 설정 가이드

현재 앱은 Hive 기반 로컬 앱입니다. 별도 로그인이나 원격 데이터베이스 설정은 필요하지 않습니다.

## 환경 변수

프로젝트 루트에서 예시 파일을 복사합니다.

```bash
cp .env.example .env
```

### 온디바이스 AI

AI용 환경 변수나 API 키는 필요하지 않습니다. 최초 실행에서 Gemma 4 E2B 모델(2.59GB)을 설치하며, 설치 파일은 고정 리비전·파일 크기·SHA-256으로 검증합니다. 설치 뒤 캐릭터 채팅, 표현 분석, X 페르소나 생성은 LiteRT-LM을 통해 기기 안에서 실행됩니다.

- Android: API 24 이상, ARM64 기기
- iOS: iOS 16 이상, ARM64 기기
- GPU를 우선 사용하고 사용할 수 없으면 CPU로 폴백합니다.
- 설정의 `온디바이스 AI 모델`에서 모델을 삭제하거나 다시 설치할 수 있습니다.
- 모델 다운로드, X 공개 프로필 가져오기, 리워드 광고에는 네트워크가 필요합니다.

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
