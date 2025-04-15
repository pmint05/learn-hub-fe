import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learn_hub/screens/login.dart';
import 'package:learn_hub/screens/register.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: screenHeight / 10,
            left: 0,
            right: 0,
            height: screenHeight / 2.3,
            child: SvgPicture.asset(
              isDark ? 'assets/images/welcome_dark.svg' : 'assets/images/welcome.svg',
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
            ),
          ),

          // Nội dung sau ảnh
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: screenHeight / 2),
                  Text(
                    "Welcome to LearnHub",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Learning has never been easier. From documents to insights – let AI do the work!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: cs.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: BorderSide(color: cs.primary),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Register',
                        style: TextStyle(color: cs.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
