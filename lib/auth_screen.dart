import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glass_keep/widgets.dart';
import 'package:glass_keep/constants.dart' show AppColors, AppUtils;
import 'package:glass_keep/providers.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validate and submit form
  Future<void> _submit() async {
    final currentState = _formKey.currentState;
    if (currentState == null || !currentState.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (!context.mounted) return;
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (!context.mounted) return;
      }
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      setState(() {
        _errorMessage = e.message ?? 'An error occurred during authentication';
      });
    } catch (e) {
      if (!context.mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred';
      });
    } finally {
      if (context.mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = GlassAnimationProvider.of(context);
    final themeColor = provider?.themeColor ?? AppColors.obsidianBlack;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: VisionBackground(
              backgroundColor: themeColor,
              blobColors: provider?.blobColors,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
              child: VisionGlassCard(
                useDistortion: false,
                borderRadius: 24,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App Logo
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.accentBlue.withValues(alpha: 0.8),
                              AppColors.accentDeepPurple.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentBlue.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.blur_on,
                          size: 40,
                          color: Colors.white,
                          shadows: AppColors.iconShadows,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Glass Keep',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isLogin ? 'Welcome Back' : 'Create Account',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin 
                        ? 'Sign in to sync your notes' 
                        : 'Join us to keep your thoughts safe',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                              prefixIcon: const Icon(
                                CupertinoIcons.envelope_fill, 
                                color: Colors.white, 
                                size: 22, 
                                shadows: AppColors.iconShadows
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.accentDeepPurple, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.red, width: 1.5),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              }
                              if (!AppUtils.isValidEmail(value)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                              prefixIcon: const Icon(
                                CupertinoIcons.lock_fill, 
                                color: Colors.white, 
                                size: 22, 
                                shadows: AppColors.iconShadows
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? CupertinoIcons.eye_fill : CupertinoIcons.eye_slash_fill,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  size: 20,
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.accentDeepPurple, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.red, width: 1.5),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (!AppUtils.isValidPassword(value)) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          _errorMessage ?? '',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 255, 100, 100),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accentBlue,
                            ),
                          )
                        : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                _submit();
                              },
                              child: Text(
                                _isLogin ? 'Login' : 'Create Account',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Toggle login/signup
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              setState(() => _isLogin = !_isLogin);
                            },
                      child: Text(
                        _isLogin
                            ? "Don't have an account? Sign up"
                            : 'Already have an account? Login',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'SYSTEM-REBORN-${AppColors.appVersion}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
