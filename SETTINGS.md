# 토모토모 — 설정 가이드

앱 실행/빌드에 필요한 설정 파일과 키 목록입니다. 저장소에는 예시 파일만 포함되어 있으므로, 로컬에서 복사 후 값을 채워 사용하세요.

---

## 1. `.env` (필수 — 앱 실행)

**위치**: 프로젝트 루트  
**예시 파일**: `.env.example`

| 키 | 설명 | 발급/설정 |
|----|------|------------|
| `OLLAMA_BASE_URL` | Ollama 호환 API 베이스 URL (예: `http://taba.asia:11434`). 끝의 `/`는 생략 가능. | 본인 서버 또는 로컬 Ollama |
| `OLLAMA_MODEL` | 사용할 모델 태그 (예: `gemma4:e2b`). | `ollama list` 등으로 확인 |
| `OLLAMA_NUM_CTX` / `OLLAMA_NUM_PREDICT` / `OLLAMA_TEMPERATURE` | 선택. 미설정 시 앱 기본값은 **속도 우선**(`2048` / `512` / `0.15`). | 답·JSON이 잘리면 `OLLAMA_NUM_PREDICT`를 `768`~`1024` 등으로, 대화 맥락이 부족하면 `OLLAMA_NUM_CTX`를 `4096` 등으로 올리면 됨 (서버·GPU 한도 내) |
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
# .env 파일을 열어 OLLAMA_BASE_URL, OLLAMA_MODEL 등을 본인 환경에 맞게 수정
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

### 실기기에서 `EXC_BAD_ACCESS` (debug) 가 날 때

프로젝트에서 시도해 둔 안정화 (요약):

- **iOS 임베딩**: `UIApplicationSceneManifest` 없이 **`UIMainStoryboardFile` = Main** + `AppDelegate`에서 `GeneratedPluginRegistrant.register(with: self)` 만 사용 (레거시 단일 윈도 경로).
- **Pods**: `use_frameworks! :linkage => :static`.
- **Impeller 끔**: `Info.plist` 의 `FLTEnableImpeller` = false.
- **UI**: 로그인 타이틀은 셰이더 없이 단색만; 전역 테마는 `InkSparkle` 대신 `InkRipple`(스파클 셰이더가 iOS에서 크래시 보고됨); iOS 에서 하단 `BackdropFilter` 블러 생략.
- **`home_widget`**: `setAppGroupId` 는 첫 프레임 이후(`App`의 `addPostFrameCallback`).

그래도 동일하면 **`flutter run --profile`** / **`flutter run --release`** 로 비교하세요. Apple이 UIScene 강제하기 전까지는 위 레거시 경로가 실기기 안정성에 유리한 경우가 많습니다.

---

## 요약

| 용도 | 필요한 설정 |
|------|-------------|
| 로컬 실행 (iOS/Android 디버그) | `.env` 에 `OLLAMA_BASE_URL`, `OLLAMA_MODEL`(선택), `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` 설정 |
| Android 릴리즈 빌드 | `.env` + `android/key.properties` |
| iOS 릴리즈 빌드 | `.env` (Xcode 서명은 Xcode에서 설정) |

광고는 제거된 상태이므로 별도의 광고 키/설정은 없습니다.
