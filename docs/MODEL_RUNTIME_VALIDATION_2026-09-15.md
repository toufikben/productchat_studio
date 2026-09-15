# حالة تحقق نماذج ProductChat Studio — 2026-09-15

## النتيجة

تم التحقق من أن artifacts الثلاثة التي يشير إليها التطبيق متاحة من مستودع Hugging Face العام وأن الملفات المنزلة تطابق قيم SHA-256 المثبتة في `lib/core/constants.dart`. هذا تحقق من التوفر والسلامة، وليس إثباتاً لنجاح ONNX inference على Android.

| النموذج | الملف | الحجم | النتيجة |
|---|---|---:|---|
| MI-GAN | `migan.onnx` | 29,546,882 bytes | HTTP 200 وSHA-256 مطابق |
| LaMa | `lama_fp16.onnx` | 107,762,632 bytes | HTTP 200 وSHA-256 مطابق |
| Real-ESRGAN x4 | `real_esrgan_x4.onnx` | 67,051,616 bytes | HTTP 200 وSHA-256 مطابق |

يمكن إعادة تنفيذ الفحص بواسطة:

```bash
bash scripts/verify_model_artifacts.sh
```

## ما لم يُتحقق بعد

لم تتوفر في بيئة التنفيذ الحالية أدوات Flutter أو ADB أو جهاز Android/Emulator، ولذلك لم يُنفذ تحميل ONNX Session أو inference أو قياس الزمن والذاكرة أو اختبار انقطاع التنزيل واستئنافه. كما لم يتوفر `QWEN_API_KEY`، ولذلك لم يُرسل طلب فعلي إلى WaveSpeed ولم تُعتبر خدمة Qwen متحققة.

يلزم في المرحلة التالية تشغيل اختبار Android ARM64 لكل نموذج، وتسجيل الجهاز وإصدار Android والـ commit، والتحقق من input/output tensor contract وصلاحية PNG الناتج. ويجب تنفيذ اختبار Qwen محلياً أو في CI باستخدام Secret، مع تغطية النجاح والفشل والمهلة و401 و429، دون طباعة المفتاح أو تضمينه في APK موزع.

## قرار Hugging Face

لا يوجد artifact جديد مطلوب رفعه إلى Hugging Face في هذه المرحلة. يجب عدم رفع مفاتيح API أو keystore أو إعادة تسمية ملفات Safetensors/PTH لتبدو كـ ONNX. بعد توفر اختبار Android، تُحدّث بطاقة النموذج بعقود tensors ونتائج runtime الفعلية، لا بمجرد إثبات HTTP 200.

## مصادر الحقيقة

- روابط النماذج وقيم SHA-256: `lib/core/constants.dart`
- التنزيل والتحقق: `lib/services/model_manager.dart`
- فحص artifacts العام: `scripts/verify_model_artifacts.sh`
- خارطة الطريق: `ROADMAP.md`
- الجرد التفصيلي: `docs/MODEL_INVENTORY.md`
- تكامل Qwen: `lib/services/ai/qwen_edit_service.dart`

## حالة البيئة

| الأداة/السر | الحالة |
|---|---|
| Flutter SDK | غير موجود في بيئة التنفيذ |
| Android ADB | غير موجود في بيئة التنفيذ |
| `QWEN_API_KEY` | غير متوفر، وهو الوضع الصحيح لعدم تسريب سر |
| مفاتيح Hugging Face | غير مطلوبة لفحص المستودع العام |

بالتالي تبقى بنود Android runtime وQwen API و`flutter analyze`/`flutter test` بنوداً معلقة، ولا يجوز تحويلها إلى «جاهزة للإصدار» قبل تنفيذها في بيئة Flutter/Android مناسبة.

> **ملاحظة:** ملفات `docs/ai_package/` تحتوي على نصوص تاريخية للحزم السابقة؛ أي ذكر فيها لـ `qwen_edit_int8.onnx` لا يمثل الخطة الحالية. الخطة الحالية هي WaveSpeed API، بينما artifacts المحلية الحالية هي النماذج الثلاثة المذكورة أعلاه.

التاريخ: 2026-09-15
تطبيق: `toufikben/productchat_studio`
مستودع النماذج: `Toufikben/productchat-models`
