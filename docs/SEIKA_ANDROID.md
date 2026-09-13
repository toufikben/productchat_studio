# Seika Android engine

The Flutter `SeikaService` is now connected to `MainActivity` through the `productchat/studio/seika` MethodChannel. `SeikaChannel.kt` provides a deterministic local CPU baseline for background removal, masked inpainting, upscaling, shadow compositing, and export.

The baseline is intentionally not described as MI-GAN or LaMa inference. It is an executable fallback that keeps the Flutter contract working. The next production step is to replace the corresponding Kotlin operations with ONNX Runtime sessions for the verified MI-GAN, LaMa, and Real-ESRGAN artifacts, while preserving the same method names and output-path contract.

Inpainting requires a real mask with the same dimensions as the source image. Passing the source image as its own mask is rejected by the Dart layer.

Hugging Face status: the `Toufikben` account login was verified in the browser, but no public `productchat-models` repository was created and no model weights were uploaded. This remains blocked until the final model artifacts and commercial-license decisions are confirmed.
