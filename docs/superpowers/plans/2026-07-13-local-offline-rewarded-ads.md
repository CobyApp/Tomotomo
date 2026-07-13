# Local Offline Migration + Rewarded-Ad Points Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert Tomotomo from a Supabase-backed social app into a single-user offline AI Japanese tutor app whose point wallet is local and can be topped up by watching rewarded ads.

**Architecture:** Remove `supabase_flutter` entirely. Persist all data in Hive boxes behind the existing domain repository interfaces (only the `*_impl` classes change). Delete server-only features (auth, friends, DM, Discover). Keep X/link persona import, retargeted to save characters locally. Points become a local Hive-backed wallet; rewarded ads (AdMob) and IAP both credit it.

**Tech Stack:** Flutter, Hive (`hive_ce`, `hive_ce_flutter`), `google_generative_ai` (kept), `in_app_purchase` (kept), `google_mobile_ads` (new), Provider.

**Reference spec:** `docs/superpowers/specs/2026-07-13-local-offline-rewarded-ads-design.md`

---

## File Structure

**New:**
- `lib/core/local/hive_boxes.dart` — box-name constants + `openAllBoxes()` init.
- `lib/data/local/local_json_store.dart` — thin typed helper over a Hive box (get/put/list/delete JSON maps).
- `lib/data/repositories/local_points_repository_impl.dart` — Phase 2.
- `lib/core/ads/rewarded_ad_service.dart` — Phase 3.
- `lib/core/ads/ad_config.dart` — Phase 3 (unit ids + economy constants).

**Modified:** `lib/main.dart`, `lib/app.dart`, `lib/core/di/injection.dart`, `pubspec.yaml`, `.env` / `.env.example`, all `lib/data/repositories/*_impl.dart` that used Supabase, `lib/presentation/main_shell/*`, `lib/presentation/points/*`.

**Deleted:** `lib/core/supabase/`, `lib/core/storage/character_storage.dart`, `lib/data/repositories/supabase_chat_repository.dart`, `lib/data/repositories/friends_repository_impl.dart`, `lib/domain/repositories/friends_repository.dart`, `lib/presentation/auth/`, `lib/presentation/friends/`, and Discover/public-character screens (`lib/presentation/tutor_studio/public_character_sheet.dart`, `lib/presentation/main_shell/tabs/add_friend_tab.dart`, `friends_tab.dart`).

---

# PHASE 1 — Backend removal & local persistence

**Exit criteria:** app builds with no `supabase` import remaining, launches straight into the shell (no login), AI chat works, creating a character (manual + X import) persists locally and survives restart, word book works. `flutter analyze` clean, `flutter test` green.

## Task 1.1: Add Hive, remove Supabase from pubspec

**Files:** Modify `pubspec.yaml`

- [ ] **Step 1: Edit dependencies**

In `pubspec.yaml` under `dependencies:` remove the `supabase_flutter: ^2.12.2` line and add:

```yaml
  hive_ce: ^2.10.0
  hive_ce_flutter: ^2.2.0
  path_provider: ^2.1.4
```

- [ ] **Step 2: Resolve**

Run: `flutter pub get`
Expected: resolves without error; `supabase_flutter` no longer in `pubspec.lock`.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add hive, drop supabase_flutter dependency"
```

## Task 1.2: Hive box registry + init

**Files:** Create `lib/core/local/hive_boxes.dart`; Test `test/core/local/hive_boxes_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:tomotomo/core/local/hive_boxes.dart';

