import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Provides the app-wide soft holographic theme.
class ThemeNotifier extends ChangeNotifier {
  ThemeData get theme => AppTheme.buildHoloTheme();
}
