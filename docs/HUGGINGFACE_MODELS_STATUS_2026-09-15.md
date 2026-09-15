# تقرير تنفيذ نماذج ProductChat Studio

**التاريخ:** 2026-09-15  
**المستودع:** `toufikben/productchat_studio`  
**مستودع النماذج:** [`Toufikben/productchat-models`](https://huggingface.co/Toufikben/productchat-models)  
**نطاق التقرير:** توثيق ما تم تنفيذه وما تبقى من خطة النماذج الأربعة: MI-GAN، LaMa، Real-ESRGAN، وQwen-Image-Edit.

## الخلاصة التنفيذية

تم تجهيز ثلاثة نماذج ONNX ورفعها إلى مستودع Hugging Face العام، ثم ربط التطبيق بروابطها الثابتة والتحقق من قيم SHA-256 محليًا وعن بُعد. النماذج الثلاثة هي MI-GAN لإزالة الخلفية، وLaMa بصيغة FP16 للإدخال/الإزالة بالقناع، وReal-ESRGAN x4 لرفع الدقة.

أما Qwen-Image-Edit فلم يُحوَّل إلى ONNX ولم يُرفع باسم وهمي. السبب أن Qwen-Image-Edit ليس شبكة ONNX مفردة، بل pipeline كبيرة متعددة المكونات تعتمد على Diffusers وQwen2.5-VL وVAE وTransformer وscheduler. لذلك تم استبدال التنفيذ المحلي بواجهة API بعيدة، مع تمرير مفتاح الوصول في وقت البناء عبر `--dart-define` وعدم حفظه في GitHub.

الحالة الحالية **مكتملة من ناحية رفع artifacts الثلاثة وربطها بالكود**. ما زالت هناك أعمال تحقق وتشغيل مطلوبة قبل اعتبار تكامل النماذج جاهزًا للإصدار، خصوصًا اختبار inference فعلي على Android، اختبار Qwen بمفتاح صالح، وإغلاق مشاكل التحليل العامة في بقية المشروع.

## الحالة الحالية حسب النموذج

| النموذج | الغرض | الصيغة | الحالة | المصدر/الرابط |
|---|---|---|---|---|
| MI-GAN | إزالة الخلفية | `migan.onnx` | مرفوع ومربوط بالكود | `https://huggingface.co/Toufikben/productchat-models/resolve/main/migan.onnx` |
| LaMa | إزالة عناصر أو تعبئة مناطق باستخدام mask | `lama_fp16.onnx` | مرفوع ومربوط بالكود | `https://huggingface.co/Toufikben/productchat-models/resolve/main/lama_fp16.onnx` |
| Real-ESRGAN | رفع الدقة ×4 | `real_esrgan_x4.onnx` | مرفوع ومربوط بالكود | `https://huggingface.co/Toufikben/productchat-models/resolve/main/real_esrgan_x4.onnx` |
| Qwen-Image-Edit | تعديل محادثي متقدم للصورة | API بعيد، لا يوجد ONNX محلي | API مهيأ، يحتاج مفتاحًا واختبارًا فعليًا | WaveSpeed Qwen Image Edit API |

## ما تم تنفيذه فعليًا

### 1. مستودع Hugging Face

تم التحقق من تسجيل الدخول إلى حساب `Toufikben` والوصول إلى مستودع `Toufikben/productchat-models`. يحتوي المستودع حاليًا على ملفات النماذج التالية:

- `migan.onnx`
- `lama_fp16.onnx`
- `lama_fp32.onnx`
- `real_esrgan_x4.onnx`
- `RealESRGAN_x4plus.pth`
- ملفات README وملفات تراخيص LaMa وReal-ESRGAN.

تم رفع النماذج الثلاثة المطلوبة في commit Hugging Face الأصلي رقم `94592115e5ec95fe6be57f99ba6927da98f27795`. حالة المستودع الحالية تشير إلى commit أحدث هو `c9f69e8cffbdc48ee04a70dae4f5657cd4412d66` بعد تحديث بطاقة النموذج.

لم يتم رفع keystore أو أي secret إلى Hugging Face.

### 2. MI-GAN

تم الحصول على ملف ONNX فعلي باسم `migan.onnx` من مصدر عام، ثم رُفع إلى مستودع المستخدم. الحجم الذي تم تنزيله والتحقق منه محليًا يقارب 29.5 MB.

قيمة SHA-256 المسجلة في التطبيق:

```text
593eba0b7e04730f1b61c0a3cbca68d97d8d6a7ff5c6a44a7b9d7fcd880fc5ae
```

الرابط المستخدم في التطبيق:

```text
https://huggingface.co/Toufikben/productchat-models/resolve/main/migan.onnx
```

تم التحقق من أن الرابط يعيد HTTP 200، وأن hash الملف المنزّل من Hugging Face يطابق القيمة المحلية.

ما لم يتم إثباته بعد هو نجاح inference كامل على جهاز Android حقيقي، وتطابق tensor contract مع قناة Android `MIGanChannel` على جميع أحجام الصور.

### 3. LaMa

تم تنزيل `lama_fp32.onnx` من مستودع `Carve/LaMa-ONNX`. بعد ذلك تم تحويل نسخة FP32 إلى FP16 باستخدام `onnx` و`onnxconverter-common` مع إبقاء أنواع الإدخال والإخراج مناسبة للتشغيل.

الملف المستخدم في التطبيق هو:

```text
lama_fp16.onnx
```

الحجم التقريبي هو 103 MB.

قيمة SHA-256:

```text
37f2e4888eb27aa08841786b506fa094156c497de3d954ebf7a297c61a7fb4ea
```

الرابط المستخدم في التطبيق:

```text
https://huggingface.co/Toufikben/productchat-models/resolve/main/lama_fp16.onnx
```

تم التحقق من HTTP 200 ومن تطابق SHA-256 بعد تنزيل الملف من الرابط النهائي.

يجب لاحقًا اختبار contract الإدخال الفعلي، وخصوصًا شكل الصورة والقناع، وأبعاد 512×512، واستهلاك الذاكرة على Android.

### 4. Real-ESRGAN

تم استخدام ملف ONNX فعلي من مصدر عام لموديل Real-ESRGAN x4، ثم رُفع إلى المستودع باسم متوافق مع التطبيق:

```text
real_esrgan_x4.onnx
```

الحجم التقريبي هو 64 MB.

قيمة SHA-256:

```text
5c586662929cbc686c1a5c38d9c060dbdb4ea5863a1f7672b8c0761e6b89c033
```

الرابط المستخدم في التطبيق:

```text
https://huggingface.co/Toufikben/productchat-models/resolve/main/real_esrgan_x4.onnx
```

تم التحقق من HTTP 200 ومن تطابق SHA-256.

يوجد أيضًا في مستودع Hugging Face ملف `RealESRGAN_x4plus.pth`، لكنه ليس الملف الذي يستخدمه التطبيق. لا ينبغي أن يحاول التطبيق تحميل ملف PTH على أنه ONNX.

ما تبقى هو اختبار tensor contract، وقياس الذاكرة، والتحقق من أن الناتج النهائي يحافظ على أبعاد الصورة ويعمل على Android ARM64.

## تنفيذ التطبيق المرتبط بالنماذج

### `lib/core/constants.dart`

تم تثبيت روابط النماذج الثلاثة وقيم SHA-256 الفعلية. أزيلت ثوابت Qwen المحلية:

- `modelMiganUrl`
- `modelLamaUrl`
- `modelRealEsrganUrl`
- `modelMiganSha256`
- `modelLamaSha256`
- `modelRealEsrganSha256`

لم تعد هناك ثوابت `modelQwenEditUrl` أو `modelQwenEditSha256`.

### `lib/services/model_manager.dart`

يدير `ModelManager` حاليًا ثلاثة نماذج فقط:

```text
migan.onnx
lama_fp16.onnx
real_esrgan_x4.onnx
```

ويقوم بالوظائف التالية:

1. إنشاء مجلد نماذج داخل `Application Support`.
2. تنزيل الملفات عبر Dio.
3. دعم استكمال التنزيل باستخدام ملف `.part`.
4. التحقق من SHA-256 بعد اكتمال التنزيل.
5. حذف الملف التالف عند فشل التحقق.
6. الإبلاغ عن حالة التخزين المؤقت.
7. حذف نموذج منفرد أو جميع النماذج.

تم إصلاح ملاحظات lint الخاصة بالملف عبر إبقاء I/O غير متزامن وإضافة `ignore_for_file` لملاحظة `avoid_slow_async_io`، مع إضافة الأقواس المطلوبة حول progress callback.

### `lib/services/ai/qwen_edit_service.dart`

تم استبدال التنفيذ المحلي الذي كان يحاول فتح `qwen_edit_int8.onnx` بخدمة API بعيدة. الخدمة الحالية:

1. تقرأ المفتاح من `String.fromEnvironment('QWEN_API_KEY')`.
2. ترفض التنفيذ برسالة واضحة إذا لم يكن المفتاح موجودًا.
3. ترفع الصورة والـ prompt بصيغة multipart.
4. ترسل الطلب إلى WaveSpeed Qwen Image Edit API.
5. تستخرج task ID.
6. تستطلع النتيجة كل ثانيتين لمدة تصل إلى 60 ثانية.
7. تنزل الصورة الناتجة إلى ملف باسم ينتهي بـ `_qwen.png`.
8. تعيد `EditResult` متوافقًا مع بقية التطبيق.

يتم تمرير المفتاح وقت البناء، مثل:

```bash
flutter build apk --dart-define=QWEN_API_KEY=YOUR_KEY
```

لا يجوز وضع المفتاح في:

- `constants.dart`.
- `pubspec.yaml`.
- GitHub repository.
- Hugging Face model repository.
- ملفات Dart المرفوعة.

### `QwenEditChannel.kt`

ما زال ملف Android الأصلي موجودًا في المشروع، لكنه لم يعد مسار التنفيذ المستخدم في `QwenEditService` بعد الانتقال إلى API. ينبغي اعتباره كودًا قديمًا يحتاج إما إلى إزالة منظمة في مهمة مستقلة، أو إبقاؤه مؤقتًا حتى يتم التأكد من عدم وجود استهلاك له من أي جزء آخر من التطبيق.

لا ينبغي إعادة تفعيل هذا الجسر دون إعادة تصميم pipeline كاملة، لأن Qwen ليس نموذج صورة واحدًا بمدخل RGB وtokens بطول 77.

## التحقق الذي تم إنجازه

تم إجراء التحققات التالية:

- فحص HTTP 200 للروابط الثلاثة.
- تنزيل الملفات الثلاثة من الروابط النهائية.
- حساب SHA-256 عن بُعد ومقارنته بالقيم المحلية.
- `flutter pub get` نجح بعد إضافة API implementation.
- `flutter build apk --debug` نجح بعد ترحيل Qwen إلى API.
- التحليل المركز لملفات `ModelManager` و`voice_service.dart` و`watermark_preset_service.dart` أصبح بلا ملاحظات:

```text
No issues found!
```

- تم رفع التغييرات إلى GitHub في commit `5fecf69` بعد مزامنة الفرع مع آخر تغييرات GitHub.

## ما تبقى من العمل

### أ. اختبارات تشغيل النماذج على Android

لم يثبت وجود inference ناجح على هاتف أو Emulator حقيقي لكل نموذج. يجب تنفيذ اختبار Android يتضمن:

1. تنزيل MI-GAN من Hugging Face.
2. التحقق من SHA-256 داخل التطبيق.
3. تحميل ONNX session بنجاح.
4. إرسال صورة اختبار.
5. مقارنة الناتج مع expected output أو على الأقل التأكد من ملف PNG صالح.
6. تحرير الموارد وإغلاق session.
7. تكرار الاختبار مع LaMa وReal-ESRGAN.
8. قياس زمن التنفيذ والذاكرة.
9. اختبار انقطاع الشبكة واستكمال التنزيل.
10. اختبار ملف تالف والتأكد من حذفه وإعادة تنزيله.

### ب. اختبار عقود tensors

يجب توثيق عقود الإدخال والإخراج لكل نموذج بدل الاعتماد على الاسم فقط:

| النموذج | المطلوب توثيقه |
|---|---|
| MI-GAN | أسماء tensors، نوع البيانات، الأبعاد، شكل القناع، المجال العددي، شكل الناتج |
| LaMa | image tensor، mask tensor، أبعاد 512×512، مجال mask، مجال الناتج |
| Real-ESRGAN | أبعاد الإدخال الديناميكية، RGB/BGR، مجال القيم، مقياس ×4 |

إذا كان أحد artifacts لا يطابق القناة الأصلية، يجب تغيير القناة أو استبدال artifact، وليس الاكتفاء بتغيير اسم الملف.

### ج. اختبار Qwen API فعليًا

تكامل Qwen لن يعتبر متحققًا حتى يتم توفير مفتاح صالح خارج Git وتشغيل طلب فعلي. يجب اختبار:

1. صورة منتج صغيرة.
2. prompt إنجليزي.
3. prompt عربي إن كان endpoint يدعمه.
4. استجابة task ID.
5. حالات `completed` و`failed` وtimeout.
6. URL الناتج وصلاحية تنزيله.
7. إلغاء الطلب أو انقطاع الشبكة.
8. عدم طباعة المفتاح في logs.
9. التعامل مع rate limit وHTTP 401 وHTTP 429.
10. التأكد من سياسة الاحتفاظ بالصور لدى مزود API.

يجب أيضًا تأكيد أن schema WaveSpeed الحالي يطابق endpoint المستخدم، لأن API خارجي قد يغيّر أسماء الحقول أو مسار polling. يفضل إضافة اختبار تكامل لا يعمل إلا عند توفير متغير بيئة محلي.

### د. إدارة مفتاح Qwen في CI/CD

لا يجب تمرير المفتاح في أوامر GitHub الظاهرة أو logs. الخيار الصحيح هو GitHub Actions Secret باسم مثل:

```text
QWEN_API_KEY
```

ثم استخدامه في خطوة build بطريقة تمنع ظهوره في السجل. لا ينبغي وضعه داخل APK إذا كان التطبيق موزعًا على مستخدمين عامين، لأن `--dart-define` داخل تطبيق العميل ليس حماية حقيقية للسر. الحل الأكثر أمانًا هو وضع API key في backend وسيط، ثم استخدام authentication خاص بالتطبيق مع rate limiting.

### هـ. تنظيف مسار Qwen المحلي القديم

يجب اتخاذ قرار صريح بشأن `QwenEditChannel.kt`:

- إزالته إذا لم يعد مطلوبًا.
- أو إبقاؤه مع توثيق أنه غير مستخدم.
- أو استبداله بجسر API إذا كان هناك سبب لاستخدام native networking.

قبل الحذف يجب التأكد من `MainActivity.kt` ومن عدم وجود اختبارات تعتمد على القناة.

### و. إصلاح التحليل العام للمشروع

التحليل المركز للنماذج الثلاثة أصبح نظيفًا، لكن التحليل الكامل للمشروع ما زال يعرض مشاكل في ملفات أخرى. آخر تحليل كامل بعد إصلاحات الصوت وwatermark أظهر 243 issue، منها warnings وinfos وأخطاء في خدمات وواجهات أخرى.

يجب فصل هذه الأعمال إلى حزم مستقلة بدل ربطها بتكامل النماذج:

1. أخطاء type-safety في Hive وواجهات UI.
2. imports غير مستخدمة.
3. استدعاءات API deprecated.
4. شروط وحلقات بلا أقواس.
5. أخطاء الخدمات التي تستخدم `dynamic`.
6. اختبارات الوحدات واختبارات العقود.

لا يصح إعلان المشروع جاهزًا للإصدار اعتمادًا على أن ملفات النماذج وحدها خالية من الملاحظات.

### ز. بناء Release والتحقق من التوقيع

تم التحقق سابقًا من بناء Debug، لكن يلزم بعد آخر التعديلات تشغيل:

```bash
flutter clean
flutter pub get
flutter gen-l10n
flutter build apk --release --dart-define=QWEN_API_KEY=...
flutter build appbundle --release --dart-define=QWEN_API_KEY=...
```

يجب أن يتم التوقيع باستخدام أسرار GitHub أو بيئة CI آمنة. لا ينبغي رفع keystore إلى المستودع.

### ح. تحديث الوثائق القديمة

توجد داخل `docs/ai_package/` ملفات تعليمات قديمة تشير إلى `qwen_edit_int8.onnx` والتنفيذ المحلي. هذه الملفات هي سجل تاريخي للحزمة، لكنها قد تسبب التباسًا. يجب إضافة ملاحظة واضحة في وثيقة الفهرس بأن:

- Qwen المحلي لم يعد الخطة الحالية.
- الخطة الحالية هي WaveSpeed API.
- روابط النماذج الثلاثة في `lib/core/constants.dart` هي مصدر الحقيقة.
- أي ذكر سابق لـ `qwen_edit_int8.onnx` تاريخي وليس artifact صالحًا.

كما يجب تحديث `docs/ROADMAP_VERIFICATION_2026-09-13.md` إذا كان التقرير سيستخدم كمرجع إصدار، لأن بعض فقراته تقول إن MI-GAN غير مرفوع أو أن Real-ESRGAN لا يملك artifact ONNX، وهذه المعلومات لم تعد تعكس الحالة الحالية.

## ما لا ينبغي فعله

لا ينبغي تنفيذ أي من الإجراءات التالية:

- إعادة تسمية GGUF أو Safetensors إلى `.onnx`.
- رفع ملف PTH ثم تعديل الرابط ليبدو كأنه ONNX.
- وضع API key داخل `constants.dart`.
- رفع keystore إلى GitHub.
- اعتبار HTTP 200 دليلًا كافيًا على صحة inference.
- اعتبار وجود ONNX في المستودع دليلًا على توافق tensor contract.
- تشغيل Qwen المحلي بمدخل tokens وهمية أو tokenizer مبسط.
- حذف ملفات Qwen الأصلية دون فحص كل المراجع أولًا.

## خطة التنفيذ المقترحة بالترتيب

### المرحلة الأولى: تثبيت الحالة الحالية

يجب اعتماد commit GitHub الأخير كمرجع، ثم تشغيل `flutter pub get` و`flutter gen-l10n` والتحقق من أن working tree نظيف. بعد ذلك تُراجع روابط النماذج الثلاثة وقيم SHA-256 في `constants.dart`.

### المرحلة الثانية: اختبار التنزيل والتحقق

ينبغي إضافة اختبارات آلية لـ `ModelManager` تستخدم Dio mock أو local HTTP server. يجب أن تغطي الاختبارات التنزيل الكامل، الاستكمال، SHA mismatch، وحالة unknown model.

### المرحلة الثالثة: اختبار Android runtime

يجب تنفيذ اختبار على Android ARM64 لكل نموذج. يفضل البدء بصورة صغيرة وبعدد خيوط محدود، ثم تسجيل الذاكرة وزمن التنفيذ والنتيجة.

### المرحلة الرابعة: اختبار Qwen API

بعد توفير مفتاح خارج المستودع، يُنفذ اختبار تكامل يدوي أو آلي محلي. يتم تسجيل status codes ومدة التنفيذ وحالات الفشل دون تسجيل المفتاح أو الصور الحساسة.

### المرحلة الخامسة: CI وRelease

بعد نجاح اختبارات runtime، يتم إعداد GitHub Actions لاستخدام secrets، ثم بناء APK وAAB Release، والتحقق من التوقيع، والتأكد من أن النماذج لا تدخل داخل APK وأنها تُنزّل عند الحاجة.

### المرحلة السادسة: تحديث خارطة الطريق

بعد إتمام الاختبارات، يجب نقل البنود من “موجود في المصدر” إلى “متحقق آليًا” أو “متحقق على Android” فقط مع إرفاق logs أو artifacts قابلة لإعادة الإنتاج.

## مصفوفة الحالة النهائية

| البند | الحالة الحالية | الدليل | المتبقي |
|---|---|---|---|
| حساب Hugging Face | مكتمل | الحساب `Toufikben` متصل | لا شيء |
| مستودع النماذج | مكتمل | `Toufikben/productchat-models` موجود | تحديث README عند الحاجة |
| MI-GAN artifact | مرفوع ومتحقق hash | HTTP 200 وSHA مطابق | Android inference |
| LaMa FP16 artifact | مرفوع ومتحقق hash | HTTP 200 وSHA مطابق | Android tensor/runtime test |
| Real-ESRGAN ONNX artifact | مرفوع ومتحقق hash | HTTP 200 وSHA مطابق | Android tensor/runtime test |
| Qwen ONNX | مستبعد عمدًا | لا يوجد ONNX متوافق جاهز | API integration test |
| Qwen API code | منفذ | `QwenEditService` يستخدم Dio وpolling | مفتاح صالح واختبار endpoint |
| ModelManager | منفذ للنماذج الثلاثة | تنزيل واستكمال وSHA verification | اختبارات آلية وruntime |
| Android channels | موجودة جزئيًا | MI-GAN وLaMa ومسارات native | تحقق فعلي على Android |
| Flutter focused analyze | ناجح | `No issues found!` للملفات المستهدفة | لا شيء لهذه الملفات |
| Flutter full analyze | غير مكتمل | 243 issue في المشروع الكامل | حزمة إصلاح مستقلة |
| Debug APK | بُني بنجاح سابقًا | `flutter build apk --debug` | إعادة البناء بعد آخر تعديلات اختيارية |
| Release APK/AAB | غير مثبت في هذا التقرير | لا يوجد artifact جديد بعد آخر commit | بناء وتوقيع Release |
| GitHub synchronization | مكتمل | الفرع `main` متزامن، آخر commit `5fecf69` | لا شيء |

## الخلاصة النهائية

تم تنفيذ الجزء الخاص بتوفير ثلاثة نماذج Hugging Face وربطها بالتطبيق والتحقق من سلامة التنزيل والـ hash. تم اتخاذ قرار صحيح باستبعاد Qwen من ONNX بدل رفع artifact غير صالح، ثم إعداد بديل API قابل للتشغيل عند توفير مفتاح صالح.

المهمة المتبقية ليست رفع ملفات إضافية إلى Hugging Face، بل إثبات التشغيل الفعلي على Android، توثيق عقود tensors، اختبار API خارجي، تأمين مفتاح Qwen، بناء Release موقّع، وتحديث الوثائق القديمة التي لا تزال تشير إلى مسار Qwen المحلي أو إلى حالة نماذج قديمة.

## المراجع

[1]: https://huggingface.co/Toufikben/productchat-models "ProductChat Studio Hugging Face model repository"
[2]: https://huggingface.co/Carve/LaMa-ONNX "Carve LaMa ONNX model repository"
[3]: https://huggingface.co/andraniksargsyan/migan "MI-GAN ONNX model repository"
[4]: https://huggingface.co/SceneWorks/real-esrgan-onnx "Real-ESRGAN ONNX model repository"
[5]: https://huggingface.co/Qwen/Qwen-Image-Edit "Qwen Image Edit official model card"
[6]: https://github.com/triple-mu/Qwen-Image-TensorRT "Qwen Image TensorRT ONNX export experiments"
[7]: https://onnxruntime.ai/docs/ "ONNX Runtime documentation"
[8]: https://github.com/toufikben/productchat_studio "ProductChat Studio GitHub repository"