void main() {
  setUp(() => Hive.init('./.dart_tool/hive_test_1_2'));
  tearDown(() async => Hive.deleteFromDisk());

  test('openAllBoxes opens every declared box', () async {
    await openAllBoxes();
    for (final name in HiveBoxes.all) {
      expect(Hive.isBoxOpen(name), isTrue, reason: name);
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/local/hive_boxes_test.dart`
Expected: FAIL — `hive_boxes.dart` does not exist.

- [ ] **Step 3: Write implementation**

```dart
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Central registry of Hive box names + one-shot opener. All app data lives here.
class HiveBoxes {
  static const characters = 'characters';
  static const chats = 'chats';
  static const wordbook = 'wordbook';
  static const points = 'points';
  static const settings = 'settings';

  static const List<String> all = [characters, chats, wordbook, points, settings];
}

/// Opens every box as an untyped `Box` of JSON-serializable values.
Future<void> openAllBoxes() async {
  for (final name in HiveBoxes.all) {
    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox<dynamic>(name);
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/local/hive_boxes_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/local/hive_boxes.dart test/core/local/hive_boxes_test.dart
git commit -m "feat: add hive box registry and opener"
```

## Task 1.3: LocalJsonStore helper

**Files:** Create `lib/data/local/local_json_store.dart`; Test `test/data/local/local_json_store_test.dart`

This is the shared persistence primitive every local repo uses: a box holds a
list of JSON maps under one key, or keyed single objects. Keeps repos DRY.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:tomotomo/data/local/local_json_store.dart';

void main() {
  late Box box;
  setUp(() async {
    Hive.init('./.dart_tool/hive_test_1_3');
    box = await Hive.openBox('t');
  });
  tearDown(() async => Hive.deleteFromDisk());

  test('putItem/listItems round-trips by id', () async {
    final store = LocalJsonStore(box);
    await store.putItem('a', {'id': 'a', 'name': 'x'});
    await store.putItem('b', {'id': 'b', 'name': 'y'});
    final all = store.listItems();
    expect(all.length, 2);
    expect(store.getItem('a')!['name'], 'x');
    await store.deleteItem('a');
    expect(store.getItem('a'), isNull);
  });

  test('putValue/getValue for scalar settings', () async {
    final store = LocalJsonStore(box);
    await store.putValue('lang', 'ja');
    expect(store.getValue('lang'), 'ja');
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/data/local/local_json_store_test.dart`
Expected: FAIL — file missing.

- [ ] **Step 3: Write implementation**

```dart
import 'package:hive_ce/hive.dart';

/// Typed helpers over one Hive [Box]. Item maps are stored under their own key;
/// [listItems] returns every map value in the box (skips scalar settings keys).
class LocalJsonStore {
  LocalJsonStore(this._box);
  final Box _box;

  Future<void> putItem(String id, Map<String, dynamic> json) =>
      _box.put(id, Map<String, dynamic>.from(json));

  Map<String, dynamic>? getItem(String id) {
    final v = _box.get(id);
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  List<Map<String, dynamic>> listItems() {
    return _box.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> deleteItem(String id) => _box.delete(id);

  Future<void> putValue(String key, Object? value) => _box.put(key, value);
  Object? getValue(String key) => _box.get(key);
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/data/local/local_json_store_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/local/local_json_store.dart test/data/local/local_json_store_test.dart
git commit -m "feat: add LocalJsonStore hive helper"
```

## Task 1.4: Rewrite `main.dart` — drop Supabase, init Hive

**Files:** Modify `lib/main.dart`

- [ ] **Step 1: Replace file contents**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/local/hive_boxes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Hive.initFlutter();
  await openAllBoxes();

  setupInjection();

  runApp(const App());
}
```

- [ ] **Step 2: Verify no supabase import**

Run: `grep -rn "supabase" lib/main.dart`
Expected: no output.

- [ ] **Step 3: Commit** (will not build until DI is fixed in 1.5; commit anyway as a checkpoint)

```bash
git add lib/main.dart
git commit -m "refactor: init hive instead of supabase in main"
```

## Task 1.5: Port repositories to Hive (per-file)

Each repository keeps its **domain interface unchanged**; only the `_impl`
swaps `AppSupabase.client...` for a `LocalJsonStore` over the right box. The
pattern for every file:

1. Read the current `_impl.dart` and its domain interface.
2. Delete the `import '../../core/supabase/app_supabase.dart';` line.
3. Add `import '../local/local_json_store.dart';` and `import 'package:hive_ce/hive.dart';`.
4. Replace each method body: server `select` → `store.listItems()` / `getItem`; `insert`/`upsert`/`update` → `putItem`; `delete` → `deleteItem`; RPCs → local logic. Drop any `owner_id`/`tenant`/auth filters (single local user).
5. Map existing entity `fromJson`/`toJson` (already present) to the stored maps.

Do these sub-tasks **one commit each**, each with a repo unit test that opens a temp box, writes via the impl, reads it back.

- [ ] **1.5a `theme_repository_impl.dart`** → `settings` box (`putValue('theme', ...)`). Test: save theme, read back.
- [ ] **1.5b `saved_expression_repository_impl.dart`** → `wordbook` box (`putItem`/`listItems`/`deleteItem`). Test: add expression, list, delete.
- [ ] **1.5c `character_record_repository_impl.dart`** → `characters` box. Keep `getMyCharacters` returning `listItems()` mapped to `CharacterRecord`; **delete** `getPublicCharacters`/`searchAccessibleCharacters`/download-count from the interface and impl (server-only). Test: save character, list, delete.
- [ ] **1.5d chat persistence** → `chats` box. Replace `SupabaseChatRepository` with `LocalChatRepository` implementing the same `ChatRepository` interface (rooms + messages stored as JSON lists keyed by room id). Update DI + delete `supabase_chat_repository.dart`. Test: append message to room, read history.
- [ ] **1.5e `profile_repository_impl.dart`** → collapse to a `settings`-box-backed local profile: `appLanguage`, `learningLanguage`, local `displayName`/`avatarPath`. `pointBalance` MOVES to the points repo in Phase 2 — for Phase 1 keep a temporary `getPointBalance()` reading `settings`. Test: set/get app language.

For each sub-task, the commit:

```bash
git add lib/data/repositories/<file> test/data/repositories/<test>
git commit -m "refactor: port <name> repository to hive"
```

## Task 1.6: Delete server-only features + fix DI/app

**Files:** Modify `lib/core/di/injection.dart`, `lib/app.dart`; Delete auth/friends/discover.

- [ ] **Step 1: Delete files**

```bash
git rm -r lib/presentation/auth lib/presentation/friends \
  lib/data/repositories/friends_repository_impl.dart \
  lib/domain/repositories/friends_repository.dart \
  lib/core/supabase lib/core/storage/character_storage.dart \
  lib/presentation/main_shell/tabs/add_friend_tab.dart \
  lib/presentation/main_shell/tabs/friends_tab.dart \
  lib/presentation/tutor_studio/public_character_sheet.dart
```

- [ ] **Step 2: Rewrite `injection.dart`**

Remove `chatRepository = SupabaseChatRepository()` → `LocalChatRepository()`;
remove all `friends` lines and the `friendsRepository` global; keep
`pointsRepository`, `aiChatRepository`, `profileRepository`,
`characterRecordRepository`, `themeRepository`, `savedExpressionRepository`,
`celebrityPersonaSuggester`. Delete the `friends_repository` imports.

- [ ] **Step 3: Rewrite `app.dart`**

Remove the `AppAuthState` provider, the `FriendsRepository` provider, and the
`auth/*` imports. Change `home: const AuthGate()` → `home: const MainShell()`
(import `presentation/main_shell/main_shell.dart`). Keep `PointsBalanceNotifier`
but change its constructor arg per Phase 2 (Phase 1: keep reading balance from
`profileRepository.getPointBalance()`).

- [ ] **Step 4: Verify build**

Run: `flutter analyze`
Expected: no errors (fix any dangling references the deletions surfaced — e.g. tabs that imported friends).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: remove auth/friends/discover, wire local shell"
```

## Task 1.7: Rebuild main shell tabs

**Files:** Modify `lib/presentation/main_shell/main_shell.dart`, `tabs/*`

- [ ] **Step 1:** Reduce the tab list/nav bar to 4: My Tutors (`characters_tab`), Chats (`chats_tab`), Word Book (word book screen), Settings (`settings_tab`). Remove friends/discover tab entries and any nav index referencing them.
- [ ] **Step 2:** In `settings_tab.dart` remove logout / account rows (no auth). Keep language, theme, points top-up entry.
- [ ] **Step 3:** Verify.

Run: `flutter analyze`
Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: 4-tab local shell (tutors/chats/wordbook/settings)"
```

## Task 1.8: X import → local character

**Files:** Modify `lib/presentation/character_form/*` (the create-character save path)

- [ ] **Step 1:** Find where `celebrityPersonaSuggester` results are saved (`create_character_screen.dart` / `custom_character_editor_body.dart`). Where it currently calls the server `characters` insert + `CharacterStorage.uploadAvatar`, change to: build a `CharacterRecord` map and `characterRecordRepository` save (Hive). For avatar: if the suggestion has a `pbs.twimg.com` URL, store the URL string directly; if the user picked a file, copy it to the app documents dir (via `path_provider`) and store that path. Remove all `CharacterStorage`/Supabase references.
- [ ] **Step 2:** Verify.

Run: `flutter analyze && flutter test`
Expected: clean/green.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: save X-imported and manual characters to local hive"
```

## Task 1.9: Phase 1 end-to-end verification

- [ ] Run `grep -rn "supabase\|Supabase" lib` → **no output**.
- [ ] Run `flutter analyze` → no issues.
- [ ] Run `flutter test` → all green.
- [ ] Run app on a simulator (`flutter run`): app opens to the shell (no login); create a character via X URL import → appears in My Tutors → restart app → still there; open a chat → AI responds; save a word → appears in Word Book.
- [ ] Commit any fixes: `git commit -am "fix: phase 1 verification fixes"`.

---

# PHASE 2 — Local points wallet

**Exit criteria:** balance persists in the `points` box; spending (DM unlock etc.) deducts locally; IAP top-up credits locally and is idempotent across restart; app-bar chip reflects the local balance. Tests green.

## Task 2.1: LocalPointsRepository

**Files:** Create `lib/data/repositories/local_points_repository_impl.dart`; Test `test/data/repositories/local_points_repository_test.dart`

Implements the existing `PointsRepository` interface (`lib/domain/repositories/points_repository.dart`) locally. Storage keys in the `points` box: `balance` (int), `spend_log` (list of maps), `dm_unlocks` (list of message ids), `iap_tx` (list of processed transaction ids), `line_cache/<messageId>/<lang>` (map). Line-analysis cache moves local too.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:tomotomo/data/repositories/local_points_repository_impl.dart';

void main() {
  late Box box;
  setUp(() async {
    Hive.init('./.dart_tool/hive_test_2_1');
    box = await Hive.openBox('points');
    await box.put('balance', 100);
  });
  tearDown(() async => Hive.deleteFromDisk());

  test('spendPoints deducts and fails when insufficient', () async {
    final repo = LocalPointsRepositoryImpl(box);
    final ok = await repo.spendPoints(30, 'dm');
    expect(ok.ok, isTrue);
    expect(ok.balance, 70);
    final bad = await repo.spendPoints(1000, 'dm');
    expect(bad.ok, isFalse);
    expect(bad.balance, 70);
  });

  test('tryUnlockDmExpression charges once per message', () async {
    final repo = LocalPointsRepositoryImpl(box);
    final first = await repo.tryUnlockDmExpression('m1');
    expect(first.charged, isTrue);
    expect(first.balance, 99);
    final second = await repo.tryUnlockDmExpression('m1');
    expect(second.charged, isFalse);
    expect(second.balance, 99);
  });

  test('creditIapPoints is idempotent by transactionId', () async {
    final repo = LocalPointsRepositoryImpl(box);
    final a = await repo.creditIapPoints(
      store: 'play_store', transactionId: 'tx1', productId: 'p',
      points: 300, usdCents: 100);
    expect(a.credited, isTrue);
    expect(a.balance, 400);
    final b = await repo.creditIapPoints(
      store: 'play_store', transactionId: 'tx1', productId: 'p',
      points: 300, usdCents: 100);
    expect(b.credited, isFalse);
    expect(b.balance, 400);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/data/repositories/local_points_repository_test.dart`
Expected: FAIL — file missing.

- [ ] **Step 3: Write implementation**

```dart
import 'package:hive_ce/hive.dart';
import '../../domain/repositories/points_repository.dart';

/// Local Hive-backed wallet implementing [PointsRepository]. Single-user; no server.
class LocalPointsRepositoryImpl implements PointsRepository {
  LocalPointsRepositoryImpl(this._box);
  final Box _box;

  int get _balance => (_box.get('balance') as num?)?.toInt() ?? 0;
  Future<void> _setBalance(int v) => _box.put('balance', v);

  List<String> _idList(String key) =>
      (_box.get(key) as List?)?.map((e) => e.toString()).toList() ?? <String>[];

  @override
  Future<SpendPointsOutcome> spendPoints(int amount, String reason) async {
    if (amount <= 0) {
      return SpendPointsOutcome(ok: true, balance: _balance);
    }
    if (_balance < amount) {
      return SpendPointsOutcome(ok: false, balance: _balance, error: 'insufficient');
    }
    await _setBalance(_balance - amount);
    return SpendPointsOutcome(ok: true, balance: _balance);
  }

  @override
  Future<DmExpressionUnlockOutcome> tryUnlockDmExpression(String messageServerId) async {
    final unlocked = _idList('dm_unlocks');
    if (unlocked.contains(messageServerId)) {
      return DmExpressionUnlockOutcome(ok: true, balance: _balance, charged: false);
    }
    if (_balance < 1) {
      return DmExpressionUnlockOutcome(
          ok: false, balance: _balance, charged: false, error: 'insufficient');
    }
    await _setBalance(_balance - 1);
    await _box.put('dm_unlocks', [...unlocked, messageServerId]);
    return DmExpressionUnlockOutcome(ok: true, balance: _balance, charged: true);
  }

  @override
  Future<CreditIapPointsOutcome> creditIapPoints({
    required String store,
    required String transactionId,
    required String productId,
    String? purchaseToken,
    required int points,
    required int usdCents,
    String? rawReceipt,
  }) async {
    final processed = _idList('iap_tx');
    if (processed.contains(transactionId)) {
      return CreditIapPointsOutcome(ok: true, credited: false, balance: _balance);
    }
    await _setBalance(_balance + points);
    await _box.put('iap_tx', [...processed, transactionId]);
    return CreditIapPointsOutcome(ok: true, credited: true, balance: _balance);
  }

  @override
  Future<LineAnalysisCacheRow?> getLineAnalysisCache(String messageServerId, String appLang) async {
    final v = _box.get('line_cache/$messageServerId/$appLang');
    if (v is! Map) return null;
    final m = Map<String, dynamic>.from(v);
    final vocab = (m['vocabulary'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];
    return LineAnalysisCacheRow(
      explanation: m['explanation']?.toString(),
      lineTranslation: m['line_translation']?.toString(),
      vocabularyJson: vocab,
    );
  }

  @override
  Future<void> saveLineAnalysisCache(
    String messageServerId,
    String appLang, {
    String? explanation,
    String? lineTranslation,
    List<Map<String, dynamic>>? vocabularyJson,
  }) async {
    await _box.put('line_cache/$messageServerId/$appLang', {
      'explanation': explanation,
      'line_translation': lineTranslation,
      'vocabulary': vocabularyJson ?? [],
    });
  }

  /// Credits an arbitrary reward (used by rewarded ads in Phase 3). Returns new balance.
  Future<int> creditReward(int points) async {
    await _setBalance(_balance + points);
    return _balance;
  }

  int get balance => _balance;
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/data/repositories/local_points_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/local_points_repository_impl.dart test/data/repositories/local_points_repository_test.dart
git commit -m "feat: local hive-backed points wallet"
```

## Task 2.2: Seed starting balance + wire DI

**Files:** Modify `lib/core/local/hive_boxes.dart` (seed), `lib/core/di/injection.dart`, `lib/app.dart`, `lib/presentation/points/points_balance_notifier.dart`

- [ ] **Step 1:** In `openAllBoxes()`, after opening the `points` box, if `balance` key is absent, seed it: `if (box.get('balance') == null) await box.put('balance', 500);` (matches old `Profile.pointBalance` default of 500).
- [ ] **Step 2:** In `injection.dart`, `pointsRepository = LocalPointsRepositoryImpl(Hive.box(HiveBoxes.points));`.
- [ ] **Step 3:** Change `PointsBalanceNotifier` to take the `PointsRepository` (read local balance) instead of `ProfileRepository`. `refreshFromProfile` → `refresh()` reading `pointsRepository`. Update `app.dart` provider + the temporary `getPointBalance()` from Phase 1.5e is removed.
- [ ] **Step 4: Verify.** Run: `flutter analyze && flutter test` → clean/green.
- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: wire local points wallet into DI and balance chip"
```

## Task 2.3: IAP top-up credits locally

**Files:** Modify `lib/presentation/points/points_topup_screen.dart`

- [ ] **Step 1:** The `_onPurchaseUpdated` handler already calls `repo.creditIapPoints(...)`. It now hits the local impl — no code change to the call. Remove the `AppSupabase.auth.currentUser` login check in `_buy` (no accounts): replace with a direct purchase; delete the `import '../../core/supabase/app_supabase.dart';`.
- [ ] **Step 2: Verify.** Run: `flutter analyze` → clean.
- [ ] **Step 3: Commit**

```bash
git add lib/presentation/points/points_topup_screen.dart
git commit -m "refactor: local iap credit, drop login gate on top-up"
```

## Task 2.4: Phase 2 verification

- [ ] `flutter analyze` clean, `flutter test` green.
- [ ] Run app: balance chip shows 500 on fresh install; unlock a DM learning sheet → balance drops by 1, re-open same message → no further charge; restart → balance persisted.
- [ ] Commit fixes if any.

---

# PHASE 3 — Rewarded-ad earning ⭐

**Exit criteria:** a "watch ad to earn points" action loads and shows a rewarded ad; completing it credits +30 pt; a 5/day cap is enforced and resets at local midnight; entry points exist in the top-up screen and the out-of-points prompt. Tests green.

## Task 3.1: Add `google_mobile_ads` + config

**Files:** Modify `pubspec.yaml`; Create `lib/core/ads/ad_config.dart`

- [ ] **Step 1:** Add to `pubspec.yaml` dependencies: `google_mobile_ads: ^5.2.0`. Run `flutter pub get`.
- [ ] **Step 2:** Create `ad_config.dart`:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Rewarded-ad economy + unit ids. Uses Google public TEST ids in debug so
/// development needs no AdMob account; real ids come from env in release.
class AdConfig {
  static const int pointsPerAd = 30;
  static const int maxAdsPerDay = 5;

  // Google-provided public rewarded test unit ids.
  static const String _testAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testIos = 'ca-app-pub-3940256099942544/1712485313';

  static String get rewardedUnitId {
    if (kDebugMode) return Platform.isIOS ? _testIos : _testAndroid;
    final key = Platform.isIOS ? 'ADMOB_REWARDED_IOS' : 'ADMOB_REWARDED_ANDROID';
    final v = dotenv.isInitialized ? dotenv.env[key] : null;
    return (v == null || v.isEmpty) ? (Platform.isIOS ? _testIos : _testAndroid) : v;
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/ads/ad_config.dart
git commit -m "chore: add google_mobile_ads and ad config with test ids"
```

## Task 3.2: Native AdMob app-id config

**Files:** Modify `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`

- [ ] **Step 1 (Android):** Inside `<application>` add (test app id — replace for release):

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```

- [ ] **Step 2 (iOS):** In `Info.plist` add `GADApplicationIdentifier` = `ca-app-pub-3940256099942544~1458002511` and the `SKAdNetworkItems` block from the `google_mobile_ads` README.
- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
git commit -m "chore: configure admob application id (test) for android/ios"
```

## Task 3.3: Daily-cap logic (test-first)

**Files:** add cap methods to `LocalPointsRepositoryImpl`; Test extends `local_points_repository_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
test('rewarded ad daily cap counts and resets by date', () async {
  final repo = LocalPointsRepositoryImpl(box);
  expect(repo.adsRemainingToday(today: '2026-07-13'), 5);
  final r = await repo.recordAdReward(today: '2026-07-13'); // credits +30
  expect(r.credited, isTrue);
  expect(repo.adsRemainingToday(today: '2026-07-13'), 4);
  // exhaust
  for (var i = 0; i < 4; i++) { await repo.recordAdReward(today: '2026-07-13'); }
  expect(repo.adsRemainingToday(today: '2026-07-13'), 0);
  final blocked = await repo.recordAdReward(today: '2026-07-13');
  expect(blocked.credited, isFalse);
  // next day resets
  expect(repo.adsRemainingToday(today: '2026-07-14'), 5);
});
```

Add the `AdRewardOutcome` type + methods. Implementation:

```dart
// in local_points_repository_impl.dart
class AdRewardOutcome {
  const AdRewardOutcome({required this.credited, required this.balance, required this.remaining});
  final bool credited;
  final int balance;
  final int remaining;
}

// inside LocalPointsRepositoryImpl:
int adsRemainingToday({required String today}) {
  final storedDate = _box.get('ad_date') as String?;
  final count = storedDate == today ? ((_box.get('ad_count') as num?)?.toInt() ?? 0) : 0;
  final rem = AdConfig.maxAdsPerDay - count;
  return rem < 0 ? 0 : rem;
}

Future<AdRewardOutcome> recordAdReward({required String today}) async {
  final storedDate = _box.get('ad_date') as String?;
  var count = storedDate == today ? ((_box.get('ad_count') as num?)?.toInt() ?? 0) : 0;
  if (count >= AdConfig.maxAdsPerDay) {
    return AdRewardOutcome(credited: false, balance: _balance, remaining: 0);
  }
  count += 1;
  await _box.put('ad_date', today);
  await _box.put('ad_count', count);
  final bal = await creditReward(AdConfig.pointsPerAd);
  return AdRewardOutcome(credited: true, balance: bal, remaining: AdConfig.maxAdsPerDay - count);
}
```

Add `import '../../core/ads/ad_config.dart';` to the impl.

- [ ] **Step 2: Run** `flutter test test/data/repositories/local_points_repository_test.dart` → PASS.
- [ ] **Step 3: Commit** `git commit -am "feat: rewarded-ad daily cap in points wallet"`

## Task 3.4: RewardedAdService

**Files:** Create `lib/core/ads/rewarded_ad_service.dart`

- [ ] **Step 1: Implementation**

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';

/// Loads and shows a single rewarded ad. Calls [onEarned] once the user earns
/// the reward, then preloads the next ad.
class RewardedAdService {
  RewardedAd? _ad;
  bool _loading = false;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    load();
  }

  void load() {
    if (_loading || _ad != null) return;
    _loading = true;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) { _ad = ad; _loading = false; },
        onAdFailedToLoad: (_) { _ad = null; _loading = false; },
      ),
    );
  }

  bool get isReady => _ad != null;

  /// Shows the ad; invokes [onEarned] on completion. Returns false if not ready.
  Future<bool> show({required void Function() onEarned}) async {
    final ad = _ad;
    if (ad == null) { load(); return false; }
    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) { a.dispose(); load(); },
      onAdFailedToShowFullScreenContent: (a, _) { a.dispose(); load(); },
    );
    await ad.show(onUserEarnedReward: (_, __) => onEarned());
    return true;
  }

  void dispose() { _ad?.dispose(); _ad = null; }
}
```

- [ ] **Step 2:** Init in `main.dart`: create a singleton `RewardedAdService` (register in `injection.dart` as a global), `await adService.init()` after `openAllBoxes()`. Guard so `MobileAds` init failure doesn't crash the app (wrap in try/catch).
- [ ] **Step 3: Commit** `git add -A && git commit -m "feat: rewarded ad service + init"`

## Task 3.5: Earn-points UI

**Files:** Modify `lib/presentation/points/points_topup_screen.dart`, `points_topup_prompt.dart`

- [ ] **Step 1 (top-up screen):** Add a card above the IAP packs: title "광고 보고 포인트 받기" (add l10n keys to `app_strings.dart`), subtitle showing `${remaining}/5 오늘 남음` and `+30pt`. Button disabled when `remaining == 0` or `!adService.isReady`. On tap: `adService.show(onEarned: () async { final r = await pointsRepo.recordAdReward(today: _todayString()); if (r.credited) { balanceNotifier.setBalance(r.balance); showSnackBar('+30pt'); } })`. `_todayString()` = `DateTime.now()` formatted `yyyy-MM-dd` (use `intl` `DateFormat`).
- [ ] **Step 2 (out-of-points prompt):** In `showPointsTopUpPrompt`, add a third button "광고 보기" that triggers the same earn flow inline (or navigates to the top-up screen which now shows the ad card).
- [ ] **Step 3: l10n:** add keys `adEarnTitle`, `adEarnSubtitle`, `adEarnRemaining`, `adEarnCapReached`, `adEarnNotReady` to `app_strings.dart` (ko + ja).
- [ ] **Step 4: Verify.** Run: `flutter analyze && flutter test` → clean/green.
- [ ] **Step 5: Commit** `git add -A && git commit -m "feat: watch-ad-to-earn-points UI in top-up and prompt"`

## Task 3.6: Phase 3 verification

- [ ] `flutter analyze` clean, `flutter test` green.
- [ ] Run on a simulator: open top-up → "광고 보고 포인트 받기" → Google **test** rewarded ad plays → on completion balance +30, remaining decrements; after 5 the button disables with cap message; simulate next day (temporarily hardcode `today`) → resets to 5.
- [ ] Confirm the app still runs fully offline for chat/character/wordbook (ads simply fail to load with no network — button stays disabled, no crash).
- [ ] Commit fixes.

---

## Self-Review notes (author)

- **Spec coverage:** backend removal (1.1–1.6), Hive persistence (1.2–1.5), tab rebuild (1.7), X import kept + local (1.8), local points (2.1–2.3), IAP idempotency (2.1 test), rewarded ads +30/5-per-day + cap reset (3.3–3.5), test-unit-id dev path (3.1), required real ids documented (3.2). All spec sections mapped.
- **Type consistency:** `PointsRepository` interface preserved; `LocalPointsRepositoryImpl` adds `creditReward`, `recordAdReward`, `adsRemainingToday`, `balance`, `AdRewardOutcome`. `RewardedAdService.show({onEarned})` / `isReady` / `load` / `init` used consistently in 3.4–3.5. `HiveBoxes.points` name reused everywhere.
- **Known follow-up (not blocking):** iOS App Tracking Transparency prompt is recommended before ads in release but omitted from tasks to keep scope tight; add before store submission.
