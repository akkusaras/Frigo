import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/frigo_widgets.dart';
import '../../providers/auth_provider.dart';

/// `1. Login` — mock email / Google authentication that lands on the fridge.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitEmail() {
    final email = _emailController.text;
    final password = _passwordController.text;
    setState(() {
      _emailError = AuthNotifier.validateEmail(email);
      _passwordError = AuthNotifier.validatePassword(password);
    });
    final ok = ref.read(authProvider.notifier).signInWithEmail(email, password);
    if (ok) context.goToFridge();
  }

  void _signInWithGoogle() {
    ref.read(authProvider.notifier).signInWithGoogle();
    context.goToFridge();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FrigoLogo(),
                const SizedBox(height: 8),
                Text(
                  'Cook with what you already have.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 40),
                Text('Email', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('login-email'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  onChanged: (_) {
                    if (_emailError != null) setState(() => _emailError = null);
                  },
                  decoration: InputDecoration(
                    hintText: 'you@example.com',
                    errorText: _emailError,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Password', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('login-password'),
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                  },
                  onSubmitted: (_) => _submitEmail(),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    errorText: _passwordError,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _submitEmail,
                  child: const Text('Log in'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                  label: const Text('Continue with Google'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  // Mock sign-up: validates the same fields and signs in.
                  onPressed: _submitEmail,
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
