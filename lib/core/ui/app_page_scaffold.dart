import 'package:flutter/material.dart';
import 'app_tokens.dart';

/// Primary page layout: shared app bar title style. Main shell tabs use [transparentBackground]; pushed routes often set it false.
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottom,
    this.floatingActionButton,
    this.transparentBackground = true,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final bool transparentBackground;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          transparentBackground ? Colors.transparent : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.pageTitle(context)),
        centerTitle: false,
        actions: actions,
        bottom: bottom,
      ),
      floatingActionButton: floatingActionButton,
      body: body,
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
