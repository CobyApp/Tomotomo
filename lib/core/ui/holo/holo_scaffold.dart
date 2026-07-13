import 'package:flutter/material.dart';
import '../points_toolbar_chip.dart';
import 'glitch_text.dart';
import 'holo_tokens.dart';

/// HOLO-KITSCH page layout. Drop-in shape-compatible replacement for
/// [AppPageScaffold]: same public constructor params. Renders a transparent
/// [Scaffold] over the [Holo.pageGradient], with a [GlitchText] app-bar title.
class HoloScaffold extends StatelessWidget {
  const HoloScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.actions,
    this.bottom,
    this.floatingActionButton,
    this.transparentBackground = true,
    this.showPointsChip = false,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    final mergedActions = <Widget>[
      if (showPointsChip) const PointsToolbarChip(),
      ...?actions,
    ];

    final titleWidget = hasSubtitle
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GlitchText(
                title,
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Holo.inkPlumSoft,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ],
          )
        : GlitchText(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
          );

    return Container(
      decoration: const BoxDecoration(gradient: Holo.pageGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: hasSubtitle ? 72 : kToolbarHeight,
          titleSpacing: NavigationToolbar.kMiddleSpacing,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          foregroundColor: Holo.inkPlum,
          title: titleWidget,
          centerTitle: false,
          actions: mergedActions.isEmpty ? null : mergedActions,
          bottom: bottom,
        ),
        floatingActionButton: floatingActionButton,
        body: body,
      ),
    );
  }
}
