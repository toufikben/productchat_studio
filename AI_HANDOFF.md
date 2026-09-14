# ProductChat Studio — AI Handoff

ProductChat Studio is an Android-first Flutter foundation for conversational product-photo editing.

## Current state

The repository contains a Flutter/Android build foundation, a Dart Seika service, an Android ONNX LaMa path, Model Manager, Smart Analysis, editor operation contracts, and basic Batch state/progress. Recorded builds used Flutter 3.47.4, Dart 3.13.3, Android SDK 36, and JDK 17. Android device/runtime verification is still pending.

The model repository is [`Toufikben/productchat-models`](https://huggingface.co/Toufikben/productchat-models). LaMa ONNX and Real-ESRGAN `.pth` artifacts have recorded hashes and licenses. Real-ESRGAN inference is not implemented; the product must describe the current bounded result as Basic enhancement fallback. MI-GAN must remain disabled until commercial redistribution permission exists.

The current billing source now contains all six product IDs, local purchase handling, an idempotent local ledger, the `lifetime` non-consumable path, and a local `ProService` for expiry/Lifetime state. It still does not provide trusted server entitlement or backend receipt verification. The target specification is recorded in [`ROADMAP.md`](ROADMAP.md) and [`docs/P7_BILLING_VALIDATION.md`](docs/P7_BILLING_VALIDATION.md).

## Billing v2 target

The target catalog is `pro_monthly`, `pro_yearly`, `credits_100`, `credits_500`, `credits_1200`, and `lifetime`. The target reference prices are `$4.99/month`, `$29.99/year`, `$4.99`, `$19.99`, `$39.99`, and `$79.99` respectively; Google Play regional prices are authoritative in the app. Free is specified as three images per month with PatchMatch and watermark; Pro is specified as unlimited images, legally available models, no watermark, Batch, and Brand Identity; Lifetime provides Pro forever. These are target requirements, not current verification claims.

Credits cost 1 for background removal, 1 for shadow, 2 for enhancement, 3 for conversational/inpaint, and 0 for compliance and export. A failed operation must not consume Credits. A local purchase callback is not sufficient for final financial grant; production requires backend verification and an atomic ledger.

## Completed source/build work recorded previously

- Model/source inventory and feature verification matrix.
- Flutter/Android project restoration and recorded analysis/test/build evidence.
- Editor AI success stub removal and explicit operation results.
- LaMa contract guards, sampled decode, verification cache, cancellation, native hard timeout, and resource cleanup.
- Gallery image picker, local storage/privacy work, locale/theme wiring, and release-signing workflow.

## Next execution order

1. Commit and rerun Flutter analysis/tests/build after the roadmap reconciliation.
2. Provide an Android device/emulator and execute LaMa cold/warm, cancellation, timeout, memory, provider, and repeated-inference tests.
3. Implement the core image/mask/Chat/Editor/History/Batch paths that are still partial.
4. Implement Billing v2 only with the exact Product IDs and policy recorded in the roadmap; do not claim Lifetime until Play Console setup is complete.
5. Implement Receipt Verification, server-authoritative Pro entitlement, transactional Credits ledger, and RTDN reconciliation before production billing.
6. Run Internal Testing with a License Tester and record purchase callbacks and restore behavior.

Do not commit model binaries, credentials, signing keys, Purchase Tokens, or unsupported model claims.
