import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/app_supabase.dart';

/// Auth UI state. Waits briefly after startup so Supabase can finish async
/// [recoverSession] before deciding logged-out vs logged-in (session persistence).
class AppAuthState extends ChangeNotifier {
  AppAuthState() {
    unawaited(_bootstrap());
  }

  StreamSubscription<AuthState>? _authSubscription;
  User? _user;
  bool _isLoading = true;
  bool _showSignUp = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get showSignUp => _showSignUp;
  bool get isLoggedIn => _user != null;

  Future<void> _bootstrap() async {
    try {
      _authSubscription = AppSupabase.auth.onAuthStateChange.listen((data) {
        _user = data.session?.user;
        notifyListeners();
      });

      await Future<void>.delayed(Duration.zero);
      _user = AppSupabase.auth.currentUser;

      if (_user == null) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        _user = AppSupabase.auth.currentUser;
      }
    } catch (_) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void toggleSignUp() {
    _showSignUp = !_showSignUp;
    notifyListeners();
  }

  /// [displayName] is stored in user metadata and copied to `profiles` by trigger.
  Future<AuthResponse> signUp(
    String email,
    String password, {
    required String displayName,
    String? statusMessage,
  }) async {
    return AppSupabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName.trim(),
        if (statusMessage != null && statusMessage.trim().isNotEmpty) 'status_message': statusMessage.trim(),
      },
    );
  }

  Future<void> signIn(String email, String password) async {
    await AppSupabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await AppSupabase.auth.signOut();
  }
}
