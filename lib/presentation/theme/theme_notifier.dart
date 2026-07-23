import 'package:flutter/material.dart';
import '../../core/ui/paper/paper_theme.dart';

/// Provides the app-wide paper-cartoon theme (light + dark, follows system).
class ThemeNotifier extends ChangeNotifier {
  ThemeData get theme => PaperTheme.light;
  ThemeData get darkTheme => PaperTheme.dark;
  // Soft-cyber look is a light UI — default to light (not a dark neon blast).
  ThemeMode get mode => ThemeMode.light;
}
