# خارطة طريق التحقق والتصحيح والإضافة

**المشروع:** ProductChat Studio  
**المرجع البرمجي المفحوص:** `main` عند الالتزام `fb20f125134d381bbc655883008a4f214aebde74`  
**تاريخ إعداد الخارطة:** 2026-09-13  
**الغرض:** اكتشاف الفرق بين ما هو موجود فعليًا في الكود أو Hugging Face، وما هو موثق فقط، وما يحتاج إصلاحًا أو إضافة أو تحسينًا.

## 1. قاعدة الحالة المعتمدة

لا تُعتبر أي ميزة مكتملة بسبب وجود ملف أو شاشة أو dependency فقط. يجب أن تمر الميزة بالمراحل التالية:

| الحالة | معناها |
|---|---|
| **موجود في المصدر** | يوجد class/function/screen أو artifact يمكن الإشارة إليه مباشرة |
| **موصول** | هناك مسار فعلي من UI أو controller إلى الخدمة أو الجسر |
| **قابل للتنفيذ** | لا يعيد Stub/placeholder ويُنتج النتيجة المتوقعة |
| **متحقق آليًا** | يوجد unit/widget/integration test ناجح |
| **متحقق على Android** | بُني التطبيق وشُغّل المسار على جهاز أو محاكي |
| **جاهز للإصدار** | يتضمن الأداء، الأخطاء، الخصوصية، الترخيص، الدفع، signing، وCI |

**قاعدة القرار:** إذا فشلت مرحلة، لا تُرفع الميزة إلى المرحلة التالية. وجود model file لا يساوي inference ناجحًا، ووجود screen لا يساوي feature مكتملة.

## 2. نتيجة التحقق المباشر من Hugging Face

تم فحص المستودع العام `Toufikben/productchat-models` مباشرة عبر صفحة المستودع وواجهات Hugging Face العامة.

| artifact | موجود؟ | الحجم | SHA-256 المعلن | الترخيص/الملاحظات | توافقه الحالي |
|---|---:|---:|---|---|---|
| `lama_fp32.onnx` | نعم | 208,044,816 bytes | `1faef5301d78db7dda502fe59966957ec4b79dd64e16f03ed96913c7a4eb68d6` | Apache-2.0؛ يتطلب attribution لـ Places2 وفق بطاقة النموذج | مناسب مبدئيًا لعقد LaMa الموجود في Android |
| `RealESRGAN_x4plus.pth` | نعم | 67,040,989 bytes | `4fa0d38905f75ac06eb49a7951b426670021be3018265fd191d2125df9d682f1` | BSD-3-Clause | **غير مناسب مباشرة** لـ `onnxruntime-android`؛ الكود لا ينفذه |
| MI-GAN | لا | — | — | الأوزان غير مضافة بسبب غموض ترخيص إعادة التوزيع التجاري | لا يُضاف قبل قرار قانوني مكتوب |
| DreamLite | لا | — | — | مستبعد من بطاقة المستودع | غير مطلوب حاليًا |

### عقد LaMa المثبت في بطاقة النموذج

- `image`: `[1, 3, 512, 512]`، `float32`
- `mask`: `[1, 1, 512, 512]`، `float32`
- قيمة mask: `1` للمنطقة المراد حذفها، `0` للمنطقة التي تبقى.
- الخرج RGB بقيم `[0,255]`.

هذا يتوافق مبدئيًا مع `SeikaChannel.kt`، الذي يبني tensors بحجم 512×512 ويشغل `session.run`. لكنه لم يُثبت بعد بتشغيل Android حقيقي.

### ملفات المستودع التي يجب اعتبارها مصدر الحقيقة للنماذج

- `README.md`
- `LICENSE-LAMA.txt`
- `LICENSE-REALESRGAN.txt`
- `lama_fp32.onnx`
- `RealESRGAN_x4plus.pth`

ويجب تثبيت revision/commit وhash في سجل المشروع عند كل تغيير في artifact.

## 3. الجرد الحالي: ما وُجد فعليًا في الكود

| المجال | الموجود فعليًا | الحالة الواقعية | الإجراء |
|---|---|---|---|
| Model Manager | تنزيل، استئناف، checksum، حذف، readiness في `lib/services/model_manager.dart` | منفذ جزئيًا | إضافة اختبارات HTTP وUI وربطه بشاشة Models |
| Smart Analysis | تحليل brightness/background/coverage واقتراح حتى 5 عمليات | منفذ محليًا | توسيع الاختبارات بصور fixtures والتحقق من جودة الترتيب |
| LaMa Android | MethodChannel + ONNX session + tensor preparation + save output | منفذ مبدئيًا غير مثبت runtime | بناء وتشغيل واختبار عقد input/output والذاكرة |
| Real-ESRGAN | artifact `.pth` موجود في HF؛ `runEsrgan` يعيد `null` | غير منفذ | تصدير ONNX/استخدام NCNN أو تعطيل الإعلان عن Real-ESRGAN |
| Background removal | `floodRemove` baseline؛ وقد يستدعي LaMa فقط إذا كانت quality غير fast | fallback/feature جزئي | تعريف pipeline واضح واختبار الجودة وعدم تسميته MI-GAN |
| Inpainting | Dart يتحقق من المسار والقناع؛ Android يستدعي LaMa | منفذ مبدئيًا | اختبار mask semantics والأبعاد وفشل model loading |
| Editor | state، history، undo/redo، text/layers/before | UI/state جزئي | ربط العمليات بمحرّك فعلي؛ `AiService` الحالي يعيد نفس path |
| Batch | اختيار ملفات، تقدم، نسخ إلى temp | Batch file-copy فقط | ربط كل job بعملية تحرير/export حقيقية وإضافة cancel/retry |
| Storage | `Map` داخل الذاكرة فقط | غير دائم | تنفيذ persistence للتاريخ والإعدادات والأرصدة والملفات |
| Billing | class فارغ وdependency فقط | غير منفذ | ربط Google Play Billing أو إزالة paywall من مسار الإصدار |
| Screens | شاشات عديدة موجودة، بعضها `Feature scaffold` أو نص فقط | غير مكتملة | إكمالها أو إخفاؤها من المسار المعلن |
| Routing | Splash/Chat/Editor/Batch فقط | غير مكتمل | إضافة routes للشاشات التي أصبحت فعلية |
| Localization | `en` و`ar` ظاهرتان في شجرة الملفات | غير مكتمل | تحديد هل الهدف لغتان أم 16، ثم اختبار RTL/overflow |
| Android release | SDK 35 وapplicationId وProGuard وManifest أساسي | غير متحقق | إكمال ملفات مشروع Flutter، build، signing، Play checklist |
| Tests | اختباران فقط | تغطية منخفضة | إضافة اختبارات الخدمات، controllers، widgets، والجسر عبر contract tests |

## 4. خارطة الطريق المرحلية

### المرحلة 0 — تثبيت خط الأساس والحقائق

**الهدف:** منع استمرار التناقض بين الوثائق والكود.

المهام:

1. تثبيت commit التطبيق وrevision مستودع Hugging Face في ملف inventory.
2. تحديث `docs/BUILD_AND_REPOSITORY_AUDIT.md` و`docs/VALIDATION.md` و`docs/SEIKA_ANDROID.md` لتطابق الحالة الحالية.
3. إزالة الادعاءات القديمة مثل “لا يوجد مستودع Hugging Face” و`YOUR_ORG` إن لم تعد صحيحة.
4. إنشاء matrix موحدة تحتوي لكل ميزة: source path، runtime path، test، device evidence، owner/status.
5. عدم تعليم أي بند مكتمل إلا مع evidence وtimestamp وcommit.

**معيار الخروج:** لا توجد وثيقة تقول إن artifact أو integration غير موجود بينما هو موجود، ولا تقول إن runtime verified دون نتيجة تشغيل.

### المرحلة 1 — استعادة قابلية البناء

**الهدف:** جعل النتائج قابلة لإعادة الإنتاج.

المهام:

1. توفير Flutter/Dart المتوافقين وتوثيق الإصدار والمسار.
2. تشغيل `flutter pub get` و`flutter gen-l10n` و`flutter analyze` و`flutter test` من clean checkout.
3. فحص اكتمال Android project files وGradle configuration وwrapper.
4. تشغيل `flutter build apk --debug` ثم release build.
5. حفظ سجل النتائج في CI وليس في وثيقة يدوية فقط.

**معيار الخروج:** clean checkout يبني APK ويجتاز التحليل والاختبارات دون اعتماد على ملفات محلية غير موجودة في Git.

### المرحلة 2 — عقد الخدمات والعمليات الأساسية

**الهدف:** إزالة الـ stubs من المسار الذي يراه المستخدم.

المهام:

1. استبدال `AiService.apply` بتكامل فعلي مع `SeikaService`، أو إعادة تصميم الطبقة حتى لا توجد نسختان متعارضتان من Model Manager.
2. ربط remove background وinpaint وupscale وshadow وexport بالمسارات الصحيحة.
3. إضافة explicit operation result errors وعدم اعتبار إعادة نفس المسار نجاحًا.
4. توحيد credits المستخدمة لكل عملية وربطها بنتيجة ناجحة فقط.
5. جعل Batch ينفذ نفس pipeline بدل نسخ المصدر فقط.

**معيار الخروج:** كل زر تحرير ينتج output مختلفًا قابلًا للفحص أو يظهر فشلًا صريحًا، ولا توجد عملية أساسية تعيد input كأنها نجاح.

### المرحلة 3 — التحقق من LaMa على Android

**الهدف:** تحويل LaMa من implementation غير مثبت إلى runtime verified.

المهام:

1. استخدام صورة اختبار ثابتة وقناع اصطناعي مطابق للأبعاد.
2. التحقق من تحميل model من HF بعد checksum.
3. التحقق من أسماء ومدخلات ONNX فعليًا بدل افتراض ترتيب `inputNames`.
4. التحقق من mask semantics: الأبيض/1 للحذف والأسود/0 للإبقاء.
5. اختبار صور أكبر وأصغر، landscape، alpha، وفشل decode.
6. قياس زمن التنفيذ والذاكرة ونتيجة OOM؛ إضافة resize/limits/cleanup.
7. اختبار session lifecycle وunload وإعادة التحميل.

**معيار الخروج:** smoke test على Android ينتج صورة صحيحة من LaMa، مع log للزمن والذاكرة، ولا يحدث crash عند الفشل.

### المرحلة 4 — قرار Real-ESRGAN

**الهدف:** عدم تقديم fallback على أنه نموذج AI.

المسارات الممكنة:

- **المسار A:** توفير Real-ESRGAN بصيغة ONNX متوافقة، التحقق من input/output contract ثم إضافة inference.
- **المسار B:** استخدام runtime مناسب لـ PyTorch/NCNN إذا كان مقبولًا من حيث حجم التطبيق والأداء والترخيص.
- **المسار C:** إبقاء التكبير Bitmap fallback وتغيير الاسم والواجهة إلى “Basic upscale”، مع إزالة ادعاء Real-ESRGAN من الحالة المكتملة.

**معيار الخروج:** واحد من المسارات موثق ومختبر، مع إبقاء `.pth` غير مستخدم كأنه قابل للتشغيل داخل ONNX Runtime.

### المرحلة 5 — إكمال تجربة Android الأساسية

المهام:

1. إكمال Chat upload/dispatch/result.
2. إكمال Editor export، backgrounds، shadow، relight، layers، text.
3. استبدال شاشات `Feature scaffold` بشاشات فعلية أو إزالتها من routes.
4. إضافة routes لـ onboarding/settings/models/history/compliance/recipes/paywall عند جاهزيتها.
5. ربط Models screen بالتنزيل والحذف وoffline readiness.
6. إضافة History حقيقي يعتمد على التخزين الدائم.

**معيار الخروج:** كل route ظاهر قابل للاستخدام ولا توجد شاشة معلنة للمستخدم تعرض placeholder.

### المرحلة 6 — التخزين والخصوصية

المهام:

1. اختيار storage واضح: Hive أو SharedPreferences أو SQLite حسب نوع البيانات.
2. حفظ history/settings/locale/theme/credits بطريقة versioned.
3. إدارة temp files وoutputs وdelete semantics.
4. إضافة Privacy Policy وTerms داخل التطبيق.
5. توثيق أن الصور لا تُرفع خارجيًا إلا بموافقة صريحة.
6. اختبار offline بعد تنزيل النموذج، وانقطاع التنزيل، والاستئناف.

**معيار الخروج:** إغلاق التطبيق وإعادة فتحه لا يفقد الحالة المطلوبة، والمسارات الحساسة تعمل دون شبكة بعد توفر النماذج.

### المرحلة 7 — الدفع والأرصدة

المهام:

1. ربط `in_app_purchase` بالمنتجات الحقيقية.
2. التعامل مع purchase stream وpending/error/restored.
3. خصم الرصيد بعد نجاح العملية فقط.
4. منع double-spend عند إعادة المحاولة.
5. restore purchases وSandbox tests.
6. عدم إظهار Paywall إنتاجي قبل اكتمال العقد.

**معيار الخروج:** يمكن إثبات حالات success/failure/pending/restore دون منح أرصدة خاطئة.

### المرحلة 8 — الاختبارات والأداء وCI

المهام:

1. unit tests لـ Model Manager، Smart Analysis، Storage، Billing، Batch، Editor state.
2. widget tests للشاشات والراوتر وحالات loading/error/empty.
3. contract tests لـ Seika MethodChannel.
4. Android integration tests لـ LaMa وexport.
5. صور fixtures صغيرة ومخرجات متوقعة أو metrics قابلة للمقارنة.
6. قياس حجم النماذج، حجم APK، زمن inference، الذاكرة، وسلوك الأجهزة الضعيفة.
7. GitHub Actions للتحليل والاختبار والبناء وفحص الأسرار.

**معيار الخروج:** كل claim في matrix مرتبط باختبار أو evidence جهاز، وCI يمنع regression.

### المرحلة 9 — جاهزية النشر

المهام:

1. مراجعة Manifest، permissions، FileProvider، icons، splash، package identity.
2. إنشاء keystore خارج Git وإعداد signing آمن.
3. بناء AAB release.
4. مراجعة attribution وlicenses: LaMa/Places2/Real-ESRGAN.
5. مراجعة Google Play requirements وData safety وprivacy declarations.
6. إعداد rollback/versioning.

**معيار الخروج:** Release candidate قابل للتثبيت والتوقيع والتدقيق القانوني، دون secrets أو model artifacts غير مقصودة في Git.

## 5. سجل الإصلاحات ذات الأولوية

| الأولوية | المشكلة | الدليل | الإجراء المطلوب |
|---|---|---|---|
| P0 | Flutter غير متاح لإعادة التحقق | `flutter: command not found` في جلسة التدقيق | استعادة SDK وCI |
| P0 | Editor operations لا تنفذ | `lib/services/ai_service.dart`: `apply` يعيد `imagePath` | ربط Seika أو إزالة الوهم |
| P0 | Android runtime غير مثبت | لا يوجد build/device evidence | debug APK + device smoke test |
| P1 | Storage غير دائم | `Map<String,Object?> _memory` | تنفيذ persistence |
| P1 | Billing فارغ | `BillingService.init` فارغ | تنفيذ أو تعطيل Paywall |
| P1 | Real-ESRGAN غير منفذ | `.pth` + `runEsrgan return null` | ONNX/NCNN أو إعادة تسمية fallback |
| P1 | شاشات كثيرة Scaffold | النص `Feature scaffold` ظاهر في عدة screens | إكمال أو إزالة من المسار |
| P1 | Routes ناقصة | الراوتر يحتوي 4 routes | إضافة routes بعد اكتمال الشاشات |
| P2 | الاختبارات محدودة | ملفان فقط | توسيع التغطية والاختبارات على الجهاز |
| P2 | الوثائق قديمة ومتعارضة | `SEIKA_ANDROID.md` و`BUILD_AND_REPOSITORY_AUDIT.md` | تحديثها من inventory الحالي |

## 6. ما لا ينبغي إضافته الآن

- لا تضف MI-GAN إلى التطبيق أو Hugging Face قبل الحصول على تصريح واضح لإعادة توزيع الأوزان تجاريًا.
- لا تضف iOS أو Web إلى معيار الإصدار الحالي ما دام القرار الرسمي Android-first.
- لا توسع اللغات إلى 16 قبل تحديد ما إذا كان ذلك شرطًا فعليًا للإصدار الأول.
- لا تضف ميزات UI جديدة قبل إزالة العمليات الوهمية وربط المسار الأساسي end-to-end.
- لا تعتبر Real-ESRGAN جاهزًا لمجرد أن ملف `.pth` موجود في Hugging Face.

## 7. شكل سجل التحقق المستقبلي

لكل ميزة، يجب تسجيل الصف التالي في matrix:

| الحقل | مثال |
|---|---|
| Feature ID | `seika.lama.inpaint` |
| Source | `SeikaChannel.kt:82-89` |
| Artifact | HF revision + filename + SHA-256 |
| Entry point | `SeikaService.inpaint` |
| Expected contract | image/mask shapes and value ranges |
| Automated test | test name/path |
| Device test | model/device/OS/date |
| Result | pass/fail/blocked |
| Known limitation | memory, fallback, license |
| Roadmap status | implemented / partial / missing |
| Last verified commit | Git SHA |

## 8. النتيجة الحالية المعتمدة

حتى تاريخ هذا التقرير:

- **Hugging Face موجود فعليًا** وفيه نموذجا LaMa وReal-ESRGAN المذكوران، وليس مجرد repository مخطط له.
- **LaMa مدمج في Android على مستوى الكود**، لكنه غير متحقق ببناء وتشغيل جهاز في البيئة الحالية.
- **Real-ESRGAN artifact موجود، لكن integration غير موجود** لأن الصيغة `.pth` لا تُشغّلها جلسة ONNX الحالية.
- **الواجهة والخدمات ما زالت جزئية**، ووجود الملفات لا يثبت اكتمال الوظائف.
- **خارطة الطريق القديمة تحتاج reconciliation** مع هذه النتائج، خصوصًا بنود HF وSeika وEditor/Batch وبيئة Flutter.

هذه الخارطة هي خطة تحقق وتصحيح، وليست إعلانًا بأن البنود قد أُنجزت.

## مصادر التحقق الخارجي

- [Hugging Face model card](https://huggingface.co/Toufikben/productchat-models)
- [Hugging Face model API](https://huggingface.co/api/models/Toufikben/productchat-models)
- [Hugging Face repository tree API](https://huggingface.co/api/models/Toufikben/productchat-models/tree/main?recursive=true)

**آخر تحديث:** 2026-09-13.
