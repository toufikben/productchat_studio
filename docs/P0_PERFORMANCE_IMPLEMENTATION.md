# P0 performance fixes implementation

**Date:** 2026-09-14  
**Scope:** Kotlin Android bridge and Dart model manager  
**Validation:** Flutter analyze passed, 7 Flutter tests passed, debug APK built successfully

## Implemented fixes

### 1. Background execution for native operations

`SeikaChannel` now owns a single-thread `ExecutorService`. MethodChannel operations are queued on that executor instead of running directly in the MethodChannel callback path.

This prevents decode, resize, tensor creation, ONNX `session.run`, pixel conversion, and file encoding from blocking the Flutter/UI thread. A single queue preserves the intended `maxConcurrentInferences = 1` policy and avoids concurrent access to the ONNX session.

The executor and loaded sessions are released from `MainActivity.onDestroy()` through `SeikaChannel.close()`.

**Not yet implemented:** cancellation of an already running inference and a hard native inference timeout.

### 2. Sampled decode and image limits

`decodeBitmap` now:

- reads image bounds first;
- computes a power-of-two `inSampleSize`;
- prevents decoded dimensions from exceeding 4096 where possible;
- applies a final aspect-ratio-preserving scale if the decoder still returns a larger bitmap;
- forces ARGB_8888 for predictable pixel access.

The same limit is enforced for LaMa output pixels (`4096 × 4096`). Output rank, channels, positive dimensions, and pixel count are validated before allocating output buffers.

### 3. Verification cache for model SHA-256

`ModelManager` now caches successful model verification by model id, path, file length, modification time, and expected SHA-256. Repeated `readyPath` calls no longer hash the entire 208 MB LaMa file when the verified file metadata is unchanged.

The cache is invalidated when:

- verification fails;
- a model is deleted;
- a new download is finalized.

A full SHA-256 still runs after a fresh download or when metadata changes.

### 4. Resource and memory limits

The LaMa path now explicitly recycles temporary resized Bitmaps, closes tensors and ONNX results in `finally`, recycles intermediate output Bitmaps when scaling, and rejects oversized dynamic output shapes.

The native executor/session lifecycle is closed when the Activity is destroyed.

## Verification results

| Check | Result |
|---|---|
| `flutter analyze` | Passed — no issues |
| `flutter test` | Passed — 7 tests |
| `flutter build apk --debug` | Passed |
| APK size | 243,628,883 bytes |
| APK SHA-256 | `5dbb645539d110d39ccb9d6488ff5fb2203c554fc5baaee4c578a5869929ce93` |
| Android runtime benchmark | Pending device/emulator |
| Peak native memory | Pending device/emulator |
| CPU vs NNAPI latency | Pending device/emulator |

## Remaining performance work

- Add native cancellation and a real inference timeout.
- Add instrumentation for decode, model verification, model load, inference, output conversion, and save durations.
- Measure Java/native heap and OOM behavior on low-, mid-, and high-tier Android devices.
- Verify that the MethodChannel result callback is accepted safely after background execution across the supported Flutter embedding/runtime.
- Add progress streaming for model downloads; the current Dart download stream still emits coarse progress.
- Add a real device fixture test for LaMa image/mask inference and output quality.

## Status

The four requested P0 code fixes are implemented and the project still analyzes, tests, and builds successfully. This is a source/build verification result, not a performance pass: latency, peak memory, NNAPI behavior, and thermal stability require Android hardware or an emulator.
