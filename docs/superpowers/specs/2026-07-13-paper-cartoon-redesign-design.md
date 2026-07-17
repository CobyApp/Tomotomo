# Design: PAPER-CARTOON Redesign (Toss-grade UX)

**Date:** 2026-07-13
**Status:** Approved (pending written-spec review)
**Branch:** `paper-cartoon-redesign` (off `main`)

## Summary

Re-skin Tomotomo into a **warm paper-craft journal + cute cartoon** aesthetic,
with **Toss-grade UX**: simple layouts, generous whitespace, one clear action per
screen, and top-tier readability. This **replaces** the current holo-kitsch/glass
look. Cute rounded display type (Korean + Japanese) for titles/wordmark/word
cards; a highly readable body font. **Logic is untouched** — on-device Gemma AI,
points wallet, rewarded ads, X/link persona import all stay. Light **and** dark
modes.

## Locked decisions

- **Aesthetic:** paper-craft journal (cream paper, polaroid photos, washi tape,
  rubber stamps/tickets, journal note cards, soft "cut-paper" double shadows) +
  cute cartoon warmth. A faint print-offset (misregistration) glitch stays on the
  wordmark only — a nod to the old kitsch, not a system-wide effect.
- **UX:** Toss-simple. Clear hierarchy (big title → cards → single primary CTA),
  big tap targets (≥48px), secondary actions in bottom sheets, minimal chrome,
  maximum legibility.
- **Type:** cute rounded display for titles/wordmark/word cards (KO + JP);
  readable body font. See Typography.
- **Modes:** light + dark.
- **Keep:** all logic, features, and the 4-tab structure.

## Non-Goals

- No logic/behavior/feature changes; no new backend. Restyle + relayout only.
- Not changing the AI, points, ads, or import flows — only how they look and how
  the screens are organized for clarity.

## Design System: "PAPER-CARTOON"

### Palette — Light
| Token | Value | Use |
|-------|-------|-----|
| `paperBg` | `#F7EDE0` | page background (warm cream) |
| `paperGrain` | `rgba(160,120,80,.05)` | subtle dotted grain overlay |
| `card` | `#FFFDF8` | paper card surface |
| `cardEdge` | `#EFE2CE` | card hairline border |
| `cardShadow` | `#E8D9C1` (hard) + `rgba(140,100,60,.14)` (soft) | cut-paper double shadow |
| `ink` | `#4A3B32` | primary text (warm dark brown) |
| `inkSoft` | `#9C7B62` | secondary text |
| `coral` | `#C9563D` | primary accent / CTA / wordmark |
| `coralDeep` | `#A8442E` | CTA bottom edge (pressable paper) |
| `tape` | `rgba(230,180,140,.5)` | washi tape strips |
| `stampBlue` | `#3AA6B8` | secondary accent / print-offset ghost, stamps |

### Palette — Dark
Deep warm-neutral "night paper": `paperBg #241E1A`, `card #2E2723`,
`ink #F2E7D8`, `inkSoft #B79A82`, `coral #E9765C` (lifted for contrast),
`cardEdge #3A312B`. Same component shapes; shadows become subtle glows/edges.
Grain overlay reduced. All text must meet WCAG AA (≥4.5:1) in both modes — this
is a hard requirement given readability is the priority.

### Typography (cute title + readable body)
- **Display (cute, KO+JP):** a rounded, friendly face for the wordmark, screen
  titles, section labels, and vocabulary words. Candidates (all free for
  commercial use / OFL): JP — **Zen Maru Gothic** or **M PLUS Rounded 1c**; KO —
  **BM JUA (배민 주아체)** or **Cafe24 Ssurround** or Google **Dongle**. Final pair
  chosen at implementation; must cover both scripts between them.
- **Body (readable):** keep **Pretendard** (already bundled) for KO/Latin; JP
  body via bundled **Noto Sans JP** or system fallback. Body prioritizes
  legibility over cuteness.
- **Type scale:** title 26–28 / section 16–18 / body 14–15 / caption 12, with a
  clear weight jump (800 display vs 500–600 body) and generous line-height (1.4+).
- **Font assets require downloading OFL font files** — Claude will request
  explicit permission (naming file + source + size) before downloading any font.

### Shape, spacing, motion
- Radii: cards 18, buttons 15, pills/tickets 999, polaroid 2–4 (nearly square).
- Cut-paper shadow: a 2–3px hard offset shadow in `cardShadow` + a soft blurred
  shadow — makes surfaces read as layered paper.
- Generous spacing: page padding 18–20, card gaps 12, section breathing room.
- Motion: gentle press (paper "squash" — CTA bottom-edge collapses on tap),
  soft fade/slide transitions, a small stamp "thunk" on points gain. No holo
  shimmer, no continuous glitch. Subtle and performance-safe.

