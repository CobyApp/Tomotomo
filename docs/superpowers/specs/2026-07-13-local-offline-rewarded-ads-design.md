# Design: Local Offline Migration + Rewarded-Ad Points

**Date:** 2026-07-13
**Status:** Approved (pending written-spec review)

## Summary

Convert Tomotomo from a Supabase-backed social app into a **single-user,
offline-first AI Japanese tutor app**. Remove the backend entirely. Keep AI
character chat, X/link persona import, and the word book. Replace the
server-backed point wallet with a **local wallet**, and let users **earn points
by watching full-screen rewarded ads** (AdMob) in addition to IAP top-up.

## Goals

- No backend. App runs fully offline except for two direct third-party HTTP
  calls it already makes: Gemini API (chat + persona) and the Jina reader proxy
  (X profile scraping).
- Keep: AI chat, custom character creation, **X/link → character import**, word
  book, saved expressions, themes, home widget.
- Points wallet becomes local; earn via rewarded ads (+ existing IAP top-up).
- Drop everything that physically requires a server.

## Non-Goals / Explicitly Dropped

Removing the backend makes these impossible; they are deleted, not ported:

- Authentication / accounts (login, signup, `AuthGate`)
- Friends, friend search, friends tab
- User-to-user DM + realtime chat (`supabase_chat_repository`)
- Public tutor **Discover**, public character forks, download-count RPC
- Server profile (server-side avatar upload, cross-device sync)
- Server anti-cheat for points (see Trade-offs)

No data migration from Supabase — fresh local start.

## Accepted Trade-offs

- **Points are local-only.** Balance, spend records, and the ad daily-cap live
  on-device. Reinstall resets them; a rooted/jailbroken device can tamper. This
  is acceptable for a personal learning app. A lightweight serverless verifier
  can be bolted on later if abuse appears.
- **No cloud backup.** Losing/replacing the device loses local data.

## Architecture

### Persistence: Hive

Use `hive_ce` + `hive_ce_flutter` (maintained community fork). Boxes:

| Box | Contents |
|-----|----------|
| `characters` | User's tutor characters (incl. X-imported), avatar path/URL |
| `chats` | Chat rooms + messages, keyed by room id |
| `wordbook` | Saved expressions / vocabulary |
| `points` | Balance, spend log, processed IAP tx ids, ad daily-cap counter |
| `settings` | App language, theme, local nickname/avatar, misc prefs |

Repositories keep their existing **domain interfaces** where possible; only the
`*_impl.dart` classes swap Supabase calls for Hive reads/writes. This keeps the
presentation layer largely untouched.

### Removed dependencies / files

- `supabase_flutter` removed from `pubspec.yaml`.
- Delete `lib/core/supabase/app_supabase.dart`, `lib/core/storage/character_storage.dart`
  (server upload), `supabase_chat_repository.dart`, `friends_*`, `auth/`,
  and Discover/public-character code paths.
- Env: drop `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`. Keep `GEMINI_*`.

### Navigation / shell

Tabs reduce to: **My Tutors** · **Chats** · **Word Book** · **Settings**.
(Friends and Discover tabs removed.) App launches straight into the shell — no
auth gate.

### X / link persona import (KEPT)

`XProfileReader` (Jina `r.jina.ai`, no key) + `CelebrityPersonaSuggester`
(Gemini) are already client-only. Change only the **sink**: the suggested
character is saved to the local `characters` box instead of the server
`characters` table. Avatar handling:

- X-imported avatar: use the `pbs.twimg.com` URL directly (network image).
- User-picked image (`image_picker`): copy into the app documents directory and
  store the local file path (replaces Supabase Storage upload).

## Feature: Local Points Wallet (Phase 2)

- Balance stored in `points` box; a `PointsService`/local repo replaces the
  Supabase RPCs (`spend_points`, `credit_iap_points`, `try_unlock_dm_expression`).
- Existing spend rules preserved (e.g. DM learning-sheet unlock = 1 pt, charged
  once per message — tracked locally by message id).
- IAP top-up (`in_app_purchase`) retained; on a verified purchase, credit points
  locally and record the store transaction id in `points` box to stay
  idempotent (no double-credit on restore/replay).
- `PointsBalanceNotifier` reads the local balance; the app-bar chip is unchanged.

## Feature: Rewarded-Ad Earning (Phase 3) ⭐

- Add `google_mobile_ads`; initialize in `main()`.
- `RewardedAdService`: preload a rewarded ad, expose `showAndEarn()`. On the
  SDK's `onUserEarnedReward` callback, credit points via the local wallet.
- **Economy:** +30 pt per completed ad; **max 5 ads/day** (150 pt/day).
- **Daily cap:** counter + date stored in `points` box, resets at local midnight.
  When the cap is hit, the earn button is disabled with a "come back tomorrow"
  message.
- **UI entry points:**
  - `PointsTopUpScreen`: an "Watch ad to earn points" row above the IAP packs,
    showing remaining ads today.
  - `points_topup_prompt` (out-of-points prompt): a "watch ad" option alongside
    "top up".
- **Config (Android manifest + iOS Info.plist):** AdMob App ID. iOS also needs
  SKAdNetwork identifiers and (recommended) an App Tracking Transparency prompt.
- **Ad unit ids:** read from env/config; default to Google's public **test unit
  ids** in debug so development needs no real AdMob account. Real ids swapped in
  for release.

## Required from the user (API keys / setup)

| Item | Needed | When |
|------|--------|------|
| AdMob **App ID** (Android + iOS) | New — from AdMob console | Before release |
| AdMob **Rewarded ad unit ID** (Android + iOS) | New — from AdMob console | Before release |
| Gemini API key | Already present | — |
| Supabase keys | Removed | — |

Development can start immediately using Google's public test ad unit ids.

## Phased Delivery

1. **Phase 1 — Backend removal & local persistence.** Add Hive; remove Supabase
   and the dropped features; port characters/chat/wordbook/theme/settings repos
   to Hive; rebuild tabs; keep X import → local. Exit: app builds, runs offline,
   chat + character creation (incl. X import) + word book work.
2. **Phase 2 — Local points wallet.** Local balance, spend rules, IAP credit
   local + idempotent. Exit: spend/top-up flows work offline.
3. **Phase 3 — Rewarded ads.** AdMob integration, earn flow, daily cap, UI entry
   points. Exit: watch (test) ad → +30 pt, cap enforced at 5/day.

## Testing

- Repo unit tests for Hive-backed characters/wordbook/points (spend, credit
  idempotency, daily-cap reset across a date boundary).
- Manual/integration: cold start offline → chat; X import → character saved;
  earn flow with test ad unit; cap enforcement.

## Verification (per CLAUDE-style gate)

Per phase: `flutter analyze`, `flutter test`, and a debug build/run on a
simulator to exercise the changed flow before marking the phase done.
