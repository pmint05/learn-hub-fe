import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_hub/const/constants.dart';
import 'package:learn_hub/providers/app_auth_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _emailError;

  void _onBackToLogin() {
    context.go("/login");
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _emailError = null;
    });

    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);

      await authProvider.sendPasswordResetEmail(_emailController.text.trim());

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Check your email"),
              content: const Text(
                "If an account with that email exists, a password reset link has been sent to your email address. Please check your inbox and follow the instructions to reset your password.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go("/login");
                  },
                  child: const Text("Back to Sign In"),
                ),
              ],
            );
          },
        );

        _emailController.clear();
      }
    } catch (e) {
      String message = e.toString().toLowerCase();
      if (message.contains('user-not-found')) {
        setState(() => _emailError = 'No account found with this email');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset email: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Forgot Password",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Enter your email address and we'll send you a link to reset your password",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Email',
                          hintStyle: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                          prefixIcon: Icon(
                            PhosphorIconsRegular.at,
                            color: cs.onSurface.withValues(alpha: 0.8),
                          ),
                          filled: true,
                          fillColor: cs.surface,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: cs.onSurface.withValues(alpha: 0.2),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: cs.primary,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red, width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorText: _emailError,
                        ),
                        style: TextStyle(color: cs.onSurface),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!emailRegex.hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (_emailError != null) {
                            setState(() {
                              _emailError = null;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: cs.primary,
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _isLoading ? null : _sendPasswordResetEmail,
                        child:
                            _isLoading
                                ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: cs.onPrimary,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text("Send Reset Password Link"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  splashColor: cs.primary.withValues(alpha: 0.12),
                  highlightColor: cs.primary.withValues(alpha: 0.12),
                  onTap: _onBackToLogin,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "BACK TO LOGIN",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
