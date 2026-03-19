import 'package:flutter/widgets.dart';

/// Observes app lifecycle and calls [onAppResumed] when returning to foreground.
///
/// Use: `class _XState extends State<X> with WidgetsBindingObserver, OnAppResumedMixin`.
mixin OnAppResumedMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      onAppResumed();
    }
  }

  void onAppResumed();
}
