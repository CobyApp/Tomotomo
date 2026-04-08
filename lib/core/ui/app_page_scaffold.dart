import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_tokens.dart';

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
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final bool transparentBackground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: hasSubtitle ? 72 : kToolbarHeight,
        titleSpacing: NavigationToolbar.kMiddleSpacing,
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
        actions: actions,
        bottom: bottom,
      ),
      floatingActionButton: floatingActionButton,
      body: wrappedBody,
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
