# 토모토모 — 설정 가이드

앱 실행/빌드에 필요한 설정 파일과 키 목록입니다. 저장소에는 예시 파일만 포함되어 있으므로, 로컬에서 복사 후 값을 채워 사용하세요.

---

## 1. `.env` (필수 — 앱 실행)

**위치**: 프로젝트 루트  
**예시 파일**: `.env.example`

| 키 | 설명 | 발급/설정 |
|----|------|------------|
| `GEMINI_API_KEY` | Google Gemini API 키. AI 채팅에 사용됩니다. | [Google AI Studio](https://aistudio.google.com/apikey)에서 발급 |

**사용법**
```bash
cp .env.example .env
# .env 파일을 열어 GEMINI_API_KEY= 실제_키_값 으로 수정
```

`.env`는 `.gitignore`에 포함되어 있어 저장소에 올라가지 않습니다.

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

## 요약

| 용도 | 필요한 설정 |
|------|-------------|
| 로컬 실행 (iOS/Android 디버그) | `.env` 에 `GEMINI_API_KEY` 설정 |
| Android 릴리즈 빌드 | `.env` + `android/key.properties` |
| iOS 릴리즈 빌드 | `.env` (Xcode 서명은 Xcode에서 설정) |

광고는 제거된 상태이므로 별도의 광고 키/설정은 없습니다.