### Component catalog (`lib/core/ui/paper/`, replacing `holo/`)
- `paper_tokens.dart` — palette (light+dark), shadows, radii, grain.
- `paper_theme.dart` — `ThemeData` (light+dark) wired to the type scale + tokens.
- `PaperScaffold` — cream page (grain overlay) + title header (cute display) +
  actions slot; drop-in for the current scaffold API.
- `PaperCard` — layered-paper card (cut-paper double shadow, hairline edge).
- `PaperButton` — solid coral CTA with pressable bottom edge (paper squash).
- `PolaroidAvatar` — photo/emoji in a white polaroid frame, slight rotation.
- `WashiTape` — decorative tape strip (used sparingly on featured cards).
- `StampTicket` — dashed-border ticket/stamp (points balance, dates, badges).
- `JournalNote` — note card with a section label + dashed divider (word of the
  day, example sentences, field-notes style).
- `WordmarkGlitch` — "トモトモ" wordmark with faint print-offset ghost.
- `PaperNavBar` — clean paper bottom nav, line icons, coral selected state.
- `PaperStatusViews` — loading/empty/error on-brand (e.g., a cute stamp spinner).
- `PaperBottomSheet` — rounded paper sheet for secondary actions.

## UX principles applied per screen

Every screen gets: one clear primary action, a scannable title, cards with
comfortable padding, and secondary/destructive actions moved into bottom sheets
or overflow. Empty states are friendly and instructive.

## Screen inventory (all restyled + relaid-out)

1. **Home / My Tutors** (`main_shell` + `tabs/characters_tab.dart`) — journal
   home: wordmark, points ticket, taped polaroid tutor cards, "오늘의 단어" note,
   one "이어서 학습하기" CTA.
2. **Chats list** (`tabs/chats_tab.dart`) — paper room cards, polaroid avatars,
   last-message preview.
3. **Chat room + bubbles** (`chat/chat_screen.dart`, `widgets/chat_bubble.dart`,
   `widgets/chat_input.dart`, `widgets/chat_list.dart`) — me = coral paper
   bubble, tutor = cream paper bubble; readable, roomy; paper composer.
4. **Learning / expression sheet** (`chat/chat_expression_sheet.dart`) — as a
   `JournalNote`-style bottom sheet; vocab as stamps; example lines on dashed
   rules.
5. **Word Book** (`notebook/word_book_screen.dart`) — journal entries
   (`JournalNote` cards): word, reading, meaning.
6. **Character create + X import** (`character_form/*`) — paper form, prominent
   import `PaperButton`, suggestion preview in a `PaperCard`. Import logic kept.
7. **Points top-up + watch-ad** (`points/points_topup_screen.dart`) — packs as
   `StampTicket`s; the watch-ad card is the hero (a "무료 티켓" stamp), gentle
   attention (no shimmer). Prompt (`points_topup_prompt.dart`) as `PaperBottomSheet`.
8. **On-device model** (`on_device/*` — Gemma model download/manage UI) — paper
   progress card; keep all download/runtime logic.
9. **Settings / language / profile** (`tabs/settings_tab.dart`,
   `settings/*`) — paper tiles, polaroid profile avatar.
10. **Status/empty/loading** everywhere via `PaperStatusViews`.

## Removed / replaced

- The `lib/core/ui/holo/` design layer is replaced by `lib/core/ui/paper/`.
  Remove holo files once no screen references them.
- Any leftover holo tokens/gradients/glassmorphism in `app_theme.dart` and shared
  UI files are replaced by the paper theme.

## Implementation approach

1. Build `paper/` design layer (tokens, theme light+dark, core components) with
   widget tests for `PaperButton`, `WordmarkGlitch`, `StampTicket`.
2. Bundle fonts (after permission): declare in `pubspec.yaml`, wire into the type
   scale.
3. Wire `paper_theme` into `MaterialApp` (light+dark via `themeMode`).
4. Restyle + relayout screens in clusters (home/shell → chat → tabs → forms →
   points → settings/on-device), one cluster per commit.
5. Remove the holo layer once unreferenced.
6. Keep `flutter analyze` clean and `flutter test` green throughout (existing
   logic tests are the guardrail proving logic is untouched).

## Testing / verification

- `flutter analyze` clean; `flutter test` green (existing tests + new component
  tests) after each cluster.
- Contrast check: sample every text/background pairing in light + dark for ≥4.5:1.
- `flutter build apk --debug` succeeds.
- Visual pass on a simulator: each screen renders paper-cartoon, KO/JP/EN legible,
  cute display + readable body, light/dark both, new wordmark/icon consistent.

## Open item

- Exact cute font pair (KO + JP) is finalized at implementation; a download-
  permission request will precede bundling. If the user declines downloads, fall
  back to Pretendard + system JP (less cute, still shippable).
