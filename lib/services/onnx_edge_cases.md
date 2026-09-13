# ONNX edge cases

## Tensor contracts

LaMa is expected to receive NCHW tensors with shape `[1, 3, 512, 512]` for the image and `[1, 1, 512, 512]` for the mask. The Android bridge must not assume that input names are literally `image` and `mask`; it should inspect the session input names and map by order or model metadata.

## Output channels and ranges

Exports may return three or four channels. Three-channel output receives opaque alpha; four-channel output preserves alpha. Some exports return `[0, 1]`, while others return `[-1, 1]`; the bridge detects the range before converting to 8-bit pixels and clamps values to prevent overflow.

## Image dimensions

Large source images are downsampled before decoding or inference to protect memory. ESRGAN dimensions should preserve aspect ratio and be rounded to the model's required multiple, commonly 32. The final result is scaled back to the requested output size only after inference.

## Masks

A missing or empty mask must fail safely for object removal. A full-white fallback mask is only valid for operations explicitly designed to process the whole image; it must not silently replace a user-selected mask.

## Runtime providers

NNAPI or Core ML acceleration may be unavailable on a device. Provider initialization must log the failure and fall back to CPU when policy permits. A failed accelerator initialization must not crash the app or leave a half-loaded session.

## Resource lifecycle

Inference results must be closed before tensors, and tensors must be closed in a `finally` block. Model replacement must close the old session before installing the new one. A single inference lock prevents concurrent operations from exceeding device memory.

## Downloads and integrity

A model is usable only after its SHA-256 matches the registry. Downloads use a temporary `.part` file and are atomically renamed after verification. Interrupted downloads may resume only when the server honors the requested range; otherwise the partial file is discarded and downloaded again.

## Errors and user experience

Decode errors, invalid dimensions, missing model files, provider failures, and out-of-memory errors should return structured failures to Flutter. The UI should offer retry and should never deduct credits for a failed inference.

## Testing matrix

The minimum test matrix includes RGB and RGBA outputs, `[0,1]` and `[-1,1]` ranges, 512px and large images, empty and real masks, missing model files, invalid checksums, CPU fallback, cancellation, and a second inference after unloading and reloading a model.
