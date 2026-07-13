import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/local/hive_boxes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Hive.initFlutter();
  await openAllBoxes();

  setupInjection();

  runApp(const App());
}
