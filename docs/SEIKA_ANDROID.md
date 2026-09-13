# Seika Android engine

## Current implementation

The Flutter `SeikaService` calls the `productchat/studio/seika` MethodChannel. `MainActivity` attaches `SeikaChannel`, and `SeikaChannel.kt` currently contains:

- a local flood-based background-removal fallback;
- masked LaMa ONNX session loading and inference code;
- Bitmap-based upscale fallback;
- simple shadow compositing;
- export to the Android cache directory;
- model load/unload and an NNAPI attempt with CPU fallback.

## Model status

The public Hugging Face repository [`Toufikben/productchat-models`](https://huggingface.co/Toufikben/productchat-models) contains:

- `lama_fp32.onnx`, SHA-256 `1faef5301d78db7dda502fe59966957ec4b79dd64e16f03ed96913c7a4eb68d6`;
- `RealESRGAN_x4plus.pth`, SHA-256 `4fa0d38905f75ac06eb49a7951b426670021be3018265fd191d2125df9d682f1`;
- no MI-GAN weights because commercial redistribution is not yet legally clear.

LaMa's documented contract is image `[1,3,512,512]`, mask `[1,1,512,512]`, float32, with mask `1` meaning erase and `0` meaning preserve. The Kotlin tensor preparation matches these shapes in source, but this is **not Android runtime verification** until an APK is built and exercised with a fixture image and mask.

The Real-ESRGAN artifact is `.pth`. `runEsrgan` intentionally returns `null`, so the current upscale result falls back to `Bitmap.createScaledBitmap`. It must not be described as Real-ESRGAN inference.

## Required runtime verification

1. Download LaMa through `ModelManager` and verify SHA-256.
2. Load it through the MethodChannel on an Android device/emulator.
3. Run a fixed image/mask fixture and verify output dimensions, file validity, mask direction, timing, and memory.
4. Test decode failure, mismatched dimensions, oversized input, unload/reload, and NNAPI fallback.
5. Record device, Android version, app commit, model revision, result, and limitations in the feature matrix.

## Current limitations

- No Android build or device result is recorded for the current commit.
- No memory limit or large-image policy is implemented.
- Real-ESRGAN inference is not implemented.
- MI-GAN is not included.
- The Flutter editor still routes operations through an `AiService` stub, so native capability is not yet equivalent to an end-to-end product feature.
