# تقرير تنفيذ اختبار Qwen API والتحقق من البناء

**المستودع:** `toufikben/productchat_studio`  
**الفرع/الالتزام:** `main` — `ab6f2ff` (`docs: document Hugging Face model rollout status`)  
**التاريخ:** 2026-09-15

## الخلاصة التنفيذية

تم تنفيذ التحقق الخارجي من روابط نماذج Hugging Face وقيم SHA-256 الموجودة في `lib/core/constants.dart`. الروابط الثلاثة الحالية تستجيب بنجاح، والقيم المضمّنة تطابق ترويسة `x-linked-etag` التي يعرضها Hugging Face لكل ملف.

أما تكامل Qwen الحالي فلم يجتز اختبار تشغيل حقيقي؛ إذ إن البيئة لا تحتوي مفتاح `QWEN_API_KEY`، كما أن فحصًا غير موثّق أعاد HTTP 401 كما هو متوقع. وبمقارنة العميل الحالي مع توثيق WaveSpeed الحالي، توجد مشكلة تكامل يجب إصلاحها قبل اعتبار المسار جاهزًا: الشيفرة تستخدم endpoint قديمًا وترسل `multipart/form-data`، بينما التوثيق الحالي يطلب JSON إلى endpoint `/qwen-image/edit` مع `prompt` و`image`، ثم polling إلى `/api/v3/predictions/{id}/result` وقراءة `data.outputs`.

لم يمكن تشغيل `flutter analyze` أو `flutter build apk` فعليًا في هذه الجلسة لأن أمر `flutter` غير مثبت أو غير موجود في `PATH`. لذلك لا توجد نتيجة بناء جديدة يمكن نسبتها إلى هذه البيئة. التقرير السابق المحفوظ في `flutter_analyze_report.md` يسجل آخر نتيجة معروفة: **411 مشكلة**، منها **58 error** و**151 warning** و**202 info**.

## 1. التحقق من روابط النماذج وقيم SHA-256

المصدر المفحوص: `lib/core/constants.dart`.

| النموذج | الرابط | الحجم البعيد | SHA-256 في التطبيق | SHA-256 البعيد | النتيجة |
|---|---|---:|---|---|---|
| MI-GAN | `https://huggingface.co/Toufikben/productchat-models/resolve/main/migan.onnx` | 29,546,882 bytes | `593eba0b7e04730f1b61c0a3cbca68d97d8d6a7ff5c6a44a7b9d7fcd880fc5ae` | مطابق | **MATCH** |
| LaMa FP16 | `https://huggingface.co/Toufikben/productchat-models/resolve/main/lama_fp16.onnx` | 107,762,632 bytes | `37f2e4888eb27aa08841786b506fa094156c497de3d954ebf7a297c61a7fb4ea` | مطابق | **MATCH** |
| Real-ESRGAN | `https://huggingface.co/Toufikben/productchat-models/resolve/main/real_esrgan_x4.onnx` | 67,051,616 bytes | `5c586662929cbc686c1a5c38d9c060dbdb4ea5863a1f7672b8c0761e6b89c033` | مطابق | **MATCH** |

ملاحظة: التحقق اعتمد على `x-linked-etag` الذي يقدمه Hugging Face كقيمة SHA-256 للملف الكبير، ولم يتطلب تنزيل ما يقارب 195 MB من النماذج. لا يوجد حاليًا ثابت Qwen model أو SHA-256 لـ Qwen في `constants.dart`؛ Qwen في الشيفرة الحالية مسار API بعيد، وليس نموذج ONNX مُضمّنًا.

## 2. اختبار تكامل Qwen API

### ما تم اختباره

* فحص وجود عميل Qwen في `lib/services/ai/qwen_edit_service.dart`.
* فحص الربط الأصلي في `android/app/src/main/kotlin/com/productchat/studio/native/QwenEditChannel.kt`.
* إرسال طلب smoke غير موثّق إلى العنوان الموجود حاليًا.
* مراجعة توثيق WaveSpeed الحالي.

### النتيجة الحالية

الطلب غير الموثّق إلى:

```text
POST https://api.wavespeed.ai/api/v3/wavespeed-ai/qwen-image-edit
```

أعاد:

```text
HTTP 401
```

وهذا يثبت الوصول إلى المضيف وأن المصادقة مطلوبة، لكنه لا يثبت نجاح الطلب أو صحة payload.

### عدم التطابق المكتشف

العميل الحالي يستخدم:

```dart
https://api.wavespeed.ai/api/v3/wavespeed-ai/qwen-image-edit
```

ويرسل `FormData` يحتوي ملفًا محليًا تحت الحقل `image`. أما توثيق WaveSpeed الحالي فيستخدم:

