import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glass_keep/widgets.dart';
import 'package:glass_keep/constants.dart';
import 'package:glass_keep/l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
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
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 30),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
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
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

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
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password.';
        } else if (e.code == 'email-already-in-use') {
          message = 'Email already in use.';
        } else {
          message = e.message ?? message;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.accentRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
          const Positioned.fill(child: VisionBackground()),
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
                        // Logo Icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.accentBlue.withValues(alpha: 0.8),
                                AppColors.accentPurple.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentBlue.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.doc_text,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          'Glass Keep',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.secureCloudSync,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Glass Input Card
                        VisionGlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Email Field
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: l10n.email,
                                  hintStyle: TextStyle(
                                    color: AppColors.tertiaryText.withValues(alpha: 0.6),
                                  ),
                                  border: InputBorder.none,
                                  icon: const Icon(
                                    CupertinoIcons.mail,
                                    color: AppColors.secondaryText,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Divider(
                                color: AppColors.secondaryBackground,
                                height: 1,
                              ),
                              const SizedBox(height: 8),
                              // Password Field
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: l10n.password,
                                  hintStyle: TextStyle(
                                    color: AppColors.tertiaryText.withValues(alpha: 0.6),
                                  ),
                                  border: InputBorder.none,
                                  icon: const Icon(
                                    CupertinoIcons.lock,
                                    color: AppColors.secondaryText,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Auth Button
                        _isLoading
                            ? const CupertinoActivityIndicator(
                                color: AppColors.accentBlue,
                                radius: 16,
                              )
                            : _buildAuthButton(l10n),

                        const SizedBox(height: 24),

                        // Toggle Auth Mode
                        TextButton(
                          onPressed: _toggleAuthMode,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accentBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            _isLogin
                                ? l10n.dontHaveAccount
                                : l10n.alreadyHaveAccount,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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

  Widget _buildAuthButton(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentBlue,
              AppColors.accentBlue.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentBlue.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _isLogin ? l10n.login : l10n.signUp,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}
