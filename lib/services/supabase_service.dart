import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/features.dart';
import '../core/constants/supabase_config.dart';

/// Thin wrapper around the Supabase client. Safe to use even when Supabase
/// has not been configured — [isReady] is false and all calls are no-ops.
class SupabaseService {
  static bool _initialized = false;

  static bool get isReady =>
      AppFeatures.cloudSync && _initialized && SupabaseConfig.isConfigured;

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => isReady ? client.auth.currentUser : null;

  static bool get isLoggedIn => currentUser != null;

  static Future<void> init() async {
    if (!AppFeatures.cloudSync || !SupabaseConfig.isConfigured) return;
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // Supabase now calls this the "publishable key"; same value, same place
        // in the dashboard (Settings → API).
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.anonKey,
      );
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  static Stream<AuthState>? get authStream =>
      isReady ? client.auth.onAuthStateChange : null;

  // ---- Auth -------------------------------------------------------------

  static Future<AuthResponse> signInWithEmail(String email, String password) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUpWithEmail(String email, String password) {
    return client.auth.signUp(
      email: email,
      password: password,
      // Confirmation link opens the app, which finishes sign-in via the
      // deep link instead of landing on the project's Site URL.
      emailRedirectTo: SupabaseConfig.authRedirectUrl,
    );
  }

  /// Google OAuth via Supabase.
  /// TODO: configure the OAuth redirect URL and Android SHA-1 in the
  /// Supabase dashboard + Google Cloud console before enabling in production.
  static Future<bool> signInWithGoogle() {
    return client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: SupabaseConfig.authRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  static Future<void> signOut() => client.auth.signOut();

  /// Permanently deletes the signed-in account server-side (see
  /// `delete_own_account()` in supabase_schema.sql; rows cascade).
  static Future<void> deleteOwnAccount() async {
    await client.rpc('delete_own_account');
    // The account is gone, so a server-side sign-out would fail; just drop
    // the local session.
    await client.auth.signOut(scope: SignOutScope.local);
  }

  // ---- Data -------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> fetchTxns(String userId) async {
    final rows = await client.from('transactions').select().eq('user_id', userId);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<void> upsertTxns(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await client.from('transactions').upsert(rows);
  }

  static Future<void> deleteTxn(String id) async {
    await client.from('transactions').delete().eq('id', id);
  }

  static Future<List<Map<String, dynamic>>> fetchCategories(String userId) async {
    final rows = await client.from('categories').select().eq('user_id', userId);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<void> upsertCategories(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await client.from('categories').upsert(rows);
  }

  static Future<void> deleteCategory(String id, String userId) async {
    await client.from('categories').delete().eq('id', id).eq('user_id', userId);
  }

  static Future<List<Map<String, dynamic>>> fetchBudgets(String userId) async {
    final rows = await client.from('budgets').select().eq('user_id', userId);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<void> upsertBudgets(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await client.from('budgets').upsert(rows);
  }

  static Future<void> deleteBudget(String id) async {
    await client.from('budgets').delete().eq('id', id);
  }
}
