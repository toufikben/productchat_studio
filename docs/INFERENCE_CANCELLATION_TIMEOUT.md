# Inference cancellation and native hard timeout

**Date:** 2026-09-14  
**Scope:** `SeikaChannel.kt` and `SeikaService`  
**Default native timeout:** 180 seconds

## Implemented behavior

### User cancellation

Dart now exposes:

```dart
await SeikaService().cancelInference();
```

This invokes the native MethodChannel method `cancelInference` directly, without waiting behind the single-thread work queue. The native bridge marks the active `InferenceControl` as cancelled and calls `OrtSession.RunOptions.setTerminate(true)` when a running ONNX session exists.

The running inference checks the cancellation token:

- before preprocessing;
- periodically while converting pixels into tensors;
- before calling ONNX Runtime;
- after `session.run` returns.

A cancelled operation raises a native cancellation error and does not save a successful output.

### Single active inference

Only one inference is active at a time because the native work executor is
single-threaded. An explicit `cancelInference` request can terminate the active
operation directly, without waiting behind that executor. A later queued
operation starts only after the previous operation has completed or been
cancelled.

### Native hard timeout

Each LaMa inference creates a scheduled timeout task. After 180 seconds it:

1. marks the inference cancelled;
2. calls `RunOptions.setTerminate(true)`;
3. causes ONNX Runtime to terminate the run at the native runtime boundary;
4. closes the RunOptions, output, tensors, and temporary Bitmaps in `finally`.

The timeout is cancelled when the inference completes normally or fails.

### Lifecycle cleanup

`MainActivity.onDestroy()` calls `SeikaChannel.close()`, which:

- stops the work executor;
- cancels the active inference;
- stops the timeout scheduler;
- unloads ONNX sessions.

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | Passed — no issues |
| `flutter test` | Passed — 7 tests |
| `flutter build apk --debug` | Passed |
| APK size | 243,629,147 bytes |
| APK SHA-256 | `6dbe49a65d71ec7917643d7c52c7356aa92f39cca0cb43991f3413e3339450f3` |
| Direct Android cancellation during `session.run` | Requires device/emulator |
| 180-second timeout behavior under a real stalled run | Requires device/emulator |

## Important boundary

The source now uses ONNX Runtime's actual `RunOptions.setTerminate(true)` API; this is stronger than cancelling a Java `Future`, which would not necessarily stop native inference. However, no Android runtime is available in this session, so the exact cancellation latency, provider-specific behavior (CPU vs NNAPI), and timeout error surfaced by a physical runtime remain to be measured.

The current timeout applies to the LaMa inference operation. Model download and model loading have separate lifecycle paths and do not yet have the same native hard-timeout contract.
