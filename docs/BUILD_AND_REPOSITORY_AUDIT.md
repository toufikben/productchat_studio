# Build environment and repository audit

**آخر تحديث:** 2026-09-14
**النطاق:** Android-first Flutter build and repository state.

## Current build evidence

The repository records successful validation with Flutter 3.47.4, Dart 3.13.3, Android SDK/compile SDK 36, and JDK 17. The latest evidence is historical CI/build evidence and must be rerun after roadmap or code changes.

- `flutter pub get` — passed in the recorded P1 validation.
- `flutter gen-l10n` — passed in the recorded P1 validation.
- `flutter analyze` — passed in recorded validation.
- `flutter test` — passed in recorded CI runs; rerun required on the current commit after Billing v2 changes.
- Debug APK and signed Release AAB — recorded as built successfully; Release CI now also builds and uploads a signed Release APK.
- Android device or emulator execution — not recorded; runtime/inference/purchase validation remains pending.

A successful build is not Android runtime verification. Runtime claims require device/emulator, app version, commit, fixture, model checksum, provider, timing, and memory evidence.

## Current repository findings

The source contains Model Manager, Smart Analysis, editor operation contracts, Batch state/progress, the Flutter Seika MethodChannel, and an Android ONNX LaMa path. Known incomplete or gated areas are:

- LaMa Android session and output require device/emulator verification.
- Real-ESRGAN is not implemented in the Android ONNX path; the available artifact is `.pth`, so the product must call the current result Basic enhancement fallback.
- MI-GAN weights are not distributed because commercial redistribution permission is not established.
- Batch is now connected to the local `AiService` editing pipeline and records successful outputs in History; native runtime/performance evidence remains pending.
- Billing v2 Free/Pro/Lifetime, `ProService`, trusted `ProEntitlement`, Lifetime product setup, and receipt verification are not complete.
- Several feature routes and screens require completion or explicit removal from the advertised product path.
- Storage documentation must be reconciled with the actual implementation; older records mention an in-memory map while later handoff documentation mentions SharedPreferences and the new specification mentions Hive.

## Model repository

The public model repository is `Toufikben/productchat-models`. Its artifact inventory and hashes are maintained in [`MODEL_INVENTORY.md`](MODEL_INVENTORY.md). Presence in Hugging Face is not treated as Android runtime verification.

## Required next checks

1. Rerun dependency resolution, localization generation, analysis, and tests on the current commit.
2. Build Debug APK, signed Release APK, and signed Release AAB from the same commit.
3. Execute the LaMa fixture flow on an Android device/emulator.
4. Execute Billing v2 product and entitlement tests only after the required Play Console setup.
5. Keep `ROADMAP.md`, the feature matrix, billing documents, and evidence commit synchronized.
