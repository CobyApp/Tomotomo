# HOLO-KITSCH Visual Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-skin the entire Tomotomo app into a bright holographic Y2K glitch+kitsch look via a new shared design-system layer, changing visuals only — all verified logic (viewmodels, repos, local points, rewarded ads, Gemini chat, X import) stays intact.

**Architecture:** Build a `HOLO-KITSCH` design-system layer (`lib/core/ui/holo/` + a new theme), then restyle every screen to consume it. The existing 19 logic tests MUST keep passing throughout — that is the guardrail proving logic is untouched. Font stays Pretendard (already bundled); the kitsch/rounded feel comes from color, gradient, glitch treatment, and shape, not a new font.

**Tech Stack:** Flutter, Material 3, existing Pretendard font, `flutter_launcher_icons` (app icon).

**Reference spec:** `docs/superpowers/specs/2026-07-13-holo-kitsch-redesign-design.md`

**Package name:** `aichat`. Branch: `holo-kitsch-redesign`. Flutter 3.41.5. A local gitignored `.env` exists so tests run.

---

## Constraints for EVERY task
- Do NOT change any viewmodel, repository, entity, or service logic. Restyle widgets only. If a screen's logic and layout are entangled, change presentation (colors, shapes, wrapping widgets) without altering data flow, callbacks, or state.
- Keep `flutter analyze` clean and `flutter test` green after each task. The 19 existing logic tests must never regress.
- English-only code comments. Keep user-facing ko/ja strings unchanged.
- Follow existing spacing tokens (`AppSpacing`) — restyle, don't relayout metrics.

---

## File Structure

**New (`lib/core/ui/holo/`):**
- `holo_tokens.dart` — colors, gradients, radii, shadows, glitch shadow trio.
- `glitch_text.dart` — RGB-split display text widget.
- `holo_widgets.dart` — `HoloCard`, `HoloButton`, `HoloChip`, `HoloGradientRing`.
- `holo_scaffold.dart` — page scaffold with holo bg + glitch title app bar.
- `holo_nav_bar.dart` — glossy holo bottom nav.

**Overhauled:** `lib/core/theme/app_theme.dart` (holo palette), `lib/core/ui/app_shell_background.dart`, `lib/core/ui/points_toolbar_chip.dart`, `lib/core/ui/app_status_views.dart`, `lib/core/ui/app_section_header.dart`, `lib/core/ui/app_settings_tile.dart`, `lib/core/ui/app_list_row.dart`, and every screen under `lib/presentation/`.

**Deleted (after verifying no other consumers):** `lib/presentation/settings/theme_settings_screen.dart`, theme-picker plumbing in `theme_notifier.dart` (reduced to serving one theme).

**Icon:** `assets/images/app_icon.png` (regenerated), `assets/images/app_icon_fg.png` (adaptive foreground), pubspec `flutter_launcher_icons` block.

---

# PHASE R1 — Design-system layer

## Task R1.1: holo_tokens.dart

**Files:** Create `lib/core/ui/holo/holo_tokens.dart`

- [ ] **Step 1: Implement**

```dart
import 'package:flutter/material.dart';

/// HOLO-KITSCH palette + surface/shape/shadow tokens. Single bright theme.
abstract final class Holo {
  static const pink = Color(0xFFFF2EC4);
  static const cyan = Color(0xFF17D6FF);
  static const lemon = Color(0xFFFFE600);
  static const lilac = Color(0xFFC8A2FF);
  static const inkPlum = Color(0xFF5A1550);
  static const inkPlumSoft = Color(0xFF9A5C8E);
  static const surface = Color(0xFFFFF4FC);
  static const surfaceCard = Color(0xFFFFFFFF);

  /// Primary holographic sweep for buttons/chips/rings.
  static const holoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, lilac, cyan],
  );

  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFE8FA), Color(0xFFE7F6FF)],
  );

  /// RGB-split shadow trio for glitch text (offset applied by GlitchText).
  static const glitchR = pink;
  static const glitchG = cyan;
  static const glitchB = lemon;

  static List<BoxShadow> get cardShadow => const [
        BoxShadow(color: Color(0x22FF2EC4), blurRadius: 18, offset: Offset(0, 8)),
      ];
}
```

- [ ] **Step 2: Verify** — `flutter analyze` clean.
- [ ] **Step 3: Commit** — `git add lib/core/ui/holo/holo_tokens.dart && git commit -m "feat: holo-kitsch design tokens"`

## Task R1.2: GlitchText widget (TDD)

**Files:** Create `lib/core/ui/holo/glitch_text.dart`; Test `test/core/ui/glitch_text_test.dart`

