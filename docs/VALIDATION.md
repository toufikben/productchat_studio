# Validation record

**Scope:** P0 source-of-truth reconciliation  
**Application commit:** `fb20f125134d381bbc655883008a4f214aebde74`  
**Date:** 2026-09-13

## Verified in P0

- The public Hugging Face repository `Toufikben/productchat-models` exists.
- It contains `lama_fp32.onnx` and `RealESRGAN_x4plus.pth`.
- The repository exposes model-card license notices, file sizes, and hashes.
- The LaMa input/output contract is documented in the model card.
- The application contains Model Manager, Smart Analysis, Batch, Seika Dart, and Android Seika source paths.

## Not verified in P0

The current session did not have the `flutter` command available. Consequently, no fresh result is claimed for dependency resolution, code generation, analysis, tests, APK/AAB creation, or Android device behavior. The feature matrix distinguishes source presence from executable and device-verified status.

## Required next validation

Restore a documented Flutter toolchain, run the checks from a clean checkout, build a debug APK, and execute the LaMa fixture flow on an Android device or emulator. Record the exact command output and environment rather than carrying forward older claims.

See [`MODEL_INVENTORY.md`](MODEL_INVENTORY.md) and [`FEATURE_VERIFICATION_MATRIX.md`](FEATURE_VERIFICATION_MATRIX.md).
