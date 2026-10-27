# Verification — 27 October 2026

- `flutter analyze`: passed, no issues.
- `flutter test`: 8 tests passed (validation, normalized identity, combined filters,
  ordering, summary, phone layout, submit timing, and the detail rename regression).
- Firestore Emulator: all 5 test groups passed. Invalid writes use canonical IDs
  where appropriate, so data validation is checked independently of ID validation.
  Tests cover owner CRUD, anonymous/other-user denial, spoofed owner, invalid
  fields, duplicate case variants, separate owners, and atomic rename.
- `flutter build apk --release`: passed with Flutter 3.47.8 / Dart 3.13.7.
- Firestore rules published to the student's `bookshelf-d1ae3` project.

The first Windows build exposed Kotlin's different-drive incremental-cache error
(project on D:, Pub cache on C:). The project disables Kotlin incremental
compilation to keep fresh-copy builds reliable on that layout.

Real-device workflow verification and report screenshots are being collected
with `integration_test/app_test.dart`. This file will be updated with the actual
result before final submission. Passing local tests alone does not prove the
published APK link, the Firebase Console screenshots, or report completeness.

To capture the real workflow using a dedicated Firebase test account:

```powershell
flutter drive --driver=test_driver/app_driver.dart --target=integration_test/app_test.dart -d DEVICE_ID --dart-define-from-file=report.local.json
```

This test writes to the configured real Firebase project, creates dedicated test
accounts and sample books, edits/deletes the Dune sample, and saves genuine
device screenshots in `screenshots/`. Credentials stay in the ignored local JSON.
