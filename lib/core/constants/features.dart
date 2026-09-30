/// Compile-time feature switches.
class AppFeatures {
  /// Account sign-in + Supabase cloud sync.
  ///
  /// OFF for the free v1: the app is local-only and never touches the network.
  /// Kept (not deleted) so the planned paid version can switch it back on.
  /// Turning it on also needs, in android/app/src/main/AndroidManifest.xml:
  ///   * `<uses-permission android:name="android.permission.INTERNET"/>`
  ///   * delete the `ACCESS_NETWORK_STATE ... tools:node="remove"` line
  ///   * inside `<activity>`, the Supabase redirect (email confirmation/OAuth):
  ///     ```xml
  ///     <intent-filter>
  ///         <action android:name="android.intent.action.VIEW"/>
  ///         <category android:name="android.intent.category.DEFAULT"/>
  ///         <category android:name="android.intent.category.BROWSABLE"/>
  ///         <data android:scheme="com.pratik.spendcraft" android:host="login-callback"/>
  ///     </intent-filter>
  ///     ```
  /// plus: run supabase/*.sql, custom SMTP + redirect URL in Supabase, and
  /// Data Safety / privacy policy updates for account data (the account-based
  /// versions are described in spendcraft_release/CHECKLIST.md history notes).
  static const cloudSync = false;
}