- [ ] **Step 1: Write failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aichat/core/ui/holo/glitch_text.dart';

void main() {
  testWidgets('GlitchText renders the text and layered copies', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: GlitchText('トモトモ'))),
    ));
    // The string is painted multiple times (ink + RGB split layers).
    expect(find.text('トモトモ'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run → FAIL** — `flutter test test/core/ui/glitch_text_test.dart`

- [ ] **Step 3: Implement**

```dart
import 'package:flutter/material.dart';
import 'holo_tokens.dart';

/// Display text with an RGB channel-split glitch look: three offset colored
/// copies behind a solid ink copy. Use for the app name and key headers only.
class GlitchText extends StatelessWidget {
  const GlitchText(this.text, {super.key, this.style, this.offset = 2});

  final String text;
  final TextStyle? style;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final base = (style ??
            Theme.of(context).textTheme.titleLarge ??
            const TextStyle())
        .copyWith(fontWeight: FontWeight.w900, color: Holo.inkPlum);
    Widget layer(Color c, Offset d) => Transform.translate(
          offset: d,
          child: Text(text, style: base.copyWith(color: c)),
        );
    return Stack(
      alignment: Alignment.center,
      children: [
        layer(Holo.glitchR, Offset(-offset, 0)),
        layer(Holo.glitchG, Offset(offset, 0)),
        layer(Holo.glitchB, Offset(0, offset)),
        Text(text, style: base),
      ],
    );
  }
}
```

- [ ] **Step 4: Run → PASS**; `flutter analyze` clean.
- [ ] **Step 5: Commit** — `git commit -am "feat: GlitchText RGB-split display widget"`

## Task R1.3: Holo component widgets (TDD for one)

**Files:** Create `lib/core/ui/holo/holo_widgets.dart`; Test `test/core/ui/holo_widgets_test.dart`

- [ ] **Step 1: Failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aichat/core/ui/holo/holo_widgets.dart';

void main() {
  testWidgets('HoloButton shows label and fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(
        child: HoloButton(label: 'GO', onPressed: () => tapped = true),
      )),
    ));
    expect(find.text('GO'), findsOneWidget);
    await tester.tap(find.byType(HoloButton));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run → FAIL**

- [ ] **Step 3: Implement** (gradient-filled button, gradient chip, holo-bordered card, avatar ring)

```dart
import 'package:flutter/material.dart';
import 'holo_tokens.dart';

class HoloButton extends StatelessWidget {
  const HoloButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : Holo.holoGradient,
        color: onPressed == null ? Holo.inkPlumSoft.withValues(alpha: 0.3) : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: Holo.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 18, color: Colors.white), const SizedBox(width: 6)],
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
            ]),
          ),
        ),
      ),
    );
  }
}

class HoloChip extends StatelessWidget {
  const HoloChip({super.key, required this.child, this.filled = true});
  final Widget child;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: filled ? Holo.holoGradient : null,
        color: filled ? null : Holo.surfaceCard,
        borderRadius: BorderRadius.circular(999),
        border: filled ? null : Border.all(color: Holo.cyan, width: 2),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: filled ? Colors.white : Holo.inkPlum,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
        child: child,
      ),
    );
  }
}

class HoloCard extends StatelessWidget {
  const HoloCard({super.key, required this.child, this.dashed = false, this.padding});
  final Widget child;
  final bool dashed;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Holo.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dashed ? Holo.cyan : Holo.pink.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: Holo.cardShadow,
      ),
      child: child,
    );
  }
}

/// Circular holo gradient ring around an avatar [child].
class HoloGradientRing extends StatelessWidget {
  const HoloGradientRing({super.key, required this.child, this.size = 44});
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: Holo.holoGradient),
      child: ClipOval(child: child),
    );
  }
}
```

- [ ] **Step 4: Run → PASS**; `flutter analyze` clean.
- [ ] **Step 5: Commit** — `git commit -am "feat: holo component widgets (button/chip/card/ring)"`

## Task R1.4: Holo theme + scaffold + nav; collapse theme picker

**Files:** Modify `lib/core/theme/app_theme.dart`; Create `lib/core/ui/holo/holo_scaffold.dart`, `lib/core/ui/holo/holo_nav_bar.dart`; Modify `lib/presentation/theme/theme_notifier.dart`, `lib/app.dart`, `lib/presentation/main_shell/tabs/settings_tab.dart`; Delete `lib/presentation/settings/theme_settings_screen.dart`.

