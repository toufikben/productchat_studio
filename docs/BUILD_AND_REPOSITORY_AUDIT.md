# Build environment and repository audit

## Date

2026-09-13.

## Build environment

Flutter 3.47.4 and Dart 3.13.3 are installed under `/home/ubuntu/devtools/flutter`. Android SDK command-line tools, API 35 and API 36, platform tools, and accepted Android licenses are available under `/home/ubuntu/devtools/android-sdk`. Clang 18.1.3, CMake 3.28.3, and Ninja 1.11.1 are installed so the `seika` native asset hook can build on Linux.

`flutter doctor` still reports non-Android gaps for Chrome and the Linux desktop GTK toolchain. Those do not block the Android-first path. A physical Android device or emulator is not available in this sandbox.

## Verification

The following commands completed successfully after dependency repair:

```text
flutter pub get
flutter gen-l10n
flutter analyze  -> No issues found!
flutter test    -> All tests passed!
```

The test suite currently contains one automated safety test for invalid image input. Native Android execution, APK assembly, and device tests are still pending.

## Dependency repairs

The project was updated from `intl ^0.19.0` to `intl ^0.20.3` to match Flutter 3.47.4. Unused `build_runner`, `riverpod_generator`, and `hive_generator` constraints were removed because the repository contains no generated Riverpod or Hive annotations and those constraints were incompatible with Dart 3.13. Runtime Riverpod and Hive packages remain available.

## Repository audit findings

The repository is clean and synchronized with GitHub before the audit. Required structural paths from the supplied verification specification exist, including Android, iOS, Web, localization, bridge, service, and Smart Analysis paths.

The following items are not yet production-complete and remain explicitly tracked for later implementation: several feature screens are scaffold-only; model URLs still contain `YOUR_ORG`; the Seika Dart bridge has a working Android CPU baseline but not the verified MI-GAN/LaMa/Real-ESRGAN ONNX sessions; the Hugging Face model repository has not been created; and real-device, billing, iOS, and Web execution have not been validated.

These are recorded as gaps rather than being represented as complete functionality.
