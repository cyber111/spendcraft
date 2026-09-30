class SupabaseConfig {
  // Base project URL only — no `/rest/v1/` suffix; the SDK adds the paths.
  static const url = 'https://nsofypukiopgjnsmlewy.supabase.co';

  // Public anon ("publishable") key. Safe to ship in the app: every table has
  // row-level security, so this key alone can't read or write anyone's data.
  // Never put the service_role key here.
  static const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5zb2Z5cHVraW9wZ2puc21sZXd5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA2NzI2OTEsImV4cCI6MjEwNjI0ODY5MX0.4QA1yIUJtLHoYHxuRqQXzrvJjduLrdd1HAKaxjPgRH8';

  /// Deep link Supabase sends users back to after email confirmation (and
  /// OAuth). Must be listed in Supabase → Authentication → URL Configuration →
  /// Redirect URLs, and matches the intent-filter in AndroidManifest.xml.
  static const authRedirectUrl = 'com.pratik.spendcraft://login-callback';

  /// Google sign-in is off until the Google provider is configured in Supabase
  /// (OAuth client + release SHA-1). While false the button is hidden.
  static const googleSignInEnabled = false;

  /// False while the placeholders are still in place; auth/sync stay disabled
  /// and the app runs guest-only.
  static bool get isConfigured =>
      url != 'YOUR_SUPABASE_URL' &&
      anonKey != 'YOUR_SUPABASE_ANON_KEY' &&
      url.isNotEmpty &&
      anonKey.isNotEmpty;
}
