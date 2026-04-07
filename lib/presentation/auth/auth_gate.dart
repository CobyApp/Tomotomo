import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_state.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import '../main_shell/main_shell.dart';

/// Shows login/signup when not authenticated, otherwise [MainShell].
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppAuthState>(
      builder: (context, state, _) {
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.user == null) {
          return state.showSignUp
              ? const SignUpScreen()
              : const LoginScreen();
        }
        return const MainShell();
      },
    );
  }
}
