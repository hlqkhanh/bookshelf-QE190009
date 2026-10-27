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

Android Emulator workflow against the real Firebase project: passed. The test
created the grader account and five sample books, checked duplicate rejection,
favorite persistence, every filter/search control, summary, edit validation,
atomic title rename, confirmed deletion, logout/login persistence, and a separate
empty account. Four sample books remain in the grader account after deletion.

The separate `integration_test/account_test.dart` also passed: existing accounts
remain isolated, the deleted title stays absent, and Back on List does not return
to Login. Screenshots were captured from these actual device sessions and from
the published Firebase Console, never from mockups.

To capture the real workflow using a dedicated Firebase test account:

```powershell
flutter drive --driver=test_driver/app_driver.dart --target=integration_test/app_test.dart -d DEVICE_ID --dart-define-from-file=report.local.json
```

This test writes to the configured real Firebase project, creates dedicated test
accounts and sample books, edits/deletes the Dune sample, and saves genuine
device screenshots in `screenshots/`. Credentials stay in the ignored local JSON.
