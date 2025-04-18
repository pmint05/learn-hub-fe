import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_hub/const/constants.dart';
import 'package:learn_hub/providers/app_auth_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learn_hub/screens/login.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  void _onAlreadyHaveAccount() {
    context.go("/login");
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
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
                      "Signup",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Create an account to get started.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 12,
                        children: [
                          // Username
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              hintText: 'Username',
                              hintStyle: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                              contentPadding: EdgeInsets.zero,
                              prefixIcon: Icon(
                                PhosphorIconsRegular.user,
                                color: cs.onSurface.withValues(alpha: 0.8),
                              ),
                              filled: true,
                              fillColor: cs.surface,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: cs.onSurface.withValues(alpha: 0.2),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: cs.primary,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            style: TextStyle(color: cs.onSurface),
                          ),
                          // Email
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                              contentPadding: EdgeInsets.zero,
                              prefixIcon: Icon(
                                PhosphorIconsRegular.at,
                                color: cs.onSurface.withValues(alpha: 0.8),
                              ),
                              filled: true,
                              fillColor: cs.surface,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: cs.onSurface.withValues(alpha: 0.2),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: cs.primary,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
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
                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                              contentPadding: EdgeInsets.zero,
                              prefixIcon: Icon(
                                PhosphorIconsRegular.lockKey,
                                color: cs.onSurface.withValues(alpha: 0.8),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? PhosphorIconsRegular.eye
                                      : PhosphorIconsRegular.eyeClosed,
                                  color: cs.onSurface.withValues(alpha: 0.8),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: cs.surface,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: cs.onSurface.withValues(alpha: 0.2),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: cs.primary,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              errorText: _passwordError,
                            ),
                            style: TextStyle(color: cs.onSurface),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          // Confirm Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              hintText: 'Confirm Password',
                              hintStyle: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                              contentPadding: EdgeInsets.zero,
                              prefixIcon: Icon(
                                PhosphorIconsRegular.lockKey,
                                color: cs.onSurface.withValues(alpha: 0.8),
                              ),
                              filled: true,
                              fillColor: cs.surface,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: cs.onSurface.withValues(alpha: 0.2),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: cs.primary,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              errorText: _confirmPasswordError,
                            ),
                            style: TextStyle(color: cs.onSurface),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Register button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: cs.primary,
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed:
                            _isLoading
                                ? null
                                : () async {
                                  if (_formKey.currentState?.validate() !=
                                      true) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    return;
                                  }
                                  if (_emailController.text.isNotEmpty &&
                                      _passwordController.text.isNotEmpty) {
                                    if (_passwordController.text !=
                                        _confirmPasswordController.text) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Passwords do not match',
                                          ),
                                          backgroundColor: cs.error,
                                        ),
                                      );
                                      return;
                                    }

                                    try {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      final authProvider =
                                          Provider.of<AppAuthProvider>(
                                            context,
                                            listen: false,
                                          );
                                      await authProvider.register(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text,
                                      );
                                      if (context.mounted) {
                                        context.go("/");
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Registration failed: ${e.toString()}',
                                          ),
                                          backgroundColor: cs.error,
                                        ),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    }
                                  } else {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                },
                        child:
                            _isLoading
                                ? CircularProgressIndicator(
                                  color: cs.onPrimary,
                                  strokeWidth: 2,
                                )
                                : const Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Or sign in with
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: Theme.of(context).dividerColor),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            "Or",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: Theme.of(context).dividerColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Google button (SVG)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: cs.surface,
                          side: BorderSide(color: cs.surfaceDim),
                          elevation: 0,
                        ),
                        onPressed:
                            _isLoading
                                ? null
                                : () async {
                                  try {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    final authProvider =
                                        Provider.of<AppAuthProvider>(
                                          context,
                                          listen: false,
                                        );
                                    final credential =
                                        await authProvider.signInWithGoogle();
                                    if (credential != null && context.mounted) {
                                      context.go("/");
                                    }
                                  } catch (e) {
                                    print(e);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Google sign-in failed: ${e.toString()}',
                                        ),
                                        backgroundColor: cs.error,
                                      ),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  }
                                },
                        icon: SvgPicture.asset(
                          'assets/images/google.svg',
                          height: 24,
                        ),
                        label: Text(
                          "Continue with Google",
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),

            // Footer: chuyển sang LoginScreen khi nhấn "ALREADY HAVE AN ACCOUNT"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _onAlreadyHaveAccount,
                  splashColor: cs.primary.withValues(alpha: 0.12),
                  highlightColor: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "ALREADY HAVE AN ACCOUNT",
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