- [ ] **Step 1:** In `app_theme.dart`, add a `buildHoloTheme()` that returns a `ThemeData` seeded from `Holo.pink` with `surface = Holo.surface`, `scaffoldBackgroundColor = Holo.surface`, keeping `fontFamily = 'Pretendard'`, and restyling `appBarTheme`/`cardTheme`/`navigationBarTheme`/`elevatedButtonTheme` to the holo palette (transparent app bar, gradient handled by widgets). Keep the existing `buildLightTheme` for now but make `ThemeNotifier` return `buildHoloTheme()`.
- [ ] **Step 2:** `theme_notifier.dart`: reduce to always exposing `buildHoloTheme()` as `theme` (drop user-accent/seed switching and any `ThemeRepository` reads). If this orphans `ThemeRepository`/`user_theme.dart`, verify with `grep -rn "ThemeRepository\|user_theme\|UserTheme" lib` and delete the now-unused files + their DI wiring + app.dart provider ONLY if no consumers remain; otherwise leave them and just stop using them.
- [ ] **Step 3:** Create `holo_scaffold.dart` — a `HoloScaffold({title, actions, body})` wrapping `Scaffold` with `Holo.pageGradient` background (a `Container` decoration behind a transparent Scaffold) and an app bar whose title is `GlitchText(title)`; `actions` slot for the points chip. Mirror the API surface of the existing `AppPageScaffold` (check its constructor params) so screens can swap with minimal change.
- [ ] **Step 4:** Create `holo_nav_bar.dart` — a glossy holo pill bottom bar with 4 items (icons + labels), gradient selection indicator, matching the current `AppGlassNavBar` public API (read it first) so `main_shell` can swap it in.
- [ ] **Step 5:** `settings_tab.dart`: remove the theme-settings row/navigation; `git rm lib/presentation/settings/theme_settings_screen.dart` and remove its imports/usages.
- [ ] **Step 6:** `flutter analyze` clean, `flutter test` green (19 logic + new widget tests).
- [ ] **Step 7: Commit** — `git commit -am "feat: holo theme, scaffold, nav bar; remove theme picker"`

---

# PHASE R2 — Restyle screens

For EVERY task below: read the screen first, then swap in `Holo*` components /
tokens and holo colors, keeping all callbacks, providers, state, and data flow
identical. After each: `flutter analyze` clean, `flutter test` green, commit.

## Task R2.1: Main shell + shell background + points chip
**Files:** `lib/presentation/main_shell/main_shell.dart`, `lib/core/ui/app_shell_background.dart`, `lib/core/ui/points_toolbar_chip.dart`
- [ ] Shell uses `Holo.pageGradient` background and `HoloNavBar`. Restyle `app_shell_background.dart` to the pastel holo wash + a faint scanline overlay (a `CustomPaint` or repeating gradient at low opacity). Restyle `points_toolbar_chip.dart` to a lemon-star `HoloChip`; add a brief glitch flash animation when the balance increases (compare old/new value in `didUpdateWidget`). Commit: `style: holo main shell, background, points chip`.

## Task R2.2: Chat room + message list
**Files:** `lib/presentation/chat/chat_screen.dart`, `lib/presentation/chat/widgets/chat_list.dart`
- [ ] `HoloScaffold` with `GlitchText` title. Me bubbles = `Holo.holoGradient` fill, white text, radius 18; tutor bubbles = white `HoloCard`-style with dashed cyan border, ink text. Composer bar: holo hairline top border, `HoloButton` send. Keep streaming/AI logic untouched. Commit: `style: holo chat room and bubbles`.

## Task R2.3: Learning / expression sheet
**Files:** `lib/presentation/chat/chat_expression_sheet.dart`
- [ ] Holo sheet chrome (radius 22, holo hairline), vocab items as `HoloChip`s, the unlock/points CTA as `HoloButton`. Keep unlock logic + points calls untouched. Commit: `style: holo expression sheet`.

## Task R2.4: Chats list + My Tutors tabs
**Files:** `lib/presentation/main_shell/tabs/chats_tab.dart`, `lib/presentation/main_shell/tabs/characters_tab.dart`
- [ ] Room/tutor rows as `HoloCard`s with `HoloGradientRing` avatars, ink titles, soft-plum subtitles. Create/primary actions as `HoloButton`. Empty/loading via the restyled status views. Commit: `style: holo chats and tutors tabs`.

## Task R2.5: Word Book + character form (incl. X import)
**Files:** `lib/presentation/notebook/word_book_screen.dart`, `lib/presentation/character_form/*`
- [ ] Word entries as `HoloCard`s. Character form: holo inputs, the X/link import field prominent with a `HoloButton` "import", suggestion preview in a `HoloCard`. Keep `CelebrityPersonaSuggester` + save logic untouched. Commit: `style: holo word book and character form`.

