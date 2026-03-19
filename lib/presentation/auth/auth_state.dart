import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/app_supabase.dart';

class AppAuthState extends ChangeNotifier {
  User? _user;
  bool _isLoading = true;
  bool _showSignUp = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get showSignUp => _showSignUp;
  bool get isLoggedIn => _user != null;

  void init() {
    try {
      _user = AppSupabase.auth.currentUser;
      AppSupabase.auth.onAuthStateChange.listen((data) {
        _user = data.session?.user;
        notifyListeners();
      });
    } catch (_) {
      _user = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  void toggleSignUp() {
    _showSignUp = !_showSignUp;
    notifyListeners();
  }

  Future<void> signUp(String email, String password) async {
    await AppSupabase.auth.signUp(email: email, password: password);
  }

  Future<void> signIn(String email, String password) async {
    await AppSupabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await AppSupabase.auth.signOut();
  }
}
