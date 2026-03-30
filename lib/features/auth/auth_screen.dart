import 'package:flutter/material.dart';
import 'package:notes_app/features/auth/login_page.dart';
import 'package:notes_app/features/auth/signup_page.dart';

/// Auth screen that manages login and signup pages
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoginMode = true;

  @override
  Widget build(BuildContext context) {
    return _isLoginMode
        ? LoginPage(
            onSignUpTap: () {
              setState(() => _isLoginMode = false);
            },
          )
        : SignupPage(
            onLoginTap: () {
              setState(() => _isLoginMode = true);
            },
          );
  }
}
