# P2 core functions and AI/ONNX validation

**Date:** 2026-09-13  
**Flutter:** 3.47.4  
**Application build:** Debug APK rebuilt successfully after P2 changes  
**Android runtime:** Not available; no emulator or physical device is connected

## P2 changes implemented

### 1. Removed the editor AI stub

`lib/services/ai_service.dart` no longer returns the input image path as a fake success. It now adapts editor operations to `SeikaService`:

- remove background → `removeBackground`;
- enhance → `upscale` factor 2;
- shadow → `addShadow`;
- export → `export`;
- relight/inpaint → conversational masked edit, with an explicit mask requirement.

The service returns `EditResult`, so native failures remain failures instead of being added to editor history as successful outputs.

`EditorController` now pushes a history entry only when `EditResult.ok` is true and an output path exists. On failure it stores an explicit error in state.

### 2. Added contract tests

The new `test/ai_operation_contract_test.dart` checks:

- empty image path rejection;
- mask requirement for conversational operations;
- Chat dispatch failure without a selected image;
- Chat conversational failure without a real mask.

These are contract/precondition tests. They do not claim that a native ONNX session ran because no Android runtime is available in this environment.

## LaMa artifact verification

The actual file was downloaded from Hugging Face and checked:

- File: `lama_fp32.onnx`
- Size: `208,044,816` bytes
- SHA-256: `1faef5301d78db7dda502fe59966957ec4b79dd64e16f03ed96913c7a4eb68d6`
- ONNX IR version: `8`
- ONNX opset: `17`
- Graph nodes: `17,480`

### Graph contract observed from the file

| Direction | Name | Element type | Shape |
|---|---|---:|---|
| Input | `image` | float32 | `['batch', 3, 512, 512]` |
| Input | `mask` | float32 | `['batch', 1, 512, 512]` |
| Output | `output` | float32 | `['batch', 3, dynamic, dynamic]` |

This confirms that the names and shapes used by the current Android path are compatible at the graph boundary. The Kotlin bridge currently uses `session.inputNames` order and maps the first input to image and the second to mask; runtime verification should still prefer name-based mapping and should validate output dimensions before saving.

## Verification results

| Check | Result |
|---|---|
| `flutter analyze` | Passed — no issues |
| `flutter test` | Passed — 7 tests |
| `flutter build apk --debug` | Passed |
| LaMa download | Passed |
| LaMa SHA-256 | Passed |
| LaMa graph inspection | Passed |
| Android ONNX session load | Pending device/emulator |
| LaMa inference with fixture image/mask | Pending device/emulator |
| Output visual/quality comparison | Pending device/emulator |
| Memory and latency measurement | Pending device/emulator |

## Remaining P2 gaps

1. The actual `MethodChannel` and `onnxruntime-android` session have not executed on Android.
2. The current tests verify safe contracts and preconditions, not native output pixels.
3. The Android bridge should map LaMa inputs by name (`image`, `mask`) rather than relying only on input order.
4. The bridge now validates output rank/channels and handles dynamic output dimensions defensively; this still needs device execution coverage.
5. Large-image memory limits, cancellation, temporary-file cleanup, and performance metrics remain open.
6. Real-ESRGAN is still not implemented: the available artifact is `.pth`, while `runEsrgan` returns `null` and uses Bitmap scaling fallback.
7. The Chat and Editor UI still need a real image-pick/mask creation flow for end-to-end use.

## P2 status

**P2 source and contract validation is complete for the available environment:** the editor stub was removed, operation failures are explicit, the LaMa artifact and graph contract were verified, the bridge now maps named inputs and validates output shape, tests pass, and the APK rebuilds. **P2 Android runtime validation remains blocked by the absence of an Android device or emulator.**

Next action: run the fixed image/mask fixture flow on an Android emulator/device when one is available, then record latency, memory, and output quality.
