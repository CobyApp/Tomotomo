# PAPER-CARTOON Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-skin Tomotomo into a warm paper-craft journal + cute cartoon aesthetic with Toss-grade simple UX and top-tier readability (light + dark), replacing the holo-kitsch look — changing visuals/layout only, never logic.

**Architecture:** Build a new `lib/core/ui/paper/` design layer (tokens, light+dark theme, cute+readable type scale, paper components), wire it into `MaterialApp` with `themeMode`, restyle every screen to consume it, then delete the old `lib/core/ui/holo/` layer. The existing logic tests must stay green throughout — that is the guardrail proving logic is untouched.

**Tech Stack:** Flutter, Material 3, Pretendard (bundled body) + cute OFL display fonts (KO+JP, downloaded with permission), Provider.

**Reference spec:** `docs/superpowers/specs/2026-07-13-paper-cartoon-redesign-design.md`

**Package:** `aichat`. Branch: `paper-cartoon-redesign`. Flutter 3.41.5. Local gitignored `.env` exists so tests run.

---

## Constraints for EVERY task
- VISUAL/LAYOUT ONLY. Never change viewmodels, repositories, services, providers, callbacks, or data flow. The existing test suite MUST stay green after every task (it is the "logic untouched" guardrail).
- Keep `flutter analyze` clean after every task.
- English-only code comments. Keep user-facing ko/ja strings.
- Readability is the priority: every text/background pair must meet WCAG AA (≥4.5:1) in light AND dark.

---

## File Structure

**New (`lib/core/ui/paper/`):**
- `paper_tokens.dart` — palette (light+dark), shadows, radii, grain.
- `paper_theme.dart` — `buildPaperLight()` / `buildPaperDark()` ThemeData + text theme.
- `paper_widgets.dart` — `PaperCard`, `PaperButton`, `StampTicket`, `PolaroidAvatar`, `WashiTape`.
- `journal_note.dart` — `JournalNote` card.
- `wordmark_glitch.dart` — `WordmarkGlitch`.
- `paper_scaffold.dart` — `PaperScaffold`.
- `paper_nav_bar.dart` — `PaperNavBar`.
- `paper_status_views.dart` — loading/empty/error.
- `paper_bottom_sheet.dart` — `showPaperSheet(...)`.

**Modified:** `lib/core/theme/app_theme.dart` (or superseded), `lib/presentation/theme/theme_notifier.dart`, `lib/app.dart`, `pubspec.yaml` (fonts), and every screen under `lib/presentation/`, plus shared `lib/core/ui/*` files still in use.

**Deleted (after no references remain):** `lib/core/ui/holo/*`.

---

# PHASE P1 — Paper design layer

## Task P1.1: paper_tokens.dart

**Files:** Create `lib/core/ui/paper/paper_tokens.dart`

- [ ] **Step 1: Implement**

