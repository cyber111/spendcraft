import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../../services/sync_service.dart';
import '../local/hive_service.dart';

/// Wraps Supabase auth and the guest/logged-in transition.
class AuthRepository {
  bool get isAvailable => SupabaseService.isReady;

  User? get currentUser => SupabaseService.currentUser;

  Stream<AuthState>? get authChanges => SupabaseService.authStream;

  bool get hasLocalData => HiveService.txns.isNotEmpty;

  Future<User> signIn(String email, String password) async {
    final res = await SupabaseService.signInWithEmail(email.trim(), password);
    final user = res.user;
    if (user == null) throw const AuthException('Sign in failed.');
    return user;
  }

  Future<User?> signUp(String email, String password) async {
    final res = await SupabaseService.signUpWithEmail(email.trim(), password);
    final user = res.user;
    // With email confirmation on, Supabase hides "already registered" (to
    // prevent account enumeration): it returns a placeholder user with no
    // identities and sends no email. Surface that instead of "check your email".
    if (user != null && res.session == null && (user.identities?.isEmpty ?? false)) {
      throw const AuthException('User already registered', code: 'user_already_exists');
    }
    // If email confirmation is required, `session` is null and `user` is set.
    return user;
  }

  Future<void> signInWithGoogle() => SupabaseService.signInWithGoogle();

  /// Deletes the account and everything synced to it, then wipes this
  /// device's copy so nothing of the deleted account remains.
  Future<void> deleteAccount() async {
    await SupabaseService.deleteOwnAccount();
    await SyncService.instance.clearQueues();
    await HiveService.clearAllData();
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();
    // Keep local cache — user simply returns to guest mode.
  }

  /// Called after a successful login. Decides whether to upload local data
  /// (caller asks the user first) and then reconciles with the server.
  Future<void> onLoggedIn({required bool uploadLocal}) async {
    final sync = SyncService.instance;
    if (uploadLocal) {
      await sync.uploadAllLocal();
    } else {
      // Discard local guest data so the account's data is the source of truth.
      await HiveService.txns.clear();
      await HiveService.budgets.clear();
    }
    await sync.reconcile();
  }

  static String friendlyError(Object e) {
    // Raw error to logcat so failures can be diagnosed on a device.
    debugPrint('Auth error: $e');
    if (e is AuthException) {
      switch (e.code) {
        case 'invalid_credentials':
          return 'Wrong email or password.';
        case 'user_already_exists':
        case 'email_exists':
          return 'That email is already registered. Try signing in.';
        case 'email_not_confirmed':
          return 'Please confirm your email first — check your inbox.';
        case 'weak_password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'email_address_invalid':
          return 'Please enter a valid email address.';
        case 'email_address_not_authorized':
          return "This email can't receive sign-up mail yet (the server's "
              'email provider is restricted). Try another address.';
        case 'over_email_send_rate_limit':
          return 'Too many sign-up emails were sent. Please wait a while and try again.';
        case 'over_request_rate_limit':
          return 'Too many attempts. Please wait a minute and try again.';
        case 'signup_disabled':
        case 'email_provider_disabled':
          return 'Sign-ups are currently disabled.';
      }
      // Unknown code: show Supabase's own message rather than guessing.
      return e.message;
    }
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
