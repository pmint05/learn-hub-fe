import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_hub/configs/router_config.dart';
import 'package:learn_hub/const/constants.dart';
import 'package:learn_hub/providers/app_auth_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learn_hub/screens/welcome.dart';
import 'package:learn_hub/screens/register.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final authProvider = Provider.of<AppAuthProvider>(
    context,
    listen: false,
  );
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  String? _emailError;
  String? _passwordError;

  void _onForgotPassword() {
    context.goNamed(AppRoute.forgotPassword.name);
  }

  void _onCreateNewAccount() {
    context.go("/register");
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AppAuthProvider>(context);
    if (authProvider.isAuthed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go("/");
      });
    }
  }

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
                      "Welcome back!",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Please enter your credentials",
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
                          // Email field with validation
                          TextFormField(
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
                                borderSide: BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
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
                          // Password field with validation
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
                                borderSide: BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
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
                            onChanged: (value) {
                              if (_passwordError != null) {
                                setState(() {
                                  _passwordError = null;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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
                        onPressed:
                            _isLoading
                                ? null
                                : () async {
                                  setState(() {
                                    _emailError = null;
                                    _passwordError = null;
                                    _isLoading = true;
                                  });

                                  // Validate form
                                  if (_formKey.currentState!.validate()) {
                                    try {
                                      await authProvider.login(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text,
                                      );
                                      if (context.mounted) {
                                        context.go("/");
                                      }
                                    } catch (e) {
                                      print(e.toString());
                                      // Handle specific auth errors
                                      String message =
                                          e.toString().toLowerCase();
                                      final RegExp regex = RegExp(r'\[(.*?)\]');
                                      final String code =
                                          regex
                                              .firstMatch(message)
                                              ?.group(1)
                                              ?.replaceAll('firebase_', '') ??
                                          '';
                                      print(code);
                                      if (code.isNotEmpty &&
                                          commonFirebaseErrors[code] != null) {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text(
                                                "Error",
                                                textAlign: TextAlign.center,
                                              ),
                                              content: Text(
                                                commonFirebaseErrors[code]!,
                                                textAlign: TextAlign.center,
                                              ),
                                              actionsAlignment: MainAxisAlignment.center,
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text("OK"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Login failed: ${e.toString()}',
                                            ),
                                            backgroundColor: cs.error,
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
                                  } else {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                },
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
                                : const Text("Log in"),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          splashColor: cs.primary.withValues(alpha: 0.12),
                          highlightColor: cs.primary.withValues(alpha: 0.12),
                          onTap: _onForgotPassword,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Forgot Password?",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 18,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: Theme.of(context).dividerColor),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            "Or sign in with",
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
                                    if (credential != null) {
                                      if (context.mounted) {
                                        context.go("/");
                                      }
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Google sign-in failed: ${e.toString()}',
                                        ),
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
                          "Login with Google",
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  splashColor: cs.primary.withValues(alpha: 0.12),
                  highlightColor: cs.primary.withValues(alpha: 0.12),
                  onTap: _onCreateNewAccount,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "CREATE NEW ACCOUNT",
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
