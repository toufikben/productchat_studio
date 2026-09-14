# ProductChat Studio

Private Flutter project for conversational AI-assisted product photography. It follows the supplied repair specification and adds **Smart Analysis**, an on-device image inspection flow that ranks suggestions such as lighting enhancement, background removal, upscaling, shadow creation, and export preparation.

## Quick start

```bash
bash FIX_PACKAGE.sh
flutter pub get
flutter test
bash verify_project.sh
flutter run
```

## Local Android artifacts

From a Flutter-enabled workstation, a debug APK can be built with `flutter build apk --debug`. A signed release APK and AAB require `android/key.properties` and the local keystore; the release CI workflow builds both artifacts and uploads them separately. Use `flutter build apk --release` for the installable APK and `flutter build appbundle --release` for Google Play.

## Batch processing

Batch is restricted to Pro/Lifetime and now calls the same local `AiService` operation path as Editor. The default batch operation is background removal; each successful native output is recorded in local History, and individual failures are shown without stopping the remaining jobs.

## Important limitation

This initial repository was created in a sandbox without the Flutter SDK. The structure and Dart sources were checked textually and by shell verification; Flutter compilation and device validation remain to be run on a Flutter-enabled workstation.
