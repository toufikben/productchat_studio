# Model and source inventory

**آخر تحقق:** 2026-09-13  
**كود التطبيق:** `toufikben/productchat_studio`، الفرع `main`، commit `fb20f125134d381bbc655883008a4f214aebde74`  
**مستودع النماذج:** [`Toufikben/productchat-models`](https://huggingface.co/Toufikben/productchat-models)  
**Hugging Face repository SHA:** `974c8e8607396ca79e03aefd70d354707d7192a3`  
**Hugging Face lastModified:** `2026-09-13T20:29:08Z`

## Artifacts

| الملف | موجود في HF | الحجم بالبايت | SHA-256 | الترخيص/الإسناد | استخدام التطبيق الحالي |
|---|---:|---:|---|---|---|
| `lama_fp32.onnx` | نعم | 208,044,816 | `1faef5301d78db7dda502fe59966957ec4b79dd64e16f03ed96913c7a4eb68d6` | Apache-2.0؛ بطاقة النموذج تطلب attribution لـ Places2 | `ModelManager.lama` ثم `SeikaChannel` عند `inpaint` أو مسار جودة غير fast |
| `RealESRGAN_x4plus.pth` | نعم | 67,040,989 | `4fa0d38905f75ac06eb49a7951b426670021be3018265fd191d2125df9d682f1` | BSD-3-Clause | غير قابل للتشغيل حاليًا بواسطة ONNX Runtime؛ `runEsrgan` يرجع `null` |
| MI-GAN weights | لا | — | — | لا توجد موافقة واضحة لإعادة التوزيع التجاري | ممنوع إضافته حتى حسم الترخيص |
| DreamLite | لا | — | — | مستبعد من المستودع | غير مستخدم |

## LaMa contract

وفق بطاقة النموذج في Hugging Face:

- `image`: float32، shape `[1,3,512,512]`.
- `mask`: float32، shape `[1,1,512,512]`.
- mask value `1` تعني المنطقة التي تُحذف، و`0` المنطقة التي تبقى.
- output RGB float32 في نطاق `[0,255]`.

`android/.../SeikaChannel.kt` يطابق shapes المذكورة، لكن التطابق runtime لم يُثبت بعد في بيئة Android.

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
- Android inference: `android/app/src/main/kotlin/com/productchat/studio/native/SeikaChannel.kt`
- Android dependency: `android/app/build.gradle`

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