```dart
import 'package:flutter/material.dart';

/// PAPER-CARTOON tokens. Two schemes (light/dark); components read [PaperColors]
/// from the active [Theme] extension so they adapt to mode automatically.
@immutable
class PaperColors extends ThemeExtension<PaperColors> {
  const PaperColors({
    required this.paperBg,
    required this.card,
    required this.cardEdge,
    required this.hardShadow,
    required this.softShadow,
    required this.ink,
    required this.inkSoft,
    required this.coral,
    required this.coralDeep,
    required this.tape,
    required this.stampBlue,
    required this.grain,
  });

  final Color paperBg, card, cardEdge, hardShadow, softShadow;
  final Color ink, inkSoft, coral, coralDeep, tape, stampBlue, grain;

  static const light = PaperColors(
    paperBg: Color(0xFFF7EDE0),
    card: Color(0xFFFFFDF8),
    cardEdge: Color(0xFFEFE2CE),
    hardShadow: Color(0xFFE8D9C1),
    softShadow: Color(0x24907850),
    ink: Color(0xFF4A3B32),
    inkSoft: Color(0xFF9C7B62),
    coral: Color(0xFFC9563D),
    coralDeep: Color(0xFFA8442E),
    tape: Color(0x80E6B48C),
    stampBlue: Color(0xFF3AA6B8),
    grain: Color(0x0DA07850),
  );

  static const dark = PaperColors(
    paperBg: Color(0xFF241E1A),
    card: Color(0xFF2E2723),
    cardEdge: Color(0xFF3A312B),
    hardShadow: Color(0xFF1C1714),
    softShadow: Color(0x40000000),
    ink: Color(0xFFF2E7D8),
    inkSoft: Color(0xFFB79A82),
    coral: Color(0xFFE9765C),
    coralDeep: Color(0xFFC85B44),
    tape: Color(0x66C79A72),
    stampBlue: Color(0xFF5FC3D4),
    grain: Color(0x0DFFFFFF),
  );

  @override
  PaperColors copyWith({Color? paperBg, Color? card, Color? cardEdge, Color? hardShadow, Color? softShadow, Color? ink, Color? inkSoft, Color? coral, Color? coralDeep, Color? tape, Color? stampBlue, Color? grain}) {
    return PaperColors(
      paperBg: paperBg ?? this.paperBg,
      card: card ?? this.card,
      cardEdge: cardEdge ?? this.cardEdge,
      hardShadow: hardShadow ?? this.hardShadow,
      softShadow: softShadow ?? this.softShadow,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      coral: coral ?? this.coral,
      coralDeep: coralDeep ?? this.coralDeep,
      tape: tape ?? this.tape,
      stampBlue: stampBlue ?? this.stampBlue,
      grain: grain ?? this.grain,
    );
  }

  @override
  PaperColors lerp(ThemeExtension<PaperColors>? other, double t) {
    if (other is! PaperColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return PaperColors(
      paperBg: c(paperBg, other.paperBg), card: c(card, other.card),
      cardEdge: c(cardEdge, other.cardEdge), hardShadow: c(hardShadow, other.hardShadow),
      softShadow: c(softShadow, other.softShadow), ink: c(ink, other.ink),
      inkSoft: c(inkSoft, other.inkSoft), coral: c(coral, other.coral),
      coralDeep: c(coralDeep, other.coralDeep), tape: c(tape, other.tape),
      stampBlue: c(stampBlue, other.stampBlue), grain: c(grain, other.grain),
    );
  }
}

/// Convenience accessor: `context.paper`.
extension PaperColorsX on BuildContext {
  PaperColors get paper => Theme.of(this).extension<PaperColors>() ?? PaperColors.light;
}

abstract final class PaperRadii {
  static const card = 18.0;
  static const button = 15.0;
  static const pill = 999.0;
  static const polaroid = 3.0;
}
```

- [ ] **Step 2: Verify** — `flutter analyze` clean.
- [ ] **Step 3: Commit** — `git add lib/core/ui/paper/paper_tokens.dart && git commit -m "feat: paper-cartoon tokens (light+dark theme extension)"`

## Task P1.2: WordmarkGlitch (TDD)

**Files:** Create `lib/core/ui/paper/wordmark_glitch.dart`; Test `test/core/ui/wordmark_glitch_test.dart`

- [ ] **Step 1: Failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aichat/core/ui/paper/wordmark_glitch.dart';

