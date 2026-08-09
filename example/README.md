# secure_storage_example

Demonstrates the [`secure_storage`](../) package. Type a box name, a key and a
value, pick encrypted or not, then exercise every operation from the buttons.

Android, iOS and Web are all configured.

```sh
flutter pub get

flutter run                # Android or iOS device / emulator
flutter run -d chrome      # Web
```

## What to look at

| File                                  | Shows                                            |
| ------------------------------------- | ------------------------------------------------ |
| `lib/main.dart`                       | Resolving `storagePath` per platform, then DI     |
| `lib/bloc/demo_storage_bloc.dart`     | Folding `Either<Failure, T>` into UI state        |
| `lib/pages/secure_storage_demo_page.dart` | Building the parameter objects from user input |

## Platform notes

- **Android** — `android/app/build.gradle.kts` sets `minSdk = 24` and
  `compileSdk = 37`, both required by `flutter_secure_storage` 11.
- **iOS** — deployment target 13.0.
- **Web** — `storagePath` is `null`, Hive stores boxes in IndexedDB, and
  `listUnencryptedKeys` returns an empty list because there are no box files to
  scan.
