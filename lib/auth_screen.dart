import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glass_keep/widgets.dart';
import 'package:glass_keep/constants.dart';

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
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
        } else if (e.code == 'weak-password') {
          message = 'Password should be at least 6 characters.';
        } else if (e.code == 'invalid-email') {
          message = 'Invalid email address.';
        } else {
          message = e.message ?? message;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.blur_on, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 24),
              const Text('Glass Keep', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
              const Text('Secure Cloud Sync', style: TextStyle(color: Colors.white38, fontSize: 14)),
              const SizedBox(height: 40),
              
              Form(
                key: _formKey,
                child: VisionGlassCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          hintText: 'Email',
                          hintStyle: TextStyle(color: Colors.white24),
                          border: InputBorder.none,
                          icon: Icon(Icons.email_outlined, color: Colors.white38),
                        ),
                      ),
                      const Divider(color: Colors.white12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(color: Colors.white24),
                          border: InputBorder.none,
                          icon: Icon(Icons.lock_outline, color: Colors.white38),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              _isLoading 
                ? const CircularProgressIndicator(color: Colors.blueAccent)
                : Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _submit,
                          child: Text(_isLogin ? 'Login' : 'Create Account', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login",
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
