import 'package:flutter/material.dart';
import 'package:learn_hub/screens/app.dart';
import 'package:learn_hub/screens/welcome.dart';
import 'package:provider/provider.dart';
import 'package:learn_hub/providers/app_auth_provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);

    if (authProvider.isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authProvider.shouldShowWelcomeScreen()) {
      return WelcomeScreen();
    }

    return App();
  }
}