# قرار التنفيذ والخصائص المتبقية — 2026-09-15

## القرار الأول: تأجيل Qwen مؤقتاً

المقصود بالبند السابع هو **التعديل المحادثي العام عبر Qwen**. قررنا تأجيله بسبب تكلفة كل طلب، وليس إلغاءه. ستعمل النسخة الأولى بالوظائف المحلية المتخصصة، ثم يُعاد فتح Qwen عندما تتوفر ميزانية Backend وWaveSpeed ونظام Credits موثوق.

التأجيل يعني:

- عدم تضمين اتصال WaveSpeed في مسار الإصدار العام حالياً.
- عدم وضع مفتاح Qwen داخل APK، حتى لو كان Base64 أو مشفراً شكلياً.
- إبقاء كود Qwen موثقاً خلف Feature Flag أو مسار غير منشور.
- عدم بيع وعد “تعديل محادثي عام” قبل توفير Backend وحماية المفتاح.
- إطلاق الوظائف المحلية التي لا تحتاج شبكة أو تكلفة لكل صورة.

## مقارنة النماذج والخيارات

> **مهم:** حجم الأوزان ليس حجم التطبيق. يجب إضافة ONNX Runtime أو MediaPipe أو OpenCV، وذاكرة الاستدلال، وملفات preprocessing وpostprocessing إلى حساب الحجم النهائي. بعض الأرقام أدناه أحجام artifact منشورة، وبعضها تقدير أو غير منشور بوضوح.

| الوظيفة والخيار | الحجم المعلن أو الحالة | مكان التنفيذ | السعر التشغيلي | الجودة مقارنة بـ Qwen | الحكم |
|---|---:|---|---:|---|---|
| MODNet Photographic | ONNX نحو 25 MB | الهاتف عبر ONNX Runtime | صفر لكل صورة | أفضل من Qwen في alpha matte وإزالة الخلفية المتخصصة، وأضعف في التعديل العام | أفضل مرشح محلي لإزالة الخلفية، يحتاج اختبار منتجات |
| MediaPipe/ML Kit Segmentation | حجم نموذج ML Kit غير ثابت في المستندات؛ dependency صغيرة، والتنزيل قد يحدث لاحقاً | الهاتف، وقد يعتمد ML Kit على Google Play services | صفر لكل صورة | أقل من Qwen في الحواف والتعديلات العامة؛ جيد لقناع شخص/جسم بسيط | fallback سهل، وليس matting كاملاً |
| MobileSAM | نحو 40.7 MB للـpipeline حسب جدول Ultralytics | الهاتف بعد دمج ONNX/Runtime | صفر لكل صورة | أفضل من Qwen في اختيار منطقة محددة؛ لا يقوم بالتعديل أو الإكمال | مساعد لإنشاء القناع فقط |
| MI-GAN | حجم pipeline ONNX الرسمي غير منشور بوضوح | الهاتف بعد ONNX Runtime | صفر لكل صورة | جيد للإكمال المحلي المقيد بالقناع؛ أضعف من Qwen في الفهم الدلالي والتعديلات العامة | مرشح inpainting بعد PoC Android |
| LaMa | الوزن الرسمي غير موحد؛ نسخة ONNX طرف ثالث نحو 208 MB FP32 | الهاتف القوي أو Backend محلي | صفر لكل صورة محلياً | قوي في الأنماط والفراغات الكبيرة، لكنه لا يفهم التعليمات مثل Qwen | مرجع جودة، ليس الخيار الأخف |
| OpenCV Telea/Navier–Stokes | لا أوزان، حجم نموذج صفر | الهاتف | صفر لكل صورة | أقل بكثير من Qwen؛ مناسب للخدوش والفراغات الصغيرة | fallback سريع وآمن |
| Real-ESRGAN-General-x4v3 | 4.65 MB float أو 1.25 MB w8a8 حسب Qualcomm | الهاتف عبر TFLite/ONNX بعد التحقق | صفر لكل صورة | أفضل من Qwen في رفع الدقة المتخصص؛ لا يقوم بتعديل دلالي | أفضل توازن مبدئي للـupscale |
| FSRCNN-small x4 | أوزان نحو 11 KB؛ runtime غير محسوب | الهاتف عبر OpenCV أو تحويل ONNX | صفر لكل صورة | أقل جودة من Qwen وReal-ESRGAN، لكنه سريع وصغير جداً | خيار للأجهزة الضعيفة |
| Real-ESRGAN-x4plus | 63.9 MB float أو 16.7 MB w8a8 | الهاتف القوي أو Backend | صفر محلياً | أعلى جودة upscale غالباً، لكن ليس محرراً عاماً مثل Qwen | خيار جودة، لا للأجهزة الدنيا |
| Shadow Compositor | لا نموذج | الهاتف، Flutter/Native Canvas | صفر لكل صورة | لا يقارن بـQwen؛ يعطي ظلاً قابلاً للتحكم أكثر استقراراً من توليد عشوائي | الأفضل للإصدار الأول |
| Zero-DCE | checkpoint نحو 320 KB، لكن لا TFLite/ONNX رسمي ثابت | الهاتف بعد تحويل واختبار | صفر لكل صورة | جيد لتحسين الإضاءة، لا يساوي Qwen في relighting الدلالي؛ ترخيصه غير تجاري افتراضياً | بحثي/غير معتمد تجارياً حالياً |
| DDColor-Tiny | الحجم غير منشور بشكل موثوق | الهاتف بعد ONNX export والقياس | صفر لكل صورة | أفضل من Qwen في وظيفة colorize المتخصصة إذا نجح؛ لا يفهم أوامر عامة | مرشح لاحقاً، يحتاج artifact مثبت |
| Qwen-Image-Edit عبر WaveSpeed | نموذج 20B؛ لا يمكن وضعه عملياً في الهاتف | خادم WaveSpeed عبر Backend | يبدأ تقريباً من 0.02 USD/run حسب صفحة النموذج، والسعر قابل للتغير | الأفضل للتعديل المحادثي العام، إضافة/حذف عناصر، النصوص، والتعديلات متعددة الخطوات | مؤجل بسبب التكلفة، وليس محذوفاً |
| FLUX.1 Kontext API | 12B؛ ليس للهاتف | خادم API | تقريباً 0.04–0.08 USD للصورة حسب النسخة المنشورة | منافس قوي للاتساق والتعديلات المتتابعة؛ لا يبرر تكلفة الآن | ليس بديلاً محلياً |
| Stability Inpaint API | لا حجم محلي | خادم API | نحو 0.05 USD للنجاح وفق 5 credits، قابل للتغير | جيد عندما يوجد قناع؛ أضعف من Qwen في التعديل المحادثي العام | مؤجل مع Qwen |
| Gemini/Nano Banana API | لا حجم محلي | خادم API | يعتمد على النموذج/التوكن؛ لا نثبت رقماً دون جدول حالي | محادثي قوي، لكن التكلفة والسياسة والتوفر متغيرة | للمقارنة المستقبلية فقط |

## أيها أفضل؟

لا يوجد فائز واحد لكل الوظائف. أفضل اختيار بحسب العملية هو:

| الأولوية | الأفضل |
|---|---|
| إزالة الخلفية محلياً | MODNet، مع اختبار صور المنتجات |
| اختيار الكائن وإنشاء القناع | MobileSAM مع Mask Painter كتصحيح يدوي |
| Inpainting محلي | MI-GAN بعد اختبار Android، وLaMa كمرجع جودة |
| رفع الدقة | Real-ESRGAN-General-x4v3، ثم FSRCNN-small للأجهزة الضعيفة |
| إضافة ظل | Shadow Compositor حتمي، بدون AI |
| تحسين إضاءة مجاني | أدوات exposure/curves المحلية |
| تلوين محلي | DDColor-Tiny بعد إثبات artifact والترخيص |
| تعديل محادثي عام | Qwen، لكنه مؤجل ويحتاج Backend مدفوع |

لذلك لا نستبدل Qwen بنموذج واحد. نستبدل **وظائف Qwen المتخصصة** بمسارات محلية، ونؤجل فقط الجزء الذي يحتاج فهماً عاماً وتوليداً دلالياً.

## الخصائص التي لم تُغلق بعد

### أ. بوابة النماذج المحلية وAndroid

هذه هي الأولوية الأولى قبل إعلان الميزات جاهزة:

1. تشغيل MI-GAN فعلياً على Android ARM64، مع image/mask tensor contract وقياس output.
2. تشغيل LaMa أو اعتماد MI-GAN بديلاً عنه بعد مقارنة الجودة والذاكرة.
3. تشغيل Real-ESRGAN فعلياً؛ الحالة الحالية في مصفوفة التحقق ما زالت fallback وليست runtime مكتمل.
4. اختبار MODNet أو بديل matting على صور المنتجات.
5. تجربة MobileSAM، والتحقق من ONNX operators وpost-processing والذاكرة.
6. تنفيذ DDColor-Tiny فقط بعد تثبيت ONNX وchecksum والترخيص.
7. تثبيت model artifacts داخل مسار بناء قابل لإعادة الإنتاج، لا تنزيل حي من الإنترنت.

### ب. جودة العمليات

1. بناء مجموعة صور اختبار تشمل الشعر، الزجاج، البلاستيك، الحواف البيضاء، الخلفيات المعقدة، النصوص العربية، والظلال الموجودة.
2. قياس الزمن والذاكرة والحرارة على جهاز منخفض ومتوسط وعالي.
3. إضافة fallback واضح لكل وظيفة عند فشل النموذج.
4. اختبار الصور الكبيرة، الضغط، EXIF، الاتجاه، وعمليات undo/redo.
5. تثبيت قرار جودة الظل على Compositor حتمي، ثم تحسينه دون إدخال API.

### ج. المحرر والتدفق الأساسي

1. إغلاق `edit.inpaint` بعد إثبات native runtime وmask/output.
2. إغلاق `edit.remove_background` بعد device runtime وquality fixtures.
3. إغلاق `edit.upscale` بعد استبدال bounded Bitmap fallback بنموذج مثبت أو توثيق المقايضة.
4. إغلاق `edit.shadow` بعد اختبار الأداء على Bitmap حقيقية.
5. إغلاق `edit.export` باختبار End-to-End يشمل PNG/JPEG والشفافية والعلامة المائية.
6. إغلاق `chat` باختبار صورة/قناع/dispatch/result، حتى بدون Qwen.
7. إغلاق `editor.state` بالتحقق من history وundo والنتائج بعد إعادة التشغيل.

### د. الدفعات والتجارة

1. اختبار Batch فعلياً على 100 صورة وقياس الذاكرة والزمن والإلغاء والاستئناف.
2. تشغيل واختبار Pro/Lifetime gates وFree Quota وwatermark بعد كل عملية ناجحة فقط.
3. إكمال Google Play Console والمنتجات الحقيقية وrestore وexpiry.
4. جعل Billing server-authoritative قبل منح Credits نهائية؛ السجل المحلي الحالي ليس دليلاً كافياً ضد التلاعب.
5. التحقق من lifetime؛ المصفوفة الحالية تسجله كمواصفة فقط وليس منتجاً منشأً ومختبراً.

### هـ. الخصوصية والجودة والإطلاق

1. مراجعة قانونية للترخيص، خصوصاً RVM وFastSAM وZero-DCE وRMBG وDDColor checkpoints.
2. تنفيذ اختبارات Flutter التي لم تُشغّل، ثم معالجة مشاكل `flutter analyze` المسجلة.
3. اختبار Android فعلي أو Emulator مع evidence لكل نموذج.
4. إكمال privacy/terms وdelete semantics وEXIF وlogs وعدم تسريب الصور.
5. إكمال crash reporting، analytics، rate limits، وsupport flow.
6. توقيع Release AAB، اختبار الترقية، migration، وrollback.
7. إبقاء Qwen مخفياً من الإصدار العام حتى يتوفر Backend؛ لا نضع مفتاحاً في APK.

## ترتيب الإغلاق المقترح

| المرحلة | الهدف |
|---|---|
| 1 | Android runtime لـ MI-GAN وReal-ESRGAN وعمليات الظل والتصدير |
| 2 | MODNet وMobileSAM كـPoC ثم قرار الاعتماد |
| 3 | إغلاق المحرر والقناع والتاريخ والـfallbacks |
| 4 | اختبار Batch وBilling وFree/Pro gates |
| 5 | Flutter analyze/test وAndroid device matrix |
| 6 | privacy/license/release signing وPlay Console |
| مؤجل | Qwen/WaveSpeed وBackend وCredits المدفوعة |

## الخلاصة

النسخة الأولى يمكن أن تكون مفيدة دون Qwen إذا ركزت على إزالة الخلفية، القناع، Inpainting، رفع الدقة، الظل، التصدير، والدفعات. Qwen يضيف مرونة كبيرة لكنه ليس شرطاً لإطلاق الأساس. القرار الصحيح هو **تأجيل التكلفة لا حذف الفكرة**، مع إبقاء الواجهة قابلة لإضافة Backend لاحقاً.

### المصادر

[1]: https://github.com/ZHKKKe/MODNet "MODNet"
[2]: https://github.com/chaoningzhang/mobilesam "MobileSAM"
[3]: https://github.com/Picsart-AI-Research/MI-GAN "MI-GAN"
[4]: https://github.com/advimman/lama "LaMa"
[5]: https://aihub.qualcomm.com/iot/models/real_esrgan_general_x4v3 "Real-ESRGAN General x4v3"
[6]: https://github.com/Saafke/FSRCNN_Tensorflow "FSRCNN"
[7]: https://github.com/piddnad/DDColor "DDColor"
[8]: https://wavespeed.ai/models/wavespeed-ai/qwen-image/edit "WaveSpeed Qwen Image Edit"
[9]: https://platform.stability.ai/pricing "Stability AI pricing"
[10]: https://docs.bfl.ml/quick_start/pricing "Black Forest Labs API pricing"
