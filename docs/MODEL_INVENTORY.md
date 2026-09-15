# Model and source inventory

**آخر تحقق:** 2026-09-15
**كود التطبيق:** `toufikben/productchat_studio`، الفرع `main`، آخر commit موثق عند التحديث
**مستودع النماذج:** [`Toufikben/productchat-models`](https://huggingface.co/Toufikben/productchat-models)  
**Hugging Face repository SHA:** `974c8e8607396ca79e03aefd70d354707d7192a3`  
**Hugging Face lastModified:** `2026-09-13T20:29:08Z`

## Artifacts

| الملف | موجود في HF | الحجم بالبايت | SHA-256 | الترخيص/الإسناد | استخدام التطبيق الحالي |
|---|---:|---:|---|---|---|
| `migan.onnx` | نعم | 29,546,882 | `593eba0b7e04730f1b61c0a3cbca68d97d8d6a7ff5c6a44a7b9d7fcd880fc5ae` | يجب مراجعة شروط إعادة التوزيع قبل البيع التجاري | مثبت في `ModelManager`؛ runtime Android غير مثبت |
| `lama_fp16.onnx` | نعم | 107,762,632 | `37f2e4888eb27aa08841786b506fa094156c497de3d954ebf7a297c61a7fb4ea` | تحويل FP16 موثق في بطاقة المستودع؛ يلزم التحقق من الترخيص الأصلي | `ModelManager.lama`؛ runtime Android غير مثبت |
| `real_esrgan_x4.onnx` | نعم | 67,051,616 | `5c586662929cbc686c1a5c38d9c060dbdb4ea5863a1f7672b8c0761e6b89c033` | يجب مراجعة شروط إعادة التوزيع قبل البيع التجاري | مثبت في `ModelManager`؛ runtime Android غير مثبت |
| `lama_fp32.onnx` و`RealESRGAN_x4plus.pth` | نعم، artifacts مرجعية | — | — | ليست الملفات التي يستخدمها المسار الحالي | لا تُخلط مع artifacts ONNX الحالية |
| DreamLite | لا | — | — | مستبعد من المستودع | غير مستخدم |

## LaMa contract

العقد التفصيلي للـ artifacts الثلاثة يجب أن يُثبت من graph الفعلي ومن runtime Android قبل اعتمادها. لا تُعتبر الأبعاد أو ترتيب القنوات مستنتجة من اسم الملف. وبالنسبة إلى LaMa، يظل العقد المرجعي الموثق سابقاً هو `image` من نوع float32 بالشكل `[1,3,512,512]` و`mask` بالشكل `[1,1,512,512]`، مع ضرورة تأكيده على artifact `lama_fp16.onnx` الحالي.

## Repository files observed

- `.gitattributes`
- `LICENSE-LAMA.txt`
- `LICENSE-REALESRGAN.txt`
- `README.md`
- `RealESRGAN_x4plus.pth`
- `lama_fp32.onnx`

## Application references

- URLs: `lib/core/constants.dart`
- Download/checksum: `lib/services/model_manager.dart`
- Flutter bridge: `lib/services/seika_service.dart`
- Android inference: `android/app/src/main/kotlin/com/productchat/aiphotostudio/native/SeikaChannel.kt`
- Android dependency: `android/app/build.gradle`
- Reproducible public artifact check: `scripts/verify_model_artifacts.sh`

## Verification policy

وجود الملف في Hugging Face لا يثبت قابلية التشغيل. لا تُرفع حالة النموذج إلى `runtime verified` إلا بعد:

1. تنزيله مع checksum مطابق.
2. تحميله في runtime المحدد.
3. تشغيل input fixture مطابق للعقد.
4. التحقق من output ووقت التنفيذ والذاكرة.
5. تسجيل جهاز Android ونسخة النظام والـ commit.

## External evidence

- [Model card](https://huggingface.co/Toufikben/productchat-models)
- [Model API](https://huggingface.co/api/models/Toufikben/productchat-models)
- [Repository tree](https://huggingface.co/api/models/Toufikben/productchat-models/tree/main?recursive=true)
