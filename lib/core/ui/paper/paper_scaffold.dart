import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../app_tokens.dart';
import '../points_toolbar_chip.dart';
import 'paper_tokens.dart';
import 'paper_wordmark.dart';

/// PAPER-CARTOON page layout: [title], [subtitle], [body], [actions],
/// [bottom], [floatingActionButton], [transparentBackground],
/// [showPointsChip], plus an additive [useWordmark] flag for the app root
/// screen. Renders the paper background with a subtle dotted grain overlay
/// and a cute display / [PaperWordmark] app-bar title.
class PaperScaffold extends StatelessWidget {
  const PaperScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.actions,
    this.bottom,
    this.floatingActionButton,
    this.transparentBackground = true,
    this.showPointsChip = false,
    this.useWordmark = false,
    this.showBackground = true,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;

  /// When true, prepends [PointsToolbarChip] to [actions] (main shell tabs).
  final bool showPointsChip;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final bool transparentBackground;

  /// When true, renders [title] via [PaperWordmark] (app root). Sub-screens
  /// use a plain cute display title.
  final bool useWordmark;

  /// When false, skips the [PaperBackground] wrapper so a shared ancestor (e.g.
  /// the main shell) can own one continuous gradient behind several tabs —
  /// avoiding a seam where an inset per-tab gradient meets the shell strip.
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.paper;
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    final mergedActions = <Widget>[
      if (showPointsChip) const PointsToolbarChip(),
      ...?actions,
    ];

    final titleWidget = useWordmark
        ? PaperWordmark(title, fontSize: hasSubtitle ? 22 : 24)
        : Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: p.ink,
            ),
          );

    final titleColumn = hasSubtitle
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              titleWidget,
              const SizedBox(height: 2),
              Text(
                subtitle!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: p.inkSoft,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ],
          )
        : titleWidget;

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: hasSubtitle ? 68 : 56,
        titleSpacing: AppSpacing.pageH,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        foregroundColor: p.ink,
        title: titleColumn,
        centerTitle: false,
        actions: mergedActions.isEmpty ? null : [...mergedActions, const SizedBox(width: 8)],
        bottom: bottom,
      ),
      floatingActionButton: floatingActionButton,
      body: transparentBackground ? body : ColoredBox(color: p.paperBg, child: body),
    );
    if (!showBackground) return scaffold;
    return PaperBackground(child: scaffold);
  }
}

/// The app's signature backdrop — pastel diagonal gradient + faint floating
/// star/heart deco. Shared by [PaperScaffold] and the default chat room so
/// every screen sits on exactly the same surface.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, this.child, this.showDeco = true});

  final Widget? child;
  final bool showDeco;

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(p.coral.withValues(alpha: 0.22), p.paperBg),
                p.paperBg,
                Color.alphaBlend(p.stampBlue.withValues(alpha: 0.22), p.paperBg),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        if (showDeco) const IgnorePointer(child: _DecoLayer()),
        ?child,
      ],
    );
  }
}

/// Floating star/heart stickers scattered behind content — the cute kitsch
/// signature. Faint so they never fight the foreground, and each one gently
/// bobs up/down (with its own phase) so the backdrop feels alive.
class _DecoLayer extends StatefulWidget {
  const _DecoLayer();

  @override
  State<_DecoLayer> createState() => _DecoLayerState();
}

class _DecoLayerState extends State<_DecoLayer>
    with SingleTickerProviderStateMixin {
  // (alignment, glyph, size, base rotation, bob phase 0..1)
  static const _items = [
    (Alignment(-0.85, -0.86), '★', 30.0, -0.2, 0.0),
    (Alignment(0.88, -0.78), '✦', 24.0, 0.25, 0.2),
    (Alignment(-0.94, -0.1), '♡', 34.0, 0.14, 0.55),
    (Alignment(0.9, 0.66), '✧', 30.0, -0.18, 0.35),
    (Alignment(-0.8, 0.82), '⋆', 26.0, 0.3, 0.75),
    (Alignment(0.5, 0.9), '♡', 20.0, -0.1, 0.9),
  ];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paper;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Stack(
          children: [
            for (final (align, glyph, size, rot, phase) in _items)
              Align(
                alignment: align,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    -14 * math.sin((_c.value + phase) * 2 * math.pi),
                  ),
                  child: Transform.rotate(
                    angle: rot,
                    child: Text(
                      glyph,
                      style: TextStyle(
                        fontSize: size,
                        color: p.coral.withValues(alpha: 0.16),
                        // Explicit so the glyphs never inherit the fallback
                        // yellow "missing DefaultTextStyle" underline on
                        // standalone routes (e.g. the chat screen).
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
