# 토모토모 — 설정 가이드

앱 실행/빌드에 필요한 설정 파일과 키 목록입니다. 저장소에는 예시 파일만 포함되어 있으므로, 로컬에서 복사 후 값을 채워 사용하세요.

---

## 1. `.env` (필수 — 앱 실행)

**위치**: 프로젝트 루트  
**예시 파일**: `.env.example`

| 키 | 설명 | 발급/설정 |
|----|------|------------|
| `GEMINI_API_KEY` | Google Gemini API 키 (필수). | [Google AI Studio](https://aistudio.google.com/apikey) 등 |
| `GEMINI_MODEL` | 모델 ID (앱 기본값 `gemini-2.5-flash-lite`). | [공식 가격](https://ai.google.dev/gemini-api/docs/pricing) 기준 텍스트 Standard 요금은 보통 `gemini-2.5-flash-lite`가 가장 낮고, 그다음 `gemini-3.1-flash-lite-preview`, `gemini-2.5-flash` 순입니다. **2.0 계열은 [deprecated](https://ai.google.dev/gemini-api/docs/deprecations)** 예정입니다. |
| `GEMINI_TEMPERATURE` / `GEMINI_MAX_OUTPUT_TOKENS` | 선택. 미설정 시 앱 기본값 `0.2` / `512` (짧은 JSON 위주로 응답을 빨리 끝내기). | JSON이 잘리면 `768`~`1024` 등으로 올리기 |
| `GEMINI_MAX_CHAT_CONTENTS` | 선택. 한 번의 API 요청에 포함하는 최근 대화 [Content] 개수(기본 `24`). | 채팅이 길수록 값을 `16` 등으로 줄이면 요청이 가벼워져 체감 속도에 도움이 될 수 있음 |
| `SUPABASE_URL` | Supabase 프로젝트 URL. 회원/캐릭터/채팅 등에 사용됩니다. | [Supabase](https://supabase.com) 프로젝트 설정 > API |
| `SUPABASE_PUBLISHABLE_KEY` | Supabase Publishable 키 (클라이언트용, RLS 적용). Legacy anon 키 대신 사용. | Settings > API > **Publishable and secret API keys** 탭 |

### 이메일 인증(컨펌) 없이 바로 로그인하게 하기

앱 코드로 “무조건 컨펌 생략”을 강제할 수는 없고, **Supabase 프로젝트 설정**에서 끕니다.

1. [Supabase Dashboard](https://supabase.com/dashboard) → 본인 프로젝트(**tomotomo**) 선택  
2. 왼쪽 **Authentication** (또는 **Auth**) 메뉴로 이동  
3. **Providers** → **Email** (이메일 제공자 설정)  
4. **Confirm email** / **Enable email confirmations** / **이메일 확인 필요** 에 해당하는 옵션을 **끔(OFF)**  
5. 변경 사항 **저장**

이후 새로 가입하는 계정은 **메일 링크 없이** 곧바로 세션이 잡히고 앱에 로그인된 상태로 들어갈 수 있습니다.

**이미 “미확인” 상태로만 만들어진 계정**은  
**Authentication → Users**에서 해당 사용자를 선택한 뒤 **Confirm user**(확인 처리) 하거나, 테스트용으로 **삭제 후 다시 가입**하면 됩니다.

> 프로덕션 서비스에서는 스팸·가짜 계정 방지를 위해 이메일 확인을 켜 두는 경우가 많습니다. 개발·테스트 단계에서만 끄는 것을 권장합니다.

**Supabase DB·Storage·Realtime**은 `supabase/migrations/20250320000000_full_schema.sql` 한 파일에 모아 두었습니다. `supabase db push`로 적용하거나, 파일 전체를 대시보드 **SQL Editor**에서 한 번 실행하면 됩니다 (`avatars`, `backgrounds`, `dm_voice` 버킷, RPC, Realtime publication 포함).

**사용법**
```bash
cp .env.example .env
# .env 파일을 열어 GEMINI_API_KEY, GEMINI_MODEL 등을 본인 환경에 맞게 수정
```

`.env`는 `.gitignore`에 포함되어 있어 저장소에 올라가지 않습니다.

### Supabase SQL 적용 (신규 프로젝트)

1. `supabase/migrations/20250320000000_full_schema.sql` 한 번 적용 (`supabase db push` 또는 SQL Editor 전체 실행).  
2. 이미 예전 분할 마이그레이션으로 DB를 만든 프로젝트는 **이 파일을 다시 실행하지 마세요** (객체 중복). 스키마를 맞추려면 새 프로젝트로 옮기거나 수동으로 정리해야 합니다.

이 스키마를 적용하면 **인증·캐릭터·AI 채팅·친구·DM·차단·단어장·Storage·채팅 Realtime**까지 앱이 기대하는 백엔드가 갖춰집니다.

#### 로그인/가입 시 `Failed host lookup: '…supabase.co'`

- **의미**: 휴대폰이 해당 Supabase 주소를 DNS로 찾지 못한 것입니다. 비밀번호 문제가 아닙니다.
- **할 일**
  1. Safari 등에서 `https://(프로젝트참조).supabase.co` 가 열리는지 확인 (안 열리면 URL 오타 또는 프로젝트 삭제/정지).
  2. `.env`의 `SUPABASE_URL`을 Supabase **Settings → API → Project URL**에서 **다시 복사**해 붙이기 (앞뒤 공백·한 글자 오타 없이).
  3. Wi‑Fi/셀룰러·VPN·iOS 시뮬레이터 네트워크 재시도.

`.env` 수정 후에는 앱을 **완전히 종료했다가 다시 실행**해야 `flutter_dotenv`가 다시 읽습니다.

#### AI 응답이 느릴 때 (Gemini)

- **원인**: 휴대폰 → Google API 왕복(네트워크) + 모델 추론 시간. 앱이 “느리다”고 느끼는 대부분은 이 구간입니다.
- **모델**: 기본이 `gemini-2.5-flash-lite`입니다. 품질이 아쉽으면 `gemini-2.5-flash` 등으로 올려 보세요 ([가격표](https://ai.google.dev/gemini-api/docs/pricing)).
- **대화 길이**: 앱은 최근 턴만내도록 제한합니다. 그래도 느리면 `GEMINI_MAX_CHAT_CONTENTS=16` 처럼 줄여 보세요.
- **저장**: 답변이 나온 뒤 Supabase에 메시지를 저장하는 단계는 보통 수백 ms 수준이며, 체감 지연의 대부분은 API 응답 전까지입니다.

#### 가입만 실패할 때 (연결은 됨)

- **이미 가입된 이메일** → 로그인으로 시도.
- **Authentication → Providers → Email** 에서 가입/로그인이 켜져 있는지 확인.
- **Authentication → Sign up** 관련 옵션(예: Confirm email)을 켠 경우, 가입 후 메일함에서 링크 확인.
- 앱에 표시되는 **빨간 안내 문구 전체**를 보면 Supabase가 준 이유(영문)가 아래에 붙을 수 있습니다.

---

## 2. `android/key.properties` (Android 릴리즈 빌드 시만)

**위치**: `android/key.properties`  
**예시 파일**: `android/key.properties.example`

| 키 | 설명 |
|----|------|
| `storeFile` | 업로드용 키스토어 파일 경로 (예: `../upload-keystore.jks`) |
| `storePassword` | 키스토어 비밀번호 |
| `keyAlias` | 키 별칭 (예: `upload`) |
| `keyPassword` | 키 비밀번호 |

**사용법**
```bash
cp android/key.properties.example android/key.properties
# key.properties 를 열어 실제 경로·비밀번호로 수정
```

릴리즈 빌드(`flutter build appbundle` 등)할 때만 필요합니다. 디버그 실행에는 필요 없습니다.  
`key.properties`는 버전 관리에 넣지 않는 것을 권장합니다 (필요 시 `.gitignore`에 `android/key.properties` 추가).

---

## iOS: `flutter clean` 뒤 `pod install`이 실패할 때

`flutter clean` 은 `ios/Flutter/Generated.xcconfig` 를 지웁니다. 그 상태에서 `cd ios && pod install` 만 하면 Podfile이 실패합니다.

**올바른 순서 예:**

```bash
flutter clean && flutter pub get && (cd ios && pod install && cd ..) && flutter run
```

`flutter run` / `flutter build ios` 는 보통 `pub get` 과 `pod install` 을 알아서 호출하므로, 수동으로 `pod install` 할 때만 `flutter pub get` 을 먼저 두면 됩니다.

### 실기기 설치 실패: `objective_c.framework` / `0xe8008014` (invalid signature)

Xcode / `flutter run` 으로 설치할 때 **`Failed to verify code signature of …/objective_c.framework`**, **`MIInstallerErrorDomain Code 13`**, **`0xe8008014`** 가 나오면 Flutter가 넣은 **엔진 프레임워크 서명**이 깨진 상태입니다.

**이 저장소에서 한 조치:** Runner 타깃 빌드 단계 순서를 바로잡았습니다. **`Thin Binary`** (`xcode_backend.sh embed_and_thin`) 가 **`[CP] Copy Pods Resources` 보다 반드시 나중**에 실행되어야 최종 `.app` 이 올바르게 얇아지고 서명이 맞습니다. (이전에는 Pods 리소스 복사가 그 뒤에 와서 번들이 꼬일 수 있었습니다.)

**직접 할 일:**

1. `flutter clean` 후 `rm -rf build/ios` (선택)  
2. `flutter pub get` → `cd ios && pod install`  
3. Xcode에서 **Product → Clean Build Folder**  
4. 다시 **`flutter run`** 또는 Xcode에서 Run (팀/번들 ID 그대로)

이전에 **`flutter build ios --no-codesign`** 으로 만든 `build/ios/iphoneos/Runner.app` 을 기기에 올리면 동일 오류가 날 수 있으므로, 실기기에는 **항상 정상 서명된 빌드**로 설치하세요.

### 실기기에서 `EXC_BAD_ACCESS` (debug) / VM Service 타임아웃

#### iOS 26 + 실기기 + `flutter run`(debug) = 알려진 조합 문제

**증상:** `EXC_BAD_ACCESS (code=50)`, fault 주소가 매번 다름, 심볼 없는 JIT 영역, 또는 **`The Dart VM Service was not discovered after 60 seconds`** (앱이 뜨기 전에 죽거나 디버거 연결 전에 종료).

**원인:** Apple 쪽 **JIT 메모리 페이지 정책**과 Flutter **디버그 모드의 JIT** 가 충돌하는 이슈로 보는 것이 타당합니다. ([Flutter #184533](https://github.com/flutter/flutter/issues/184533) — `code=50`, `ldur x6, [x24, #0x37]` 등; 실제로는 `tbz` / `ldur x9, [x0, #-0x1]` 같은 **다른 JIT 패턴**으로도 동일 계열 크래시가 날 수 있음.) **앱 비즈니스 코드 버그라기보다 툴체인·OS 조합 이슈**에 가깝습니다.

**실기기에서 권장하는 실행 방법 (가장 중요)**

| 목적 | 명령 / 방법 |
|------|-------------|
| **실기기에서 매일 돌리기** | **`./run_on_iphone.sh`** 또는 **`make ios`** 또는 **`flutter run --profile`** (AOT — 안정적) |
| 출시에 가깝게 확인 | `flutter run --release` |
| 브레이크포인트·핫 리로드 디버그 | **iOS 시뮬레이터**에서 `flutter run` (debug) |
| Cursor/VS Code | **실행 구성**에서 **「Tomotomo (profile — iOS 실기기 권장)」** 선택 (`.vscode/launch.json`) |

> 터미널에서 습관적으로 **`flutter run`** 만 치면 **항상 debug** 라서 실기기에서는 같은 크래시가 납니다. 실기기면 **`make ios`** 로 통일하는 것을 권장합니다.

**이미 해둔 완화 (완전 해결은 아님)**

- Debug 전용 `RunnerDebug.entitlements` 에 **`com.apple.security.cs.allow-jit`** — 이슈에서도 **빈도만 줄일 수 있고 재현을 없애지는 못한다**고 함.

**추가로**

- 주기적으로 **`flutter upgrade`** (stable) — 엔진/도구 수정이 올라올 수 있음.

#### 그 밖에 시도해 둔 앱/프로젝트 안정화 (요약)

- **iOS 임베딩**: `UIApplicationSceneManifest` 없이 **`UIMainStoryboardFile` = Main** + `AppDelegate`에서 `GeneratedPluginRegistrant.register(with: self)` 만 사용 (레거시 단일 윈도 경로).
- **Pods**: `use_frameworks! :linkage => :static`.
- **Impeller 끔**: `Info.plist` 의 `FLTEnableImpeller` = false.
- **UI**: 로그인 타이틀은 셰이더 없이 단색만; 전역 테마는 `InkSparkle` 대신 `InkRipple`(스파클 셰이더가 iOS에서 크래시 보고됨); iOS 에서 하단 `BackdropFilter` 블러 생략.
- **`home_widget` / 첫 프레임**: 네이티브 부하는 스케줄러 프레임 기준으로 늦춤 (`lib/core/platform/ios_post_layout_frames.dart`).

Apple이 UIScene 강제하기 전까지는 위 레거시 경로가 실기기 안정성에 유리한 경우가 많습니다.

---

## 요약

| 용도 | 필요한 설정 |
|------|-------------|
| 로컬 실행 (iOS/Android 디버그) | `.env` 에 `GEMINI_API_KEY`, `GEMINI_MODEL`(선택), `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` 설정 |
| Android 릴리즈 빌드 | `.env` + `android/key.properties` |
| iOS 릴리즈 빌드 | `.env` (Xcode 서명은 Xcode에서 설정) |

광고는 제거된 상태이므로 별도의 광고 키/설정은 없습니다.
