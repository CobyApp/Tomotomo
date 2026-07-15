# Legacy Services Removal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove StoreKit/IAP and unreachable Supabase/social/DM functionality while preserving the local Gemini tutor, Hive data, notebook widget, and rewarded-ad point flow.

**Architecture:** Collapse the point wallet to active spend, cache, and rewarded-ad operations. Simplify chat and character models to AI tutor conversations only. Regenerate Flutter and CocoaPods dependency metadata so native plugin registration matches the remaining code.

**Tech Stack:** Flutter, Dart, Hive CE, Provider, Google Generative AI, Google Mobile Ads, CocoaPods, Xcode

---

### Task 1: Protect the retained local point wallet behavior

**Files:**
- Modify: `test/data/repositories/local_points_repository_test.dart`
- Modify: `lib/domain/repositories/points_repository.dart`
- Modify: `lib/data/repositories/local_points_repository_impl.dart`

- [ ] Replace the IAP idempotency test with focused tests for the retained contract:
  - spending decreases balance;
  - insufficient spending preserves balance;
  - rewarded ads credit 30 points and enforce the daily limit.
- [ ] Run `flutter test test/data/repositories/local_points_repository_test.dart` and capture the baseline before deleting APIs.
- [ ] Remove `creditIapPoints`, `CreditIapPointsOutcome`, `tryUnlockDmExpression`, and `DmExpressionUnlockOutcome`.
- [ ] Remove Hive writes to `iap_tx` and `dm_unlocks`; leave existing on-device keys untouched.
- [ ] Run the focused point repository test again and require zero failures.

### Task 2: Make point earning rewarded-ad-only

**Files:**
- Modify: `lib/presentation/points/points_topup_screen.dart`
- Delete: `lib/presentation/points/points_topup_catalog.dart`
- Modify: `lib/presentation/points/points_topup_prompt.dart`
- Modify: `lib/presentation/points/points_usage_screen.dart`
- Modify: `lib/core/l10n/app_strings.dart`

- [ ] Remove `in_app_purchase`, product loading, purchase subscriptions, receipts, fallback prices, and purchase pack cards from `PointsTopUpScreen`.
- [ ] Keep `_watchAd`, daily remaining count, rewarded point feedback, and `_AdShimmerCard`.
- [ ] Replace duplicate “watch/buy” prompt actions with one point-earning action.
- [ ] Replace card/payment icons and purchase wording with rewarded-point wording. Japanese visible labels use `ポイントを獲得` and `広告を見る`.
- [ ] Remove purchase-only localization keys and update point help text to describe only active point costs and local storage.
- [ ] Run formatter and the point/widget tests.

### Task 3: Remove unreachable direct-message and social branches

**Files:**
- Modify: `lib/domain/entities/character.dart`
- Modify: `lib/presentation/chat/chat_screen.dart`
- Modify: `lib/presentation/chat/chat_viewmodel.dart`
- Modify: `lib/presentation/chat/chat_expression_sheet.dart`
- Modify: `lib/data/repositories/gemini_ai_repository_impl.dart`
- Modify: `lib/domain/repositories/ai_chat_repository.dart`
- Modify: `lib/domain/entities/chat_message.dart`
- Delete: `lib/domain/entities/block_relation.dart`
- Delete: `lib/domain/entities/friend_summary.dart`
- Delete: `lib/domain/entities/blocked_user_summary.dart`
- Delete: `lib/domain/entities/user_profile_search_result.dart`
- Delete: `lib/domain/entities/chat_room_summary.dart`

- [ ] Remove `Character.isDirectMessage`, `directMessageRoomId`, `forDirectMessage`, DM display branches, and obsolete Supabase naming comments/helpers.
- [ ] Remove no-op DM social state, banners, block/unblock menu actions, and DM-specific input restrictions from `ChatScreen`.
- [ ] Remove DM expression generation/unlock paths while retaining normal AI expression explanations and cache behavior.
- [ ] Remove unused social/domain entities after confirming no imports remain.
- [ ] Run `dart format lib test`, `flutter analyze`, and focused chat/entity tests; fix only errors caused by this removal.

### Task 4: Remove obsolete localization and documentation

**Files:**
- Modify: `lib/core/l10n/app_strings.dart`
- Modify: `lib/presentation/locale/locale_notifier.dart`
- Modify: `README.md`
- Modify: `SETTINGS.md`
- Delete: `docs/ARCHITECTURE.md`
- Delete: `docs/superpowers/plans/2026-07-13-local-offline-rewarded-ads.md`
- Delete: `docs/superpowers/specs/2026-07-13-local-offline-rewarded-ads-design.md`
- Delete: `supabase/migrations/20250320000000_full_schema.sql`
- Delete: `supabase/migrations/20250407120000_increment_public_character_download.sql`
- Delete: `supabase/migrations/20250408120000_points_and_expression_cache.sql`
- Delete: `supabase/migrations/20250409130000_characters_tagline.sql`
- Delete: `supabase/migrations/20250410120000_characters_cloned_from.sql`
- Delete: `supabase/migrations/20260408120000_chat_messages_line_translation.sql`
- Delete: `supabase/migrations/20260508002000_points_iap_topup.sql`

- [ ] Remove unreferenced authentication, friends, blocked-user, public-character, DM, IAP, and Supabase string keys from both locale maps.
- [ ] Remove Supabase-era comments and error guidance.
- [ ] Rewrite README and SETTINGS around local Hive data, Gemini configuration, AdMob configuration, iPhone profile execution, and signing.
- [ ] Delete obsolete backend migrations and plans that explicitly preserve removed IAP/Supabase behavior.
- [ ] Search the remaining docs and user-facing strings for `Supabase`, `in_app_purchase`, `StoreKit`, login/friend/block/DM references and resolve all stale matches.

### Task 5: Prune dependencies and native permissions

**Files:**
- Modify: `pubspec.yaml`
- Regenerate: `pubspec.lock`
- Regenerate: `ios/Podfile.lock`
- Modify: `ios/Runner/Info.plist`

- [ ] Remove `in_app_purchase`, `shared_preferences`, and `cupertino_icons`.
- [ ] Move `flutter_launcher_icons` from runtime dependencies to `dev_dependencies`.
- [ ] Remove unused microphone and speech recognition usage descriptions.
- [ ] Run `flutter pub get`.
- [ ] Run `pod install` from `ios/`.
- [ ] Confirm `in_app_purchase_storekit` is absent from both lockfiles and retained AdMob pods remain.

### Task 6: Full verification and device deployment

**Files:**
- Verify all modified files

- [ ] Run zero-match searches for removed package names, StoreKit purchase APIs, Supabase, deleted social entities, and removed repository methods.
- [ ] Run `dart format --output=none --set-exit-if-changed lib test`.
- [ ] Run `flutter analyze` and require no issues.
- [ ] Run `flutter test` and require all tests pass.
- [ ] Run `./run_on_iphone.sh -d 00008150-000965982680401C`.
- [ ] Confirm the profile build installs and launches on Coby.
- [ ] Inspect launch output for absence of `SKPaymentQueue` initialization errors and confirm rewarded-ad initialization remains available.

No git commit is included because the user did not request one.
