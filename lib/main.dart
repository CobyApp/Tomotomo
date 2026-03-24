import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/home_widget/notebook_home_widget_sync.dart';
import 'core/supabase/app_supabase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await AppSupabase.initSupabase();

  setupInjection();

  await initNotebookHomeWidget();

  runApp(const App());
}
