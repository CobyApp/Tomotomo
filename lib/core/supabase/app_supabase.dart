import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client access. Call [initSupabase] from main before runApp.
class AppSupabase {
  static bool _initialized = false;

  static Future<void> initSupabase() async {
    if (_initialized) return;
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    // Publishable key (safe for client; replaces legacy anon key)
    final publishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '';
    if (url.isEmpty || publishableKey.isEmpty) {
      throw Exception('SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY must be set in .env');
    }
    await Supabase.initialize(
      url: url,
      anonKey: publishableKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );
    // SDK starts recoverSession asynchronously; a short yield helps first-frame auth reads.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _initialized = true;
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
}
