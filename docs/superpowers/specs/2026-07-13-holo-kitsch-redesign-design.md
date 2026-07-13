# Design: HOLO-KITSCH Visual Redesign

**Date:** 2026-07-13
**Status:** Approved (pending written-spec review)
**Branch:** `holo-kitsch-redesign` (off `local-offline-rewarded-ads`)

## Summary

A full **visual** redesign of Tomotomo into a bright, holographic **Y2K glitch +
kitsch** aesthetic — new color system, typography, component library, app icon,
and motion — applied across every screen. **Logic is untouched:** all
viewmodels, repositories, the local points wallet, rewarded ads, Gemini chat,
and X/link persona import stay exactly as verified. Only the presentation/visual
layer (`lib/core/ui/`, `lib/core/theme/`, and each screen's widgets) is rebuilt.

## Decisions (locked)

- **Direction:** A — Holographic Y2K. Bright pastel-neon + holographic
  gradients; kitsch is the base, glitch is the accent.
- **Scope:** Visual-only. Keep all verified local logic.
- **Theme:** Single bright holo theme. Remove the multi-theme picker,
  `user_theme` persistence, and the theme-settings screen; hardwire the holo
  theme.
- **App icon:** Double speech-bubble motif (friends = 友/tomo) + sparkle, on a
  holographic rounded-square, with a subtle glitch RGB offset.

## Non-Goals

- No logic/behavior changes. No new features. No backend.
- Not changing navigation structure/tab set (still My Tutors · Chats · Word Book
  · Settings) — only its look.

## Design System: "HOLO-KITSCH"

### Color tokens
| Token | Value | Use |
|-------|-------|-----|
| `holoPink` | `#FF2EC4` | primary accent, CTAs |
| `holoCyan` | `#17D6FF` | secondary accent |
| `holoLemon` | `#FFE600` | tertiary / highlights, points |
| `holoLilac` | `#C8A2FF` | gradient mid, soft accents |
| `inkPlum` | `#5A1550` | primary text |
| `inkPlumSoft` | `#9A5C8E` | secondary text |
| `surface` | `#FFF4FC` | page background (pastel) |
| `surfaceCard` | `#FFFFFF` | cards |
| `glitchR/G/B` | `#FF2EC4` / `#17D6FF` / `#FFE600` | RGB-split shadow trio |

**Holo gradient:** `linear/conic (holoPink → holoCyan → holoLilac → holoPink)`.
Used on buttons, chips, avatars ring, app-bar title fill.

### Typography
- **Display** (app name, section headers, tutor names): **M PLUS Rounded 1c**
  (bundled asset, weights 700/900; supports Japanese). Chunky, rounded, cute.
- **Body/UI:** system font stack (already used) for Latin/Hangul; Japanese falls
  back through the rounded display where needed.
- **Glitch text treatment:** a reusable `GlitchText` widget layering the string 3×
  with `holoPink`/`holoCyan`/`holoLemon` offsets (±2px) behind the ink layer.
  Applied to the app name and key headers only (not body — legibility).

### Shape & spacing
- Radius scale: 14 (chips/inputs), 18 (cards/bubbles), 22 (sheets/nav pill).
- Keep existing spacing tokens (`AppSpacing.pageH`, etc.) — restyle, don't
  restructure layout metrics.
- Borders: 2px dashed `holoCyan` on secondary cards; holo-gradient hairline on
  primary surfaces; glossy pill for the bottom nav.

### Motion (subtle, performance-safe)
- **Point gain:** brief glitch flash + sparkle burst on the points chip.
- **Ad reward:** holographic shimmer sweep across the reward card.
- **Tab tap:** tiny RGB jitter on the selected icon.
- All ≤ 350ms, `TickerProvider`-driven, no continuous loops that drain battery.

### Component catalog (in `lib/core/ui/`, overhauled/new)
- `HoloTheme` (replaces `app_theme.dart`) — `ThemeData` in holo palette + text
  theme wired to M PLUS Rounded.
- `holo_tokens.dart` (replaces/extends `app_tokens.dart`) — colors, gradients,
  radii, shadows, the glitch shadow trio.
- `GlitchText` — RGB-split display text.
- `HoloButton` / `HoloChip` — gradient fill, glossy.
- `HoloCard` — white/pastel card with dashed-cyan or holo-hairline border.
- `HoloScaffold` (replaces `app_page_scaffold.dart`) — pastel background +
  holo app bar with `GlitchText` title + points chip slot.
- `HoloNavBar` (replaces `app_glass_nav_bar.dart`) — glossy holo pill, 4 tabs,
  RGB-jitter selection.
- `PointsChip` (restyle `points_toolbar_chip.dart`) — lemon star + glitch flash.
- `ShellBackground` (restyle `app_shell_background.dart`) — pastel holo wash +
  faint scanline texture.
- `HoloStatusViews` (restyle `app_status_views.dart`) — loading (holo spinner),
  empty, error, all on-brand.
- Restyle `app_section_header.dart`, `app_settings_tile.dart`, `app_list_row.dart`.

## App Icon

- **Concept:** two overlapping rounded speech bubbles (one pink, one cyan) with a
  small ★ sparkle, on a holographic rounded-square background; a 2px RGB glitch
  offset on the bubbles. Legible at 48px.
- **Production:** author a 1024×1024 source (SVG → PNG). Regenerate launcher
  icons with the already-present `flutter_launcher_icons` (configure
  `flutter_launcher_icons.yaml` / pubspec block; `adaptive_icon` for Android with
  a holo background layer + bubble foreground). Update iOS `AppIcon.appiconset`
  and Android `mipmap`s via the tool.

## Screen inventory (all restyled to the system above)

1. **Main shell + nav** (`main_shell/`) — holo bg, glossy nav pill, glitch title.
2. **Chats list** (`main_shell/tabs/chats_tab.dart`) — holo room cards, avatars
   with holo ring, last-message preview.
3. **Chat room** (`chat/chat_screen.dart`, `widgets/chat_list.dart`) — holo
   bubbles (me = gradient, tutor = white/dashed), glitch header, input bar.
4. **Learning / expression sheet** (`chat/chat_expression_sheet.dart`) — holo
   sheet chrome, vocab chips, unlock CTA.
5. **My Tutors** (`main_shell/tabs/characters_tab.dart`) — holo tutor cards
   (my + built-in), create CTA.
6. **Word Book** (`notebook/word_book_screen.dart`) — holo entry cards.
7. **Character create + X import** (`character_form/`) — holo form, the X/link
   import field + suggestion preview restyled (logic unchanged).
8. **Points top-up + watch-ad card** (`points/points_topup_screen.dart`) — holo
   packs, prominent shimmering "watch ad to earn" card.
9. **Insufficient-points prompt** (`points/points_topup_prompt.dart`) — holo
   dialog.
10. **Settings** (`main_shell/tabs/settings_tab.dart`) — holo tiles; theme row
    removed.
11. **Language settings** (`settings/language_settings_screen.dart`) — restyled.
12. **Profile edit** (`settings/profile_edit_screen.dart`) — restyled.
13. **Status/empty/loading** everywhere via `HoloStatusViews`.

Removed: `settings/theme_settings_screen.dart`, `theme/*` picker plumbing,
`ThemeNotifier` reduced to serving the single holo theme (or removed if trivial),
`domain/entities/user_theme.dart` + `theme_repository*` if fully unused after
hardwiring (verify no other consumers before deleting).

## Implementation Approach

1. Build the design-system layer first (`holo_tokens`, `HoloTheme`, `GlitchText`,
   core `Holo*` widgets) with widget tests for `GlitchText` and one component.
2. Wire `HoloTheme` into `MaterialApp`; collapse the theme picker.
3. Restyle screens in dependency order: shell/nav → chat → tabs → forms →
   points → settings. One screen (or small cluster) per commit.
4. Create + wire the app icon; regenerate launcher assets.
5. Keep `flutter analyze` clean and `flutter test` green throughout; the existing
   19 logic tests must keep passing (proves logic untouched).

## Testing / Verification

- `flutter analyze` clean, `flutter test` green (existing 19 + new component
  tests) after each cluster.
- `flutter build apk --debug` succeeds.
- Visual pass: launch each screen; confirm holo/glitch treatment, legibility of
  JP/KO/EN text, points-gain + ad-reward motion, and that the icon renders on the
  launcher.

## Font asset note

M PLUS Rounded 1c is an SIL Open Font License font — bundle the needed weights
under `assets/fonts/` and declare in `pubspec.yaml`. Keep only 2 weights to limit
app size.
