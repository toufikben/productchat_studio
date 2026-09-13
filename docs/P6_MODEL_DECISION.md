# P6 model decision

**Date:** 2026-09-14

## Real-ESRGAN

The repository contains `RealESRGAN_x4plus.pth`, but the Android bridge uses ONNX Runtime and does not execute PyTorch `.pth` weights. `runEsrgan` therefore remains intentionally unavailable and the app uses a bounded Bitmap scaling fallback for the enhance action.

The product must not label the fallback as Real-ESRGAN. A future implementation requires one of:

1. a verified ONNX export with input/output contract and Android runtime test; or
2. an Android-compatible NCNN/TFLite implementation with an explicit license and benchmark.

Until then, the feature is **basic enhancement fallback**, not Real-ESRGAN inference.

## MI-GAN

MI-GAN weights remain disabled because commercial redistribution permission has not been established. No model binary is added to the application or distributed repository.

## Current P6 status

P6 is complete as a product/legal decision: no unsupported model claim is made, the fallback is bounded, and MI-GAN remains disabled. Runtime implementation of a production Real-ESRGAN backend is still optional future work and is not a blocker for the base Android LaMa release.
