# P1 build and Android validation

**Date:** 2026-09-13  
**Application commit before P1 changes:** `fb20f125134d381bbc655883008a4f214aebde74`  
**Flutter:** 3.47.4  
**Dart:** 3.13.3  
**Flutter path:** `/home/ubuntu/devtools/flutter`  
**Android SDK:** `/home/ubuntu/devtools/android-sdk`  
**Android compile SDK:** 36  
**Android target SDK:** 35  
**JDK used for Gradle:** OpenJDK 17.0.20 at `/usr/lib/jvm/java-17-openjdk-amd64`

## Completed P1 work

- Installed Flutter 3.47.4 and Dart 3.13.3 from the official Flutter archive.
- Installed Android command-line tools, platform tools, Android platforms 35/36, Build Tools, NDK, and required native build tools.
- Installed Clang 18.1.3, CMake 3.28.3, and Ninja 1.11.1 for the `seika` native hook.
- Added the missing asset directories declared by `pubspec.yaml`.
- Regenerated the missing Flutter Android project files with `flutter create --platforms=android`.
- Preserved the custom Seika/ONNX bridge and merged it into the generated Android structure.
- Migrated the main Manifest to Android embedding v2.
- Added Kotlin DSL Android configuration with application id `com.productchat.aiphotostudio`, ONNX Runtime dependency, ProGuard, and model resource handling.
- Set Gradle to use JDK 17 explicitly.
- Centralized `compileSdk = 36` for Android application and library subprojects, including older plugin projects such as `file_picker`.
- Removed the generated `test/widget_test.dart` because it referenced the nonexistent `MyApp` class and was not a project test.

## Verification results

| Check | Result | Evidence |
|---|---|---|
| Flutter installation | Passed | Flutter 3.47.4 / Dart 3.13.3 |
| Android toolchain | Passed for Android | `flutter doctor -v`: Android SDK 35.0.0, platform android-36, accepted licenses |
| `flutter analyze` | Passed | `No issues found!` |
| `flutter test` | Passed | `+3: All tests passed!` |
| `flutter build apk --debug` | Passed | `Built build/app/outputs/flutter-apk/app-debug.apk` |
| APK size | Recorded | 220,358,067 bytes |
| APK SHA-256 | Recorded | `236afeb8ac984d589662243548ad39cf3388c6b963fbba603878b567911ecde2` |
| Android device/emulator | Not available | Only Linux desktop appears in `flutter devices` |
| APK installation/runtime | Not verified | Requires Android device or emulator |

## APK artifact

`build/app/outputs/flutter-apk/app-debug.apk` was created successfully. This is a debug build using local debug signing; it is not a release artifact and has not been installed or exercised on Android hardware.

## Remaining limitations after P1

- `flutter doctor` still reports Chrome and Linux desktop toolchain gaps; these do not block the Android-first build.
- No Android emulator or physical Android device is available in the current session.
- The APK has not yet passed a launch smoke test, image selection flow, Seika MethodChannel call, LaMa inference, or export flow on Android.
- Build warnings remain for plugins that still apply Kotlin Gradle Plugin rather than Flutter built-in Kotlin support. They are warnings for this Flutter version, not current build failures.
- Release signing is intentionally not configured; the release build still requires a protected keystore and signing decision.

## P1 status

**P1 is complete for local Android build reproducibility:** the project resolves dependencies, analyzes cleanly, passes its current tests, and produces a debug APK. **P1 is not device-validation complete** until an Android emulator or physical device is available.

Next recommended stage: P2 service/operation integration, while adding Android device availability as a prerequisite for LaMa runtime verification.
