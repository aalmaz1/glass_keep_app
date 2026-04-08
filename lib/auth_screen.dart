import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glass_keep/styles.dart';
import 'package:glass_keep/constants.dart';
import 'package:glass_keep/l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 30), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } catch (e) {
      if (!mounted) return;
      String message = 'Error occurred';
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') message = 'No user found for that email.';
        else if (e.code == 'wrong-password') message = 'Wrong password.';
        else if (e.code == 'email-already-in-use') message = 'Email already in use.';
        else if (e.code == 'weak-password') message = 'Password should be at least 6 characters.';
        else message = e.message ?? message;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.accentRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleAuthMode() {
    setState(() => _isLogin = !_isLogin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: LightBackground()),
          Positioned.fill(
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), child: Container(color: Colors.transparent)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: [AppColors.accentBlue.withValues(alpha: 0.8), AppColors.accentBlue.withValues(alpha: 0.6)],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: const Icon(CupertinoIcons.doc_text, size: 48, color: Colors.white),
                        ),
                        const SizedBox(height: 32),
                        
                        // Title
                        Text('Glass Keep', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryText, letterSpacing: -0.5)),
                        const SizedBox(height: 8),
                        Text(l10n.secureCloudSync, style: const TextStyle(color: AppColors.secondaryText, fontSize: 15)),
                        const SizedBox(height: 48),
                        
                        // Input Card
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          hasBlur: false,
                          child: Column(
                            children: [
                              GlassTextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                hintText: l10n.email,
                                icon: CupertinoIcons.mail,
                                hasBlur: false,
                              ),
                              const SizedBox(height: 12),
                              GlassTextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                                hintText: l10n.password,
                                icon: CupertinoIcons.lock,
                                hasBlur: false,
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash, color: AppColors.tertiaryText, size: 20),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Login Button
                        _isLoading
                            ? const CupertinoActivityIndicator(color: AppColors.accentBlue, radius: 16)
                            : GlassButton(text: _isLogin ? l10n.login : l10n.signUp, onPressed: _submit),
                        
                        const SizedBox(height: 24),
                        
                        // Toggle
                        TextButton(
                          onPressed: _toggleAuthMode,
                          style: TextButton.styleFrom(foregroundColor: AppColors.accentBlue),
                          child: Text(_isLogin ? l10n.dontHaveAccount : l10n.alreadyHaveAccount, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
