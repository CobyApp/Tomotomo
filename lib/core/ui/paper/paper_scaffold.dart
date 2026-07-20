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

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: p.paperBg),
        CustomPaint(painter: _PaperGrainPainter(color: p.grain), size: Size.infinite),
        Scaffold(
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
        ),
      ],
    );
  }
}

/// Faint dotted "paper grain" texture, cheap enough to draw every frame.
class _PaperGrainPainter extends CustomPainter {
  const _PaperGrainPainter({required this.color});

  final Color color;
  static const double _spacing = 14;
  static const double _dotRadius = 0.6;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = 0.0; y < size.height; y += _spacing) {
      for (var x = 0.0; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), _dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PaperGrainPainter oldDelegate) => oldDelegate.color != color;
}
