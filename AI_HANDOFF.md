# ProductChat Studio — AI Handoff

ProductChat Studio is a Flutter foundation for conversational product-photo editing. The repository includes the repair package, verification scripts, a local-only Smart Analysis service, and a Smart Analysis panel.

## Current status

The project is scaffolded and source-reviewed. The current sandbox does not contain the Flutter SDK, so `flutter pub get`, `flutter analyze`, and APK builds must be run on a Flutter-enabled machine.

## Next steps

1. Install Flutter 3.27+ and run `flutter pub get`.
2. Run `bash verify_project.sh` and `flutter test`.
3. Add the remaining feature screens and native bridges from the supplied specification.
4. Replace `YOUR_ORG` in `lib/core/constants.dart` only after publishing compatible ONNX models to Hugging Face.
5. Run `test_on_device.sh` with an Android device connected.

Do not commit model binaries or credentials. Keep model URLs configurable and review Android permissions before release.