```text
POST https://api.wavespeed.ai/api/v3/wavespeed-ai/qwen-image/edit
Content-Type: application/json
```

مع payload من الشكل:

```json
{
  "prompt": "...",
  "image": "https://public-image-url/...",
  "output_format": "png"
}
```

بعد الإرسال يعاد prediction id، ويجب polling على:

```text
GET https://api.wavespeed.ai/api/v3/predictions/{id}/result
```

وعند `completed` يجب قراءة `data.outputs` بدل `data.output`. لذلك لا يمكن اعتبار `qwen_edit_service.dart` متوافقًا مع العقد الحالي قبل تعديل endpoint، طريقة إرسال الصورة المحلية (رفعها إلى URL عام أو استخدام آلية الرفع المدعومة)، polling URL، وحقل output، مع التعامل مع الحالات النهائية `failed`, `cancelled`, `timeout`, و`deleted`.

### اختبار التشغيل الحقيقي

**غير منفذ** لسببين مستقلين:

1. لا يوجد `QWEN_API_KEY` متاح في بيئة التشغيل، ولا ينبغي وضعه في المستودع.
2. لا توجد صورة اختبار مرفوعة إلى URL عام يمكن إرسالها إلى واجهة WaveSpeed الحالية.

## 3. Flutter analyze

تم تنفيذ الأمر المطلوب:

```text
flutter analyze
```

النتيجة في البيئة الحالية:

```text
bash: flutter: command not found
EXIT=127
```

إذًا لم يبدأ analyzer فعليًا في هذه الجلسة.

آخر سجل محفوظ في `flutter_analyze_report.md`، من فحص سابق، يذكر:

| التصنيف | العدد |
|---|---:|
| `error` | 58 |
| `warning` | 151 |
| `info` | 202 |
| الإجمالي | **411** |

أكثر الملفات احتواءً على أخطاء مسجلة:

| الملف | عدد الأخطاء |
|---|---:|
| `lib/services/watermark_preset_service.dart` | 13 |
| `lib/services/export_preset_service.dart` | 8 |
| `lib/services/auto_save_service.dart` | 8 |
| `lib/services/voice_service.dart` | 7 |
| `lib/services/voice_presets_service.dart` | 7 |
| `lib/services/payment_history_service.dart` | 7 |
| `lib/features/editor/presets_screen.dart` | 6 |
| `lib/services/brand_service.dart` | 1 |
| `lib/features/chat/voice_search_screen.dart` | 1 |

للاطلاع على سجل المواقع والرسائل كاملًا، راجع `flutter_analyze_report.md`.

## 4. flutter build apk

تم تنفيذ الأمر المطلوب:

```text
flutter build apk
```

النتيجة في البيئة الحالية:

```text
bash: flutter: command not found
EXIT=127
```

لم يتم إنشاء APK جديد في هذه الجلسة. توجد أيضًا متطلبات إضافية للبناء لا يمكن تأكيدها دون Flutter SDK، وهي Android SDK/NDK وإعداد توقيع release. ملف `android/app/build.gradle.kts` يرفض release build عند غياب `android/key.properties`، وهو سلوك مقصود لمنع بناء release غير موقّع أو موقّعًا بمفتاح غير إنتاجي.

## 5. حالة الملفات والتغييرات

لم تُجرَ أي تغييرات على الشيفرة المصدرية أو الثوابت أثناء هذه الجولة. أُضيف هذا التقرير فقط. حالة Git قبل إضافة التقرير كانت نظيفة على الفرع `main`.

## 6. الخطوات اللازمة لإكمال اختبار التشغيل

1. توفير Flutter SDK بالإصدار المتوافق مع المشروع، ثم تشغيل `flutter pub get`.
2. تشغيل `flutter analyze` وحفظ سجل جديد مستقل عن التقرير السابق.
3. تجهيز Android SDK/NDK و`android/key.properties` محليًا عند الحاجة، ثم تشغيل `flutter build apk`.
4. تصحيح عميل Qwen ليتوافق مع endpoint وJSON/polling الحاليين.
5. توفير `QWEN_API_KEY` عبر `--dart-define` وسيناريو آمن لرفع صورة الاختبار، ثم تنفيذ طلب حقيقي وتسجيل prediction status دون كشف المفتاح أو بيانات حساسة.
6. إعادة تشغيل الاختبارات بعد الإصلاح، خصوصًا اختبارات `EditResult` ومسار timeout/failure وعدم استهلاك الرصيد عند الفشل.

## مراجع التحقق

* [WaveSpeed Qwen Image Edit API](https://wavespeed.ai/models/wavespeed-ai/qwen-image/edit)
* [Hugging Face model repository](https://huggingface.co/Toufikben/productchat-models)
