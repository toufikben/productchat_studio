# Model Licenses — ProductChat Studio

This document lists all AI models used and their license terms.

## Models

### 1. MI-GAN
- **Source**: https://github.com/Picsart-AI-Research/MI-GAN
- **License**: MIT
- **Commercial Use**: ✅ Allowed
- **Attribution**: Required
- **Modifications**: Converted to ONNX for mobile

### 2. LaMa
- **Source**: https://github.com/advimman/lama
- **License**: Apache 2.0
- **Commercial Use**: ✅ Allowed
- **Attribution**: Required
- **Modifications**: Converted to FP16 ONNX

### 3. Real-ESRGAN
- **Source**: https://github.com/xinntao/Real-ESRGAN
- **License**: BSD-3-Clause
- **Commercial Use**: ✅ Allowed
- **Attribution**: Required
- **Modifications**: Tiny variant + ONNX export

### 4. PatchMatch
- **Source**: Original implementation
- **License**: Part of this project (MIT)
- **Commercial Use**: ✅ Allowed

### 5. Qwen-Image-Edit
- **Source**: https://github.com/QwenLM/Qwen-Image
- **License**: Apache 2.0
- **Commercial Use**: ✅ Allowed
- **Usage**: Remote API only — not embedded in APK

## License Compliance Checklist

Before each release:
- [ ] Verify source repos still use same licenses
- [ ] Update About screen if models change
- [ ] Include attribution in `showLicensePage`
- [ ] Keep this document updated
