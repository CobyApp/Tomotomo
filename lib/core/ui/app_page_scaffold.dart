import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_tokens.dart';
import 'points_toolbar_chip.dart';

/// Primary page layout: shared app bar title style. Main shell tabs use [transparentBackground]; pushed routes often set it false.
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
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
    final scheme = theme.colorScheme;
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    // Full-screen shell gradient behind Scaffold + AppBar. Transparent Scaffold alone
    // under IndexedStack / pushed routes can composite to black (no ancestor paint).
    final shellBackdrop = AppTheme.shellBackdropDecoration(scheme);

    final mergedActions = <Widget>[
      if (showPointsChip) const PointsToolbarChip(),
      ...?actions,
    ];

    final wrappedBody = transparentBackground
        ? body
        : DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.shellGradientTop(scheme),
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
            child: body,
          );

    return DecoratedBox(
      decoration: shellBackdrop,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: hasSubtitle ? 72 : kToolbarHeight,
          titleSpacing: NavigationToolbar.kMiddleSpacing,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          foregroundColor: scheme.onSurface,
          title: hasSubtitle
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppTextStyles.pageTitle(context)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ],
                )
              : Text(title, style: AppTextStyles.pageTitle(context)),
          centerTitle: false,
          actions: mergedActions.isEmpty ? null : mergedActions,
          bottom: bottom,
        ),
        floatingActionButton: floatingActionButton,
        body: wrappedBody,
      ),
    );
  }
}

/// Standard horizontal + bottom padding for scrollable tab content.
class AppPageScrollPadding extends StatelessWidget {
  const AppPageScrollPadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        AppSpacing.pageTop,
        AppSpacing.pageH,
        AppSpacing.pageBottom,
      ),
      child: child,
    );
  }
}
