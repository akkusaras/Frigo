import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_provider.dart';

/// Mock authentication session. The state is the signed-in email, or `null`
/// when signed out. Swap for Firebase Auth without touching the UI.
final authProvider = NotifierProvider<AuthNotifier, String?>(AuthNotifier.new);

class AuthNotifier extends Notifier<String?> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  String? build() => null;

  bool get isSignedIn => state != null;

  /// Error message for [email], or `null` when it is valid.
  static String? validateEmail(String email) {
    final value = email.trim();
    if (value.isEmpty) return 'Enter your email';
    if (!_emailPattern.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  /// Error message for [password], or `null` when it is valid.
  static String? validatePassword(String password) {
    if (password.isEmpty) return 'Enter your password';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  /// Signs in with email and password. Returns `true` on success.
  bool signInWithEmail(String email, String password) {
    if (validateEmail(email) != null || validatePassword(password) != null) {
      return false;
    }
    state = email.trim().toLowerCase();
    return true;
  }

  /// Mock Google sign-in: always succeeds as the seeded user.
  void signInWithGoogle() => state = ref.read(profileProvider).email;

  void signOut() => state = null;
}