## Task R2.6: Points top-up + prompt + settings + language + profile + status views
**Files:** `lib/presentation/points/points_topup_screen.dart`, `points_topup_prompt.dart`, `lib/presentation/main_shell/tabs/settings_tab.dart`, `lib/presentation/settings/language_settings_screen.dart`, `lib/presentation/settings/profile_edit_screen.dart`, `lib/core/ui/app_status_views.dart`, `app_section_header.dart`, `app_settings_tile.dart`, `app_list_row.dart`
- [ ] IAP packs as `HoloCard`s; the watch-ad card gets a holographic shimmer sweep (an `AnimatedBuilder` gradient slide) and is the visual hero. Prompt dialog restyled holo. Settings/language/profile tiles restyled. `app_status_views.dart`: holo spinner + on-brand empty/error. Keep all logic (ads, IAP, spend) untouched. Commit: `style: holo points, settings, profile, status views`.

## Task R2.7: Sweep for stragglers
- [ ] `grep -rn "AppTheme.seedColor\|Color(0xFFFF6B9D)\|Pretendard" lib` and any remaining old-accent usages; confirm no screen still shows the old pink/kawaii look. Fix stragglers. `flutter analyze` + `flutter test`. Commit: `style: holo redesign stragglers`.

---

# PHASE R3 — App icon

## Task R3.1: Create the icon source
**Files:** Create `assets/images/app_icon.png` (1024×1024) and `assets/images/app_icon_fg.png` (1024×1024 transparent foreground, centered with padding for adaptive safe-zone).
- [ ] **Step 1:** Author an SVG of the concept: holographic rounded-square background (pink→lilac→cyan diagonal), two overlapping rounded speech bubbles (front pink `#FF2EC4`, back cyan `#17D6FF`) with a small lemon ★ sparkle, and a 2px RGB glitch offset duplicate of the bubbles. Save as `assets/images/app_icon.svg`.
- [ ] **Step 2:** Rasterize to PNG 1024×1024. Try in order until one works: `rsvg-convert -w 1024 -h 1024 app_icon.svg -o app_icon.png`; else `cairosvg`; else `magick -density 400 app_icon.svg -resize 1024x1024 app_icon.png`; else a small Python `Pillow` script drawing the shapes directly; else render the SVG in the mcp Claude Browser at 1024×1024 and screenshot. Also export a transparent-background foreground `app_icon_fg.png` (bubbles+sparkle only, ~66% size, centered) for the adaptive icon.
- [ ] **Step 3:** Verify both PNGs are 1024×1024 (`file`/`sips -g pixelWidth`). Commit: `feat: holo double-bubble app icon source`.

## Task R3.2: Regenerate launcher icons
**Files:** Modify `pubspec.yaml` `flutter_launcher_icons` block.
- [ ] **Step 1:** Update the block:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#FF2EC4"
  adaptive_icon_foreground: "assets/images/app_icon_fg.png"
  remove_alpha_ios: true
```
- [ ] **Step 2:** Run `dart run flutter_launcher_icons`. Confirm it rewrites `android/app/src/main/res/mipmap-*` and `ios/Runner/Assets.xcassets/AppIcon.appiconset`.
- [ ] **Step 3:** `flutter analyze` clean. Commit: `chore: regenerate launcher icons from holo app icon`.

---

# FINAL verification
- [ ] `flutter analyze` → No issues found.
- [ ] `flutter test` → all green (19 logic tests + new widget tests).
- [ ] `flutter build apk --debug` → builds.
- [ ] Visual pass: launch app; every screen shows the holo/glitch look; JP/KO/EN legible; points-gain glitch flash + ad-reward shimmer fire; new icon on the launcher.

---

## Self-Review notes (author)
- **Spec coverage:** palette/gradient/glitch tokens (R1.1–R1.2), component catalog (R1.3), theme + scaffold + nav + picker removal (R1.4), all 13 screen areas (R2.1–R2.7), motion — points glitch flash (R2.1), ad shimmer (R2.6), icon concept + production + regen (R3). Font decision revised from spec (Pretendard kept, no download) — noted here and acceptable; roundness carried by shape/gradient/glitch.
- **Type consistency:** `Holo` token class, `GlitchText(text, style, offset)`, `HoloButton(label,onPressed,icon)`, `HoloChip(child,filled)`, `HoloCard(child,dashed,padding)`, `HoloGradientRing(child,size)`, `HoloScaffold(title,actions,body)`, `HoloNavBar` — names used consistently across R2 tasks.
- **Guardrail:** the 19 existing logic tests must stay green in every task; that is the mechanical proof that "visual-only" held.
