import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/ui/paper/paper_scaffold.dart';
import '../../core/ui/paper/paper_tokens.dart';
import 'chat_background.dart';

/// A selectable chat-room background in the warm paper-cartoon palette.
///
/// Each preset is a single soft tint that is washed over the base paper
/// background as a gentle vertical gradient. The 'paper' preset is the neutral
/// default (no tint). [labelKey] is an l10n key resolved by the picker.
class ChatBackgroundPreset {
  const ChatBackgroundPreset({
    required this.id,
    required this.labelKey,
    required this.tint,
  });

  final String id;
  final String labelKey;

  /// Base hue for the wash. Rendered over `context.paper.paperBg` with an
  /// alpha derived from intensity, so it reads correctly in light and dark.
  final Color tint;
}

/// The catalog of ~8 presets. 'paper' first so it reads as the default.
const List<ChatBackgroundPreset> chatBackgroundPresets = [
  ChatBackgroundPreset(
    id: 'paper',
    labelKey: 'chatBgPresetPaper',
    tint: Color(0xFFF7EDE0),
  ),
  ChatBackgroundPreset(
    id: 'blush',
    labelKey: 'chatBgPresetBlush',
    tint: Color(0xFFEBA9B0),
  ),
  ChatBackgroundPreset(
    id: 'mint',
    labelKey: 'chatBgPresetMint',
    tint: Color(0xFF8FD4BE),
  ),
  ChatBackgroundPreset(
    id: 'lavender',
    labelKey: 'chatBgPresetLavender',
    tint: Color(0xFFC3B3E0),
  ),
  ChatBackgroundPreset(
    id: 'sky',
    labelKey: 'chatBgPresetSky',
    tint: Color(0xFFA8CCE8),
  ),
  ChatBackgroundPreset(
    id: 'peach',
    labelKey: 'chatBgPresetPeach',
    tint: Color(0xFFF3BE9A),
  ),
  ChatBackgroundPreset(
    id: 'butter',
    labelKey: 'chatBgPresetButter',
    tint: Color(0xFFF2DE9A),
  ),
  ChatBackgroundPreset(
    id: 'dusk',
    labelKey: 'chatBgPresetDusk',
    tint: Color(0xFFB09AB0),
  ),
];

/// Looks up a preset by id, falling back to the first ('paper') when unknown.
ChatBackgroundPreset chatBackgroundPresetById(String id) {
  for (final preset in chatBackgroundPresets) {
    if (preset.id == id) return preset;
  }
  return chatBackgroundPresets.first;
}

/// Peak wash alpha at intensity == 1.0. High enough that a color can read as a
/// near-solid background at full opacity; message bubbles sit on their own
/// opaque coral/card surfaces with ink borders, so they stay legible regardless.
const double _maxWashAlphaLight = 0.92;
const double _maxWashAlphaDark = 0.85;

/// Resolves the two gradient stop colors for [bg] against the active theme's
/// paper background. Exposed so the picker swatches and the live preview share
/// exactly the same math as the chat screen.
({Color top, Color bottom}) chatBackgroundStops(
  BuildContext context,
  ChatBackground bg,
) {
  final p = context.paper;
  final base = p.paperBg;
  final preset = chatBackgroundPresetById(bg.presetId);

  // 'paper' is the neutral default: always the plain paper surface.
  if (preset.id == 'paper') return (top: base, bottom: base);

  final dark = Theme.of(context).brightness == Brightness.dark;
  final maxAlpha = dark ? _maxWashAlphaDark : _maxWashAlphaLight;
  final a = bg.intensity.clamp(0.0, 1.0) * maxAlpha;

  final top = Color.alphaBlend(preset.tint.withValues(alpha: a), base);
  // Keep the two stops close so a high-intensity color reads as a solid fill
  // (with just a gentle top→bottom vignette), not a washed-out gradient.
  final bottom = Color.alphaBlend(
    preset.tint.withValues(alpha: a * 0.78),
    base,
  );
  return (top: top, bottom: bottom);
}

/// Builds the decoration for a chat-room background. Use directly for boxes
/// that need a [BoxDecoration]; see [buildChatBackground] for a ready widget.
BoxDecoration chatBackgroundDecoration(
  BuildContext context,
  ChatBackground bg,
) {
  final stops = chatBackgroundStops(context, bg);
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [stops.top, stops.bottom],
    ),
  );
}

/// Wraps [child] in the chat-room background for [bg]. Uses a custom photo when
/// [ChatBackground.imagePath] is set (with a paper scrim so text stays
/// readable — [intensity] controls how clearly the photo shows), otherwise the
/// preset color wash.
Widget buildChatBackground(
  BuildContext context,
  ChatBackground bg, {
  Widget? child,
}) {
  final path = bg.imagePath;
  if (path != null && path.isNotEmpty && File(path).existsSync()) {
    final base = context.paper.paperBg;
    // Higher intensity → clearer photo (less paper scrim). Keep a small minimum
    // scrim so message text remains legible over busy photos.
    final scrimAlpha = (1.0 - bg.intensity.clamp(0.0, 1.0)) * 0.72 + 0.12;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(File(path), fit: BoxFit.cover),
        ColoredBox(color: base.withValues(alpha: scrimAlpha.clamp(0.0, 1.0))),
        ?child,
      ],
    );
  }
  // Default ('paper') background: reuse the app's signature gradient + floating
  // deco so the chat room matches every other screen. Explicit color presets
  // still render their gentle wash.
  if (chatBackgroundPresetById(bg.presetId).id == 'paper') {
    return PaperBackground(child: child);
  }
  return DecoratedBox(
    decoration: chatBackgroundDecoration(context, bg),
    child: child,
  );
}
