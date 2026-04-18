import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.onSubmit,
    this.onGoogleSignIn,
    this.onAppleSignIn,
  });

  final Future<void> Function(String email, String password, bool isLogin)?
      onSubmit;
  final Future<void> Function()? onGoogleSignIn;
  final Future<void> Function()? onAppleSignIn;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLogin = true;
  bool _obscured = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      if (widget.onSubmit != null) {
        await widget.onSubmit!(
          _emailController.text,
          _passwordController.text,
          _isLogin,
        );
      } else {
        final auth = context.read<AuthService>();
        if (_isLogin) {
          await auth.signIn(_emailController.text, _passwordController.text);
        } else {
          await auth.signUp(_emailController.text, _passwordController.text);
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF059669),
              Color(0xFF065F46),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const Spacer(),
                        const Icon(
                          Icons.spa_rounded,
                          size: 72,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Calorie Tracker',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Know what you eat. Own your goals.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscured,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() => _obscured = !_obscured);
                                    },
                                    icon: Icon(
                                      _obscured
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                  ),
                                ),
                              ),
                              if (!_isLogin) ...[
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscured,
                                  decoration: const InputDecoration(
                                    labelText: 'Confirm Password',
                                  ),
                                ),
                              ],
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: _submit,
                                child: Text(
                                  _isLogin ? 'Sign In' : 'Create Account',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                    _error = null;
                                  });
                                },
                                child: Text(
                                  _isLogin
                                      ? "Don't have an account? Create one"
                                      : 'Already have an account? Sign in',
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Row(
                                children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8),
                                    child: Text('or continue with'),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        if (widget.onGoogleSignIn != null) {
                                          await widget.onGoogleSignIn!();
                                          return;
                                        }
                                        await context
                                            .read<AuthService>()
                                            .signInWithGoogle();
                                      },
                                      icon: const Icon(Icons.g_mobiledata),
                                      label: const Text('Continue with Google'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        if (widget.onAppleSignIn != null) {
                                          await widget.onAppleSignIn!();
                                          return;
                                        }
                                        await context
                                            .read<AuthService>()
                                            .signInWithApple();
                                      },
                                      icon: const Icon(Icons.apple),
                                      label: const Text('Continue with Apple'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
