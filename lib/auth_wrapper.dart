// auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/login_screen.dart';
import 'pages/home_page.dart';
import 'StartPage.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<_AuthState> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    return _AuthState(
      token: token,
      role: role,
      seenOnboarding: seenOnboarding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AuthState>(
      future: _loadAuthState(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final state = snapshot.data!;
        final token = state.token;
        final role = state.role;
        final seenOnboarding = state.seenOnboarding;

        if (token != null && role != null) {
          return HomePage(roleFromLogin: role);
        }

        if (!seenOnboarding) {
          return const StartPages();
        }

        return const LoginScreen();
      },
    );
  }
}

class _AuthState {
  final String? token;
  final String? role;
  final bool seenOnboarding;

  _AuthState({
    required this.token,
    required this.role,
    required this.seenOnboarding,
  });
}
