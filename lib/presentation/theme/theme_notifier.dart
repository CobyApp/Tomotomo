import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Provides the app-wide theme. Single HOLO-KITSCH theme — no user overrides.
class ThemeNotifier extends ChangeNotifier {
  ThemeData get theme => AppTheme.buildHoloTheme();
}
