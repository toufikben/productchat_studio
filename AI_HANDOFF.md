# ProductChat Studio — AI Handoff

ProductChat Studio is an Android-first Flutter foundation for conversational product-photo editing.

## Current verified state

- The code repository is at the latest GitHub `main` commit after the billing update.
- The public Hugging Face model repository exists at [`Toufikben/productchat-models`](https://huggingface.co/Toufikben/productchat-models).
- LaMa ONNX and Real-ESRGAN `.pth` artifacts are present with recorded hashes and license notices.
- Android source contains a LaMa ONNX path; Flutter analysis/tests and debug APK build are verified, but Android runtime/inference is still not verified because no device/emulator is available.
- Real-ESRGAN inference is not implemented: the available artifact is `.pth` and the Kotlin method falls back to Bitmap scaling.
- Editor AI stub is removed and operation contracts, cancellation, native timeout, sampled decode, and resource cleanup are implemented. Billing product IDs are wired to active Play Console products and subscriptions; Sandbox purchase execution, receipt verification, several screens, runtime integration tests, and release readiness remain incomplete as recorded in [`FEATURE_VERIFICATION_MATRIX.md`](docs/FEATURE_VERIFICATION_MATRIX.md) and [`ROADMAP.md`](ROADMAP.md).
- The current environment has Flutter 3.47.4 and can produce a debug APK, but it has no Android device/emulator for runtime validation.

## P0–P2 completed for source/build validation

- Created [`MODEL_INVENTORY.md`](docs/MODEL_INVENTORY.md) as the model/source of truth.
- Created [`FEATURE_VERIFICATION_MATRIX.md`](docs/FEATURE_VERIFICATION_MATRIX.md) with source, wiring, executable, automated, Android, and release states.
- Reconciled build, validation, Seika, and handoff documentation with the actual repository and Hugging Face state.
- Restored Flutter/Android build and produced debug APKs.
- Replaced the editor AI stub with Seika operation mapping and added seven contract tests.
- Verified the LaMa artifact/graph and added named-input/output guards, cancellation, native hard timeout, sampled decode, verification cache, and Kotlin resource cleanup.
- P4 added a real gallery image-picker flow into the editor (`a3e8463`).
- P5 added durable SharedPreferences storage and in-app privacy/terms route (`045669d`).
- P6 documented the Real-ESRGAN fallback and MI-GAN licensing decision (`4133d45`).
- P10 wired persisted Arabic/English locale, theme persistence, localization delegates, and basic semantics.
- Sprint 1 release hardening added local `android/key.properties` signing with no Debug signing fallback, Release INTERNET permission, Flutter CI version alignment, and [`docs/RELEASE_SIGNING.md`](docs/RELEASE_SIGNING.md). Billing release `1.0.2+3` now matches active `credits_*`, `pro_monthly`, and `pro_yearly` Play products; AAB upload/internal testing and purchase execution remain the next gate.

## Next execution order

1. Provide an Android emulator/device and execute Flutter↔Kotlin↔ONNX integration tests.
2. Measure LaMa cold/warm latency, peak Java/native memory, cancellation, timeout recovery, and repeated-session stability.
3. Complete image picker/mask creation and real batch/edit/history/storage flows.
4. Decide whether Real-ESRGAN will use ONNX/NCNN or be labeled as a basic fallback.
5. Run Internal testing purchases for Credits and subscriptions, then implement trusted receipt verification before treating Billing as production-ready.

Do not add MI-GAN weights or claim production readiness without explicit license and runtime evidence. Do not commit model binaries, credentials, or signing keys.
