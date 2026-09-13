# Build environment and repository audit

## Date

2026-09-13. Verified against application commit `fb20f125134d381bbc655883008a4f214aebde74`.

## Current build verification

The repository documentation previously recorded Flutter 3.47.4/Dart 3.13.3 and successful Flutter checks. During P1, the documented toolchain was restored and the checks below were rerun successfully. The current result is recorded in [`P1_BUILD_VALIDATION.md`](P1_BUILD_VALIDATION.md).

- `flutter pub get` — passed
- `flutter gen-l10n` — passed
- `flutter analyze` — passed
- `flutter test` — passed, 3 tests
- Debug APK assembly — passed
- Android device or emulator execution — still pending; no Android device/emulator is available

The Android-first build is now reproducible locally with Flutter 3.47.4, Android SDK 36, and JDK 17. Device/runtime verification remains separate and is not implied by a successful APK build.

## Repository findings

The source includes real implementations for Model Manager, Smart Analysis, Batch state/progress, a Flutter Seika MethodChannel, and an Android ONNX LaMa path. It also contains known incomplete paths:

- `lib/services/ai_service.dart` returns the input path from `AiService.apply` and is not an editing engine.
- `lib/services/storage_service.dart` stores values in an in-memory map only.
- `lib/services/billing_service.dart` has an empty `init` method.
- `SeikaChannel.runEsrgan` returns `null`; the available Real-ESRGAN artifact is `.pth`, not an ONNX model.
- Several feature screens explicitly render `Feature scaffold` or plain placeholder text.
- The router currently exposes only splash, chat, editor, and batch routes.

## Model repository verification

The public model repository exists at [Toufikben/productchat-models](https://huggingface.co/Toufikben/productchat-models). Its verified inventory is maintained in [`MODEL_INVENTORY.md`](MODEL_INVENTORY.md). It contains `lama_fp32.onnx` and `RealESRGAN_x4plus.pth`, with per-artifact hashes and license notices. Presence in Hugging Face is not treated as Android runtime verification.

## Required P0 exit checks

1. Restore Flutter/Dart and document exact versions and install path.
2. Run all Flutter checks from a clean checkout.
3. Confirm Android project/build files are complete and build a debug APK.
4. Record results in CI or a timestamped validation artifact.
5. Keep the feature matrix and roadmap synchronized with the commit and evidence.

See [`FEATURE_VERIFICATION_MATRIX.md`](FEATURE_VERIFICATION_MATRIX.md) for the current source/wired/executable/tested/release-ready status.
