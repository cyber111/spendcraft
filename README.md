# SpendCraft

Offline-first expense tracker for Android (Flutter). Works fully as a **guest** with
no account and no network; optionally sign in to back up and sync via Supabase.

## Run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerates Hive adapters
flutter run
```

Tests: `flutter test`

## Architecture

```
lib/
├── core/            theme, colours, default categories, ₹ formatting
├── data/
│   ├── models/      Hive models (Txn, Category, Budget) + Supabase (de)serialisation
│   ├── local/       HiveService — boxes, seeding, settings
│   └── repositories/
│       ├── txn_repository.dart   ← the ONLY data entry point for the UI
│       └── auth_repository.dart
├── services/        SupabaseService (client + queries), SyncService (push/pull/queue)
├── logic/           AuthBloc, TxnsBloc, BudgetBloc, ThemeCubit
└── presentation/    screens + widgets
```

**Key rule:** the UI never checks auth state for data operations. It calls
`TxnRepository.addTxn()` etc., and the repository decides whether to also
queue a Supabase sync. Hive is always written first, so the UI never blocks on
the network.

## Sync model (V1)

- Guest → Hive only.
- Logged in → write to Hive, mark `synced=false`, then `SyncService.flush()`
  upserts to Supabase in the background.
- Deletes made offline are queued in the settings box and replayed on reconnect
  (`connectivity_plus`).
- On login / app open: `pullAll()` merges remote rows into Hive.
  **Last-write-wins by `updated_at`.** Local unsynced rows that are newer survive
  and get pushed.
- First login with existing guest data prompts "Upload your existing data?".
- Sign out → back to guest mode; the local cache is kept.

## Enabling cloud sync

Until this is done the app runs guest-only and the Sign In screen shows a
"not configured" notice.

1. Create a Supabase project.
2. Run [`supabase_schema.sql`](supabase_schema.sql) in **SQL Editor**.
   RLS policies ensure users only ever see their own rows.
3. Copy **Project URL** and **anon / publishable key** (Settings → API) into
   [`lib/core/constants/supabase_config.dart`](lib/core/constants/supabase_config.dart).
4. Email/password sign-in works immediately.

### Google sign-in (optional, TODO)

- Supabase → Auth → URL Configuration → add redirect
  `com.pratik.spendcraft://login-callback`
  (the Android intent-filter is already in `AndroidManifest.xml`).
- Google Cloud → create an Android OAuth client with package
  `com.pratik.spendcraft` and your **release** SHA-1.
- Supabase → Auth → Providers → enable Google with the web client ID/secret.

## Play Store notes

- Permissions: `INTERNET` only.
- **Data Safety:** in guest mode nothing leaves the device. If a user signs in,
  the app collects **email address** and **financial info (transactions)**,
  stored in Supabase, encrypted in transit, user-deletable (delete account /
  clear data). Declare accordingly.
- Ads are intentionally off for v1.
- Icons: `assets/icon/app_icon.png` (1024², source) → `dart run flutter_launcher_icons`.
