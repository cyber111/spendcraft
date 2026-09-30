# SpendCraft v1.0.0 — Play Store submission checklist

**v1 scope: free, fully local.** No account, no sync, no INTERNET permission.
Cloud sync is planned for a future paid version (`AppFeatures.cloudSync`, currently `false`).

Legend: ✅ done · ⬜ you still need to do

## App

- ✅ Login/sync switched off behind `AppFeatures.cloudSync` (code kept for the paid version)
- ✅ No `INTERNET` / network-state permission in the release APK (verified with `aapt2 dump permissions`)
- ✅ Inter + Space Grotesk bundled (`assets/google_fonts/`, OFL licences registered); runtime font download disabled
- ✅ Settings → Privacy policy opens the hosted URL in the browser
- ✅ Release signing wired in `android/app/build.gradle.kts` (reads `android/key.properties`, git-ignored)
- ⬜ Create the upload keystore + `android/key.properties` — steps in `android/key.properties.example`
- ⬜ Build: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`
- ⬜ versionCode 1 / versionName 1.0.0 (`pubspec.yaml` `version: 1.0.0+1`); bump `+N` for every upload
- ⬜ Enrol in **Play App Signing** (default) when creating the first release
- ⬜ Commit the code — the repo has no commits yet

## Privacy policy

- ✅ `privacy_policy.html` — local-only, "no data collected"
- ⬜ Host it at `https://cyber111.github.io/spendcraft/privacy.html`
  → create a GitHub repo `spendcraft` (or a `docs/` folder), add the file as `privacy.html`,
  Settings → Pages → deploy from `main`. The app already links to this URL
  (`lib/core/constants/app_links.dart`) — change both if you use another address.
- ⬜ Paste the URL into Play Console → **Store settings → Privacy policy**

## Store listing

- ✅ Name, short + full description, release notes → `listing.md`
- ✅ Icon 512×512 → `icon_512x512.png`
- ✅ Feature graphic 1024×500 → `feature_graphic_1024x500.png`
- ✅ 4 phone screenshots 1080×1920 → `screenshots/01–04.png` (Home, Stats, Budget, Dark mode)
- ⬜ Optional: capture a current Settings screen ("Stored on this device only") for a 5th screenshot
- ⬜ Upload everything; contact email pjpratikjain15@gmail.com

## App content (Policy → App content)

- ⬜ **Data safety:** "Does your app collect or share data?" → **No** (see `data_safety.md`)
- ⬜ **Data deletion:** not applicable (no accounts)
- ⬜ **App access:** all functionality available without login
- ⬜ **Ads:** No
- ⬜ **Content rating (IARC):** answer No throughout → expected **Everyone / 3+**
- ⬜ **Target audience:** 18+
- ⬜ **Financial features:** No (tracker only — doesn't move money, lend, or give advice)
- ⬜ Government / Health / News: No

## Release

- ✅ Release notes → `listing.md`
- ⬜ Countries: India (+ any others)
- ⬜ New developer accounts: **closed testing with ≥12 testers for 14 days** before production
- ⬜ Upload AAB → review → **Submit**

## Before the paid cloud-sync version

Everything below is built but dormant; do it only when turning `AppFeatures.cloudSync` on:

- Restore INTERNET permission + login-callback intent-filter (exact snippet in `features.dart`)
- Run `supabase/2026-09-30_delete_account.sql`; configure custom SMTP, Site URL, redirect URL
- Test sign-up → upload → sync, offline queue, and Delete account end to end
- Update Data Safety (Email, User IDs, Other financial info; data deletion URL) and the privacy
  policy **before** releasing that version

## Regenerating assets

`python3 make_assets.py` (needs Pillow) rebuilds screenshots, icon and feature graphic from
`source/` and `../assets/icon/`.
