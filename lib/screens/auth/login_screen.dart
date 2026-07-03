import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _Mode { signIn, signUp }

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _Mode _mode = _Mode.signIn;
  bool _submitting = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;

    setState(() {
      _submitting = true;
      _error = null;
      _info = null;
    });

    try {
      final auth = Supabase.instance.client.auth;
      if (_mode == _Mode.signIn) {
        await auth.signInWithPassword(email: email, password: password);
      } else {
        await auth.signUp(email: email, password: password);
        if (mounted) {
          setState(() {
            _info = 'Check your email to confirm your account, then sign in.';
            _mode = _Mode.signIn;
          });
        }
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.outerBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RemindMD', style: AppFonts.header(size: 30)),
                    const SizedBox(height: 6),
                    Text(
                      'Meds, supplements, practices, and appointments — all in one rail.',
                      style: AppFonts.body(size: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      onSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: AppFonts.body(size: 12.5, color: AppColors.warning)),
                    ],
                    if (_info != null) ...[
                      const SizedBox(height: 12),
                      Text(_info!, style: AppFonts.body(size: 12.5, color: AppColors.herbalSupplement)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: AppColors.surface,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface),
                              )
                            : Text(_mode == _Mode.signIn ? 'Sign in' : 'Create account'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: _submitting
                            ? null
                            : () => setState(() {
                                  _mode = _mode == _Mode.signIn ? _Mode.signUp : _Mode.signIn;
                                  _error = null;
                                  _info = null;
                                }),
                        child: Text(
                          _mode == _Mode.signIn ? 'Need an account? Sign up' : 'Have an account? Sign in',
                          style: AppFonts.body(size: 12.5, color: AppColors.pharma),
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
    );
  }
}
