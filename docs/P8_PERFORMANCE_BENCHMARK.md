# Sprint 5 / P8 — Android performance benchmark

**Status:** Started — protocol and evidence ledger defined; runtime measurements pending Android device or emulator.

**Date:** 2026-09-14

**Scope:** LaMa ONNX inference, Flutter↔Kotlin MethodChannel, model loading, cancellation/timeout, memory stability, and repeated operations.

## Sprint 1–4 gate assessment

| Sprint | Current state | Evidence | Gate still open |
|---|---|---|---|
| Sprint 1 — release upload hardening | Partially complete | Release signing workflow, `INTERNET` main manifest permission, target SDK 36, signed AAB workflow | Upload to Internal Testing, Upload Key acceptance, Play Console errors, device installation |
| Sprint 2 — internal release validation | Not complete | Release checklist and Play Console preparation documented | Internal tester installation, startup/editor/credits/privacy checks, crash review |
| Sprint 3 — product activation | Partially complete | Credit products and subscription base plans are Active in Play Console | Licensed test-device purchase, pending/error/restore callbacks, product behavior |
| Sprint 4 — Billing correctness | Code/documentation complete | Commit `1c21e3d`; consumable-only credit grant; catalog tests; docs updated in `4fd32cf` | Pro entitlement policy, receipt verification/backend ledger, real purchase execution |

The project may proceed to P8 protocol work, but this does **not** promote Sprint 1–4 to production-ready.

## Required test environment

At least one Android emulator or physical device is required. Prefer three profiles when available:

1. **Low tier:** Android API 24–28, limited memory.
2. **Mid tier:** Android API 29–34, typical device profile.
3. **Modern tier:** Android API 35/36.

Record device model, Android version, ABI, available RAM, storage free space, app version, model checksum, and provider (CPU or NNAPI) for every run.

## Fixed fixtures

Use the same image and mask for repeatability:

| Fixture | Required property |
|---|---|
| Small | approximately 1 MP, portrait and landscape variants |
| Large | approximately 12 MP, portrait and landscape variants |
| Mask | valid mask matching each source geometry |
| Model | verified `lama_fp32.onnx` with recorded SHA-256 |

Do not compare results across changing model files, image dimensions, build modes, or provider settings without recording the change.

## Measurement protocol

For each scenario, perform one warm-up run, then at least three measured runs. Record median and p95 where the sample size allows it. Capture both wall-clock timing and peak Java/native memory when the profiler is available.

| Scenario | Required measurements | Pass/fail evidence |
|---|---|---|
| Cold LaMa inference | model load, decode, inference, output/save, total wall time | no crash; result image valid; timings recorded |
| Warm LaMa inference | decode, inference, output/save, total wall time | session reuse; no unbounded latency growth |
| Cancellation | cancel during inference and during timeout window | operation terminates; UI recovers; no stale result |
| Hard timeout | forced timeout and subsequent retry | timeout is surfaced; next inference can run |
| Repeated inference | 30–100 sequential operations | no crash, OOM, deadlock, or monotonic memory growth |
| Provider comparison | CPU versus NNAPI when supported | provider and latency recorded; fallback remains functional |
| Large image | 12 MP decode/downsample/inference/save | no pre-resize OOM; orientation and geometry preserved |
| Lifecycle | background, resume, destroy/reopen | sessions/resources close or recover without crash |

## Evidence ledger

| Metric | Result | Evidence | Status |
|---|---|---|---|
| Cold model load | Pending device/emulator | — | Open |
| Warm inference median/p95 | Pending device/emulator | — | Open |
| Cold inference median/p95 | Pending device/emulator | — | Open |
| Peak Java heap | Pending device/emulator | — | Open |
| Peak native/ONNX memory | Pending device/emulator | — | Open |
| CPU versus NNAPI | Pending device/emulator | — | Open |
| Cancellation latency | Pending device/emulator | — | Open |
| Timeout recovery | Pending device/emulator | — | Open |
| 30–100 run stability | Pending device/emulator | — | Open |
| AAB/download/install size | AAB approximately 76 MB from run `34807820712` | GitHub Actions artifact | Recorded; download/install still open |

## Execution commands

From an environment with Flutter and Android tooling:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --profile
flutter build appbundle --release
adb devices
adb install -r build/app/outputs/flutter-apk/app-profile.apk
```

Use Android Studio Profiler or `adb shell dumpsys meminfo` for Java/native memory. Save raw logs and timing output under a local, untracked evidence directory; do not commit user data, credentials, model binaries, or signing keys.

## Current P8 decision

P8 is **in progress at the protocol/source-validation level**. No performance pass is claimed until runtime evidence exists. The next executable action is to run the fixed-fixture cold/warm and repeated-inference matrix on an Android emulator or physical device, then append measured results to this document and update `ROADMAP.md` and `FEATURE_VERIFICATION_MATRIX.md`.
