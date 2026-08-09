# secure_storage_example

Demonstrates the [`secure_storage`](../) package. Type a box name, a key and a
value, pick encrypted or not, then exercise every operation from the buttons.

Android, iOS and Web are all configured.

```sh
flutter pub get

flutter run                # Android or iOS device / emulator
flutter run -d chrome      # Web
flutter run -d linux       # Linux desktop
```

Integration tests against the real plugin and real Hive files:

```sh
flutter test integration_test -d linux
```

## Troubleshooting

**`CMake Error ... file INSTALL cannot find .../build/native_assets/linux`**

Stale CMake state, usually after the `build/` directory was removed by hand.
The generated `cmake_install.cmake` still refers to a path that no longer
exists. Fix it with:

```sh
flutter clean && flutter pub get
```

Use `flutter clean` rather than `rm -rf build` — the latter leaves the
generated CMake files pointing at deleted paths.

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
- **Linux** — needs `libsecret-1` and GTK3 to build, and a running Secret
  Service at runtime. The integration test skips its keystore-backed cases when
  none is available, so the suite stays honest instead of failing.

  If you hit `secret_service_get_sync: The name is not activatable`, nothing on
  the session bus is providing the Secret Service. Either install
  `gnome-keyring`, or use KWallet: set `Enabled=true` in `~/.config/kwalletrc`,
  then make sure `ksecretd` is actually running. Note that `ksecretd` exits
  immediately if started attached to a terminal — a desktop session normally
  launches it via D-Bus activation.
- **Web** — `storagePath` is `null` and Hive stores boxes in IndexedDB.
  `listUnencryptedKeys` enumerates those databases, so it works here too —
  except on Firefox, which lacks `indexedDB.databases()`.
