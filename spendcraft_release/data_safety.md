# SpendCraft — Data Safety form answers

Play Console → **App content → Data safety**.
Profile: **all-local, no account, no ads, no analytics, no INTERNET permission.**
This is the simplest possible form.

> Keep consistent with `privacy_policy.html` — Google cross-checks the two.

## Answers

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |

That's the whole form: answering **No** skips the data-type, encryption and deletion questions.
Review the summary Play generates ("No data collected · No data shared") and submit.

## Why "No" is accurate

- All data lives in on-device storage (Hive); nothing is transmitted.
- The release APK declares **no `INTERNET` permission** (verified with `aapt2 dump permissions`),
  so the app physically can't send data. Fonts are bundled in the app.
- No ads, analytics, crash reporting or other third-party SDKs that phone home.
- **CSV export** is a user-initiated share via the Android share sheet — Play explicitly exempts
  user-initiated transfers.
- The **privacy policy link** opens the user's browser; the browser loads the page, not SpendCraft.
- The Supabase SDK is compiled in but switched off (`AppFeatures.cloudSync = false`) and can't run
  without network access.

## Related Play Console sections

| Section | Answer |
|---|---|
| **Data deletion** | Not applicable — the app has no accounts. (If asked: users delete data via Settings → Clear all data or by uninstalling.) |
| **App access** | All functionality is available without special access / login. |
| **Ads** | No ads. |

## When the paid version adds cloud sync

This form must change **before** that release: declare Email address, User IDs and Other financial
info (optional, not shared, encrypted in transit, deletable), add the account-deletion URL, restore
the account-based privacy policy, and ship in-app account deletion (already built, behind
`AppFeatures.cloudSync`).