void main() {
  testWidgets('WordmarkGlitch renders the text with offset ghost copies', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: WordmarkGlitch('トモトモ'))),
    ));
    expect(find.text('トモトモ'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run → FAIL** — `flutter test test/core/ui/wordmark_glitch_test.dart`

- [ ] **Step 3: Implement**

```dart
import 'package:flutter/material.dart';
import 'paper_tokens.dart';

/// The app wordmark with a faint print-offset (misregistration) ghost — a small
/// nod to the old kitsch, readable and restrained.
class WordmarkGlitch extends StatelessWidget {
  const WordmarkGlitch(this.text, {super.key, this.fontSize = 27});
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final base = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, height: 1);
    Widget ghost(Color c, Offset d) => Transform.translate(
          offset: d,
          child: Text(text, style: base.copyWith(color: c.withValues(alpha: 0.35))),
        );
    return Stack(children: [
      ghost(p.coral, const Offset(-1.5, 1)),
      ghost(p.stampBlue, const Offset(1.5, -1)),
      Text(text, style: base.copyWith(color: p.coral)),
    ]);
  }
}
```

- [ ] **Step 4: Run → PASS**; analyze clean.
- [ ] **Step 5: Commit** — `git commit -am "feat: WordmarkGlitch print-offset wordmark"`

## Task P1.3: Paper components (TDD for PaperButton + StampTicket)

**Files:** Create `lib/core/ui/paper/paper_widgets.dart`; Test `test/core/ui/paper_widgets_test.dart`

- [ ] **Step 1: Failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aichat/core/ui/paper/paper_widgets.dart';

void main() {
  testWidgets('PaperButton shows label and fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: PaperButton(label: '학습하기', onPressed: () => tapped = true))),
    ));
    expect(find.text('학습하기'), findsOneWidget);
    await tester.tap(find.byType(PaperButton));
    expect(tapped, isTrue);
  });

  testWidgets('StampTicket renders its child', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: StampTicket(child: Text('충전')))),
    ));
    expect(find.text('충전'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run → FAIL**

- [ ] **Step 3: Implement**

```dart
import 'package:flutter/material.dart';
import 'paper_tokens.dart';

/// Layered "cut-paper" card: hairline edge + hard offset + soft blur shadow.
class PaperCard extends StatelessWidget {
  const PaperCard({super.key, required this.child, this.padding, this.onTap});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final card = Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(PaperRadii.card),
        border: Border.all(color: p.cardEdge),
        boxShadow: [
          BoxShadow(color: p.hardShadow, offset: const Offset(0, 3)),
          BoxShadow(color: p.softShadow, blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(borderRadius: BorderRadius.circular(PaperRadii.card), onTap: onTap, child: card);
  }
}

/// Solid coral CTA with a pressable "paper" bottom edge.
class PaperButton extends StatefulWidget {
  const PaperButton({super.key, required this.label, required this.onPressed, this.icon, this.expand = true});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  State<PaperButton> createState() => _PaperButtonState();
}

class _PaperButtonState extends State<PaperButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.expand ? double.infinity : null,
        transform: Matrix4.translationValues(0, _down ? 3 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: enabled ? p.coral : p.inkSoft,
          borderRadius: BorderRadius.circular(PaperRadii.button),
          boxShadow: [BoxShadow(color: enabled ? p.coralDeep : p.inkSoft, offset: Offset(0, _down ? 0 : 3))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
          if (widget.icon != null) ...[Icon(widget.icon, size: 18, color: Colors.white), const SizedBox(width: 6)],
          Text(widget.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
        ]),
      ),
    );
  }
}

/// Dashed-border stamp/ticket (points balance, dates, badges).
class StampTicket extends StatelessWidget {
  const StampTicket({super.key, required this.child, this.rotate = 0});
  final Widget child;
  final double rotate;
  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Transform.rotate(
      angle: rotate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: p.coral, width: 1.5, style: BorderStyle.solid),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: p.coral, fontWeight: FontWeight.w800, fontSize: 12),
          child: child,
        ),
      ),
    );
  }
}

/// Emoji/photo inside a white polaroid frame, slightly rotated.
class PolaroidAvatar extends StatelessWidget {
  const PolaroidAvatar({super.key, required this.child, this.size = 52, this.rotate = -0.04});
  final Widget child;
  final double size;
  final double rotate;
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.fromLTRB(3, 3, 3, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(PaperRadii.polaroid),
          boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(1), child: Center(child: child)),
      ),
    );
  }
}

/// Decorative washi-tape strip; place with Positioned on featured cards.
class WashiTape extends StatelessWidget {
  const WashiTape({super.key, this.width = 46, this.height = 15, this.rotate = -0.07});
  final double width, height, rotate;
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate,
      child: Container(width: width, height: height, color: context.paper.tape),
    );
  }
}
```

- [ ] **Step 4: Run → PASS**; analyze clean.
- [ ] **Step 5: Commit** — `git commit -am "feat: paper components (card/button/ticket/polaroid/tape)"`

## Task P1.4: JournalNote, PaperScaffold, PaperNavBar, status views, bottom sheet

**Files:** Create `lib/core/ui/paper/journal_note.dart`, `paper_scaffold.dart`, `paper_nav_bar.dart`, `paper_status_views.dart`, `paper_bottom_sheet.dart`

- [ ] **Step 1:** Implement each, reading the CURRENT equivalents first to mirror their public APIs so screens swap in cleanly:
  - `JournalNote({required String label, required Widget child})` — a `PaperCard` with a coral uppercase-ish `label`, a dashed divider, then `child`.
  - `PaperScaffold` — mirror the params of the current scaffold (`lib/core/ui/app_page_scaffold.dart` / `holo_scaffold.dart`): read it, replicate `title`/`actions`/`body`/`showPointsChip`/`bottom`/`floatingActionButton`. Render a `Container(color: context.paper.paperBg)` with a `CustomPaint` dotted-grain overlay, and a title using `WordmarkGlitch` for the app root or a plain cute display `Text` for sub-screens.
  - `PaperNavBar` — mirror `holo_nav_bar.dart` / `app_glass_nav_bar.dart` API (reuse `NavItemData`): clean paper bar, line icons, coral selected state, top hairline `cardEdge`.
  - `paper_status_views.dart` — mirror `app_status_views.dart` public widgets (loading/empty/error) in paper tokens (e.g. a rotating stamp for loading, friendly empty copy).
  - `paper_bottom_sheet.dart` — `Future<T?> showPaperSheet<T>(BuildContext, {required WidgetBuilder builder})` — rounded (top radius 24) paper sheet with a grab handle.
- [ ] **Step 2:** Add a widget test for `JournalNote` (renders label + child). Run it → PASS.
- [ ] **Step 3:** analyze clean; `flutter test` green.
- [ ] **Step 4: Commit** — `git commit -am "feat: journal note, paper scaffold, nav bar, status views, bottom sheet"`

## Task P1.5: Bundle cute fonts (CONTROLLER-HANDLED download) + type scale

**Files:** `pubspec.yaml`, `assets/fonts/`, `lib/core/ui/paper/paper_theme.dart` (Task P1.6 wires it)

> The download requires explicit user permission. The controller (not a subagent) obtains permission, downloads the OFL font files (naming file/source/size), and places them in `assets/fonts/`. If the user declines, skip this task and the theme uses Pretendard + system JP fallback (still shippable).

- [ ] **Step 1:** With permission, download cute OFL fonts and place under `assets/fonts/`: a Japanese rounded (e.g. `MPLUSRounded1c-Bold.ttf` / `ZenMaruGothic-Bold.ttf`) and a Korean cute display (e.g. `BMJUA.ttf` or Google `Dongle-Bold.ttf`). Also a JP body if needed (`NotoSansJP` subset) — otherwise rely on Pretendard + system.
- [ ] **Step 2:** Declare families in `pubspec.yaml` under `fonts:` (family names `CuteDisplayJP`, `CuteDisplayKO`, and keep `Pretendard`). Run `flutter pub get`.
- [ ] **Step 3:** Commit — `git add pubspec.yaml pubspec.lock assets/fonts && git commit -m "chore: bundle cute display fonts (KO+JP)"`

## Task P1.6: paper_theme.dart + wire light/dark into app

**Files:** Create `lib/core/ui/paper/paper_theme.dart`; Modify `lib/presentation/theme/theme_notifier.dart`, `lib/app.dart`

- [ ] **Step 1:** `paper_theme.dart` — `buildPaperLight()` and `buildPaperDark()` each returning `ThemeData(useMaterial3: true, brightness: ..., scaffoldBackgroundColor: colors.paperBg, extensions: [colors], textTheme: ...)`. Body font family `Pretendard`; provide a helper `TextStyle cuteDisplay(...)` using the bundled display family (fallback `Pretendard` if fonts were skipped). Map `ColorScheme` roles: primary=coral, surface=card, onSurface=ink, etc. Restyle `cardTheme`, `appBarTheme` (transparent, cute display title), `navigationBarTheme`, `bottomSheetTheme`, `filledButtonTheme`, `inputDecorationTheme` (readable, coral focus). Ensure AA contrast in both.
- [ ] **Step 2:** `theme_notifier.dart` — expose `ThemeData get theme => PaperTheme.light;`, `ThemeData get darkTheme => PaperTheme.dark;`, `ThemeMode get mode => ThemeMode.system;` (keep it a `ChangeNotifier`; no logic).
- [ ] **Step 3:** `app.dart` — `MaterialApp(theme: notifier.theme, darkTheme: notifier.darkTheme, themeMode: notifier.mode, ...)`. Keep the existing `home:` Consumer wiring unchanged.
- [ ] **Step 4:** analyze clean; `flutter test` green.
- [ ] **Step 5: Commit** — `git commit -am "feat: paper light+dark theme wired via themeMode"`

---

# PHASE P2 — Restyle + relayout screens

For EVERY task: read the screen, swap in `paper/` components + `context.paper`
tokens, apply Toss-simple layout (one primary action, roomy spacing, clear
hierarchy), keep all callbacks/providers/state/data flow. After each: analyze
clean, `flutter test` green, commit. Consult an already-migrated screen for the
established pattern.

## Task P2.1: Home/shell + nav + points chip
**Files:** `lib/presentation/main_shell/main_shell.dart`, `lib/presentation/main_shell/tabs/characters_tab.dart`, `lib/core/ui/app_shell_background.dart`, `lib/core/ui/points_toolbar_chip.dart`
- [ ] Shell background = `paperBg` + grain; wire `PaperNavBar`. Characters/home tab: `WordmarkGlitch` header, points as a `StampTicket`, tutor rows as `PaperCard` + `PolaroidAvatar` (one featured card may use `WashiTape`), an "오늘의 단어" `JournalNote` if data is readily available (else skip — no new logic), one primary `PaperButton`. Points chip → stamp style. Commit: `style: paper home shell, nav, points chip`.

## Task P2.2: Chat room + bubbles + input
**Files:** `lib/presentation/chat/chat_screen.dart`, `widgets/chat_bubble.dart`, `widgets/chat_input.dart`, `widgets/chat_list.dart`
- [ ] Paper header (cute title). Me bubble = coral paper, white text; tutor bubble = cream `PaperCard` look, ink text; roomy, readable. Composer = paper bar + `PaperButton`/coral send. Keep AI/stream logic. Commit: `style: paper chat room and bubbles`.

## Task P2.3: Expression sheet + word book
**Files:** `lib/presentation/chat/chat_expression_sheet.dart`, `lib/presentation/notebook/word_book_screen.dart`
- [ ] Expression sheet as a `showPaperSheet` / `JournalNote` layout; vocab as `StampTicket`s; example lines on dashed rules. Word book entries as `JournalNote` cards (word / reading / meaning). Keep unlock + points logic. Commit: `style: paper expression sheet and word book`.

## Task P2.4: Chats list + character form (X import)
**Files:** `lib/presentation/main_shell/tabs/chats_tab.dart`, `lib/presentation/character_form/*`
- [ ] Chats: `PaperCard` rows, `PolaroidAvatar`, preview text. Character form: paper inputs (readable, coral focus), prominent import `PaperButton`, suggestion preview in a `PaperCard`. Keep `CelebrityPersonaSuggester` + save logic. Commit: `style: paper chats list and character form`.

## Task P2.5: Points top-up + prompt + on-device setup
**Files:** `lib/presentation/points/points_topup_screen.dart`, `points_topup_prompt.dart`, `lib/presentation/on_device/on_device_model_setup_screen.dart`
- [ ] IAP packs as `StampTicket`/`PaperCard`; watch-ad card = hero "무료 티켓" (gentle emphasis, no shimmer). Prompt → `showPaperSheet`. On-device model setup: paper progress card + `PaperButton`; keep ALL download/runtime logic and progress bindings. Commit: `style: paper points, prompt, on-device setup`.

## Task P2.6: Settings + language + profile + status views + shared tiles
**Files:** `lib/presentation/main_shell/tabs/settings_tab.dart`, `lib/presentation/settings/*`, `lib/core/ui/app_status_views.dart`, `app_section_header.dart`, `app_settings_tile.dart`, `app_list_row.dart`
- [ ] Paper tiles/section headers; profile avatar via `PolaroidAvatar`; route shared status views through `paper_status_views`. Keep logic. Commit: `style: paper settings, profile, shared tiles`.

## Task P2.7: Straggler sweep + contrast check
- [ ] `grep -rn "Holo\|holo\|GlitchText\|glass\|shimmer" lib/presentation lib/core/ui | grep -v core/ui/paper` — convert any remaining holo usage to paper. Scan for plain `Card(`, hardcoded colors, off-palette accents. Spot-check text/bg contrast in light + dark for AA. Commit: `style: paper redesign stragglers + contrast pass`.

---

# PHASE P3 — Remove holo layer + finalize

## Task P3.1: Delete holo layer
**Files:** Delete `lib/core/ui/holo/*`; clean `app_theme.dart`
- [ ] Confirm no references: `grep -rn "core/ui/holo\|buildHoloTheme\|GlitchText\|Holo\b" lib`. When clean, `git rm lib/core/ui/holo/*.dart`; remove `buildHoloTheme` and any dead holo helpers from `app_theme.dart`; remove `holo` export from `lib/core/ui/ui.dart` if present. analyze clean; `flutter test` green. Commit: `refactor: remove holo design layer`.

## Task P3.2: App icon refresh (paper-cartoon)
**Files:** `assets/images/app_icon.png`, `app_icon_foreground.png`, `pubspec.yaml`
- [ ] Regenerate the icon in the paper-cartoon style (cream/coral, cute double speech bubble as a paper cut-out with a subtle print-offset), replacing the holo icon. Use the existing PIL approach (`sips`/Pillow available). Set `adaptive_icon_background` to `#F7EDE0`. Run `dart run flutter_launcher_icons`. analyze clean. Commit: `feat: paper-cartoon app icon`.

## Task P3.3: Final verification
- [ ] `flutter analyze` → No issues. `flutter test` → all green (existing logic tests + new component tests). `flutter build apk --debug` → builds.
- [ ] Diff audit: `git diff --stat main..HEAD -- lib/data lib/domain` is EMPTY (logic untouched).
- [ ] Visual pass on a simulator: each screen paper-cartoon, light+dark, KO/JP/EN legible, cute display + readable body, new icon on launcher.

---

## Self-Review notes (author)
- **Spec coverage:** tokens light+dark (P1.1), wordmark glitch (P1.2), components incl. polaroid/tape/ticket/card (P1.3), journal note/scaffold/nav/status/sheet (P1.4), cute fonts KO+JP with permission + fallback (P1.5), light+dark theme wired (P1.6), all screens incl. on-device setup (P2.1–P2.6), sweep + AA contrast (P2.7), holo removal (P3.1), icon (P3.2), verify incl. logic-untouched diff audit (P3.3).
- **Placeholder scan:** font files named by example with an explicit permission gate + fallback (not a hidden TBD).
- **Type consistency:** `PaperColors`/`context.paper`, `PaperRadii`, `WordmarkGlitch(text,fontSize)`, `PaperCard(child,padding,onTap)`, `PaperButton(label,onPressed,icon,expand)`, `StampTicket(child,rotate)`, `PolaroidAvatar(child,size,rotate)`, `WashiTape(...)`, `JournalNote(label,child)`, `showPaperSheet<T>(context,builder)`, `PaperNavBar`(reuses `NavItemData`) — consistent across tasks.
- **Guardrail:** existing logic tests green every task; P3.3 diff audit confirms `lib/data`/`lib/domain` untouched.
