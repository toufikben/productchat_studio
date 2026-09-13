# تدقيق خارطة الطريق مقابل التنفيذ الفعلي

**المشروع:** ProductChat Studio  
**المستودع:** `toufikben/productchat_studio`  
**الفرع/الالتزام المفحوص:** `main` / `fb20f125134d381bbc655883008a4f214aebde74` (`Prioritize Android and defer iOS and web`)  
**تاريخ التدقيق:** 2026-09-13  
**المنهج:** فحص خارطة الطريق، قراءة مسارات التطبيق والخدمات والجسر الأصلي، البحث عن stubs وواجهات غير موصولة، ومحاولة تشغيل أدوات التحقق.

## الخلاصة التنفيذية

خارطة الطريق مفيدة كوثيقة نوايا، لكنها لا تمثل حالة الإصدار النهائي بعد. توجد أجزاء حقيقية وقابلة للبناء منطقيًا، خصوصًا `ModelManager`، و`SmartAnalysisService`، و`BatchService`، وواجهة Android الخاصة بـ LaMa ONNX، بالإضافة إلى دعم المحرر الأساسي. في المقابل، توجد فجوات تمنع اعتبار التطبيق إصدارًا إنتاجيًا:

1. **التحقق نفسه غير قابل لإعادة الإنتاج في البيئة الحالية:** وثائق التدقيق تقول إن Flutter 3.47.4 موجود وأن `flutter analyze` و`flutter test` نجحا، لكن أمر `flutter` غير موجود فعليًا في جلسة التدقيق، لذلك لم يمكن إعادة تشغيلهما.
2. **التكامل الوظيفي غير مكتمل:** `AiService.apply` يعيد مسار الصورة نفسه ولا ينفذ أي عملية، بينما `EditorController` يعتمد عليه لكل عمليات المحرر.
3. **التخزين والدفع غير منفذين:** `StorageService` ذاكرة مؤقتة فقط، و`BillingService.init` فارغ، ولا توجد معالجة شراء أو أرصدة أو استعادة مشتريات.
4. **عدة شاشات ما زالت Scaffold صريحًا:** Onboarding وPaywall وCompliance وRecipes وSettings تعرض `Feature scaffold`، كما أن History وLegal وSupport وModels وFAQ وBrand مجرد نصوص.
5. **Real-ESRGAN ليس منفذًا:** artifact الحالي `.pth`، و`runEsrgan` يعيد `null` دائمًا؛ النتيجة الحالية fallback إلى تكبير Bitmap عادي.
6. **المسارات غير مكتملة:** الراوتر يحتوي فقط على Splash وChat وEditor وBatch؛ معظم الشاشات الموجودة في `lib/features` غير قابلة للوصول من التطبيق.
7. **التحقق الأصلي وAPK/AAB والجهاز غير مثبت:** ملفات Android الأساسية لبناء Flutter مستقل ناقصة في اللقطة المفحوصة، ولا يوجد wrapper Gradle أو جهاز/محاكي متاح للتحقق.

**الحكم:** الحالة الواقعية هي **Prototype Android قيد التطوير**، وليست Release Candidate. يمكن اعتبار بعض البنود مكتملة على مستوى الكود، لكن لا يمكن اعتبار مسار Android مكتملًا قبل استعادة بيئة Flutter، إكمال ملفات البناء، ثم إجراء build وتشغيل وظيفي على جهاز أو محاكي.

## الأدلة المباشرة

| الادعاء | الدليل في الكود أو التشغيل | التقييم |
|---|---|---|
| Model Manager فعلي | `lib/services/model_manager.dart` ينفذ download/resume، SHA-256، delete، و`readyPath` | منفذ جزئيًا؛ الاختبارات تغطي checksum/delete فقط |
| Smart Analysis فعلي | `lib/services/smart_analysis_service.dart` يفك الصورة ويحسب brightness/complexity/coverage ويعيد حتى 5 اقتراحات | منفذ، لكن الاختبار الحالي يغطي فقط مسار ملف غير موجود |
| LaMa ONNX متكامل مبدئيًا | `SeikaChannel.kt` ينشئ ONNX session، يبني tensors، يشغل `session.run` ويحفظ الناتج | منفذ مبدئيًا؛ غير متحقق ببناء/جهاز فعلي |
| Real-ESRGAN فعلي | `runEsrgan` في `SeikaChannel.kt` يحتوي تعليقًا بأن `.pth` غير مناسب ثم `return null` | غير منفذ؛ fallback Bitmap فقط |
| عمليات المحرر فعالة | `EditorController._apply` يستدعي `AiService.apply` | غير فعالة حاليًا؛ `AiService.apply` يعيد `imagePath` كما هو |
| Batch منفذ | `BatchService.processAll` يتحقق من وجود المصدر وينسخه إلى temp ويحدث التقدم | تنفيذ Batch أساسي، وليس pipeline تحرير فعليًا |
| التخزين دائم | `StorageService` يستخدم `Map<String,Object?> _memory` فقط | غير منفذ |
| الدفع | `BillingService { Future<void> init() async {} }` | غير منفذ |
| الشاشات مكتملة | عدة ملفات تحتوي نص `Feature scaffold` | غير منفذ |
| كل الشاشات قابلة للوصول | `lib/core/router.dart` يحتوي 4 مسارات فقط | غير صحيح |
| التحليل والاختبارات ناجحة حاليًا | محاولة التشغيل أعادت `bash: flutter: command not found` | غير قابل للتحقق في الجلسة الحالية |

## مطابقة بنود خارطة الطريق

| البند | الحالة المثبتة | ما الذي تم فعليًا | ما الذي ما زال مطلوبًا |
|---|---|---|---|
| 1. بيئة البناء | **غير متحقق حاليًا** | الوثيقة `BUILD_AND_REPOSITORY_AUDIT.md` تسجل نجاحًا سابقًا | تثبيت/إتاحة Flutter فعليًا في PATH ثم إعادة `flutter pub get`, `gen-l10n`, `analyze`, `test` |
| 2. تدقيق المستودع والاعتماديات | **جزئيًا مكتمل** | `pubspec.yaml` يحتوي إصلاح `intl`، والاعتماديات المسجلة | إعادة التدقيق بعد التغييرات؛ فصل stub `ModelManager` الموجود داخل `ai_service.dart` عن manager الحقيقي |
| 3. النماذج والتراخيص | **جزئيًا مكتمل** | رابط LaMa وReal-ESRGAN الحقيقيان في `core/constants.dart`؛ MI-GAN فارغ عمدًا | حسم ترخيص MI-GAN؛ توفير artifact ONNX لـ Real-ESRGAN أو إبقاء الميزة معلنة كـ fallback فقط |
| 4. Model Manager | **منفذ جزئيًا** | تنزيل، استئناف، checksum، حذف، offline readiness | اختبار Dio فعليًا للـ range/server-ignore/error، وربط شاشة Models ومسار تنزيل UI |
| 5. Seika/ONNX | **منفذ جزئيًا** | Android MethodChannel وLaMa inference وNNAPI محاولة وCPU fallback منطقي | بناء وتشغيل؛ memory limits وتصغير الصور؛ التحقق من tensor contract؛ Real-ESRGAN؛ lifecycle وإلغاء العمل |
| 6. واجهات Android | **منفذ جزئيًا** | Editor controller، undo/redo، before/layers، Batch UI الأساسي | إزالة Scaffolds؛ ربط Chat بالعمليات؛ Export حقيقي؛ backgrounds/shadows/lighting؛ History/Brand؛ إضافة المسارات |
| 7. التخزين والخصوصية | **غير منفذ** | يوجد class شكلي فقط | Hive/SharedPreferences أو تخزين واضح دائم؛ history/settings/credits؛ temp cleanup؛ Privacy/Terms داخل التطبيق؛ اختبارات offline |
| 8. اللغات والوصول | **غير مكتمل** | ملفات `app_ar.arb` و`app_en.arb` موجودة فقط حسب شجرة الملفات | إكمال 16 لغة أو تقليص النطاق المعلن؛ RTL؛ semantics؛ أحجام لمس؛ اختبار overflow والثيمات |
| 9. Credits والدفع | **غير منفذ** | dependency `in_app_purchase` موجودة لكن لا يستخدمها `BillingService` | products، purchase stream، server/receipt strategy إن لزم، خصم بعد النجاح، restore، sandbox |
| 10. الاختبارات والأداء | **غير مكتمل** | اختباران فقط: Model Manager وinvalid Smart Analysis path | اختبارات Seika/Batch/Editor/Billing/Storage؛ fixtures صور وأقنعة؛ performance وmemory؛ network interruption |
| 11. إعداد Android للإصدار | **غير متحقق** | `applicationId`, SDK 35، ProGuard وManifest أساسي موجودة | إكمال Flutter Android project files؛ icons/splash؛ FileProvider/permissions؛ signing خارج Git؛ Play requirements؛ release/AAB |
| 12. iOS | **مؤجل حسب القرار** | القرار موثق في الخارطة | لا يلزم للإصدار Android الحالي، مع إبقاء عدم الادعاء بدعم iOS |
| 13. Web | **مؤجل حسب القرار** | القرار موثق في الخارطة | لا يلزم للإصدار Android الحالي |
| 14. التوثيق وCI/CD | **جزئيًا مكتمل** | خارطة الطريق وتقرير التدقيق وfeature matrix موجودة | GitHub Actions للتحليل/الاختبار/build؛ تحديث docs لتتوافق مع الحالة الحالية؛ فحص الأسرار والـ keystore |

## تناقضات وثائقية يجب تصحيحها

1. `docs/BUILD_AND_REPOSITORY_AUDIT.md` يقول إن Model URLs تحتوي `YOUR_ORG` وأن مستودع Hugging Face لم يُنشأ، لكن `ROADMAP.md` و`lib/core/constants.dart` يحتويان روابط Hugging Face فعلية. هذه الفقرة تبدو قديمة ويجب تحديثها.
2. `docs/BUILD_AND_REPOSITORY_AUDIT.md` يذكر “working Android CPU baseline but not verified MI-GAN/LaMa/Real-ESRGAN ONNX sessions”، بينما الكود الحالي أضاف LaMa ONNX فعليًا. يجب التفريق بين **وجود implementation** و**نجاح runtime verification**.
3. خارطة الطريق تعلّم Editor وBatch كـ “إكمال v4”، لكن Editor يعتمد على `AiService` stub، وBatch ينسخ الملفات بدل تطبيق عمليات تحرير. الأنسب تسميتهما **UI/state skeleton + basic file batch** حتى اكتمال pipeline.
4. `docs/FEATURE_TEST_MATRIX.md` يصف حالات متوقعة، لكنه لا يحتوي نتائج تنفيذ لكل حالة. يجب تحويله إلى matrix فيها `implemented / tested / device-tested / blocked` مع evidence.
5. خارطة الطريق تسجل `flutter analyze` و`flutter test` كنجاح حالي، بينما لم يمكن تنفيذ الأمر في جلسة التدقيق. يجب إضافة تاريخ وبيئة وcommit لكل نتيجة، وعدم نقل نتيجة قديمة إلى الحالة الحالية دون إعادة تشغيل.

## ترتيب العمل المقترح قبل أي ادعاء بالإصدار

### P0 — قابلية البناء والتحقق

1. استعادة Flutter 3.47.4 أو تثبيت نسخة متوافقة، وإضافة توثيق مصدرها إلى `README` أو script تحقق.
2. التأكد من اكتمال مشروع Android Flutter: `settings.gradle`/root Gradle configuration، ملفات Flutter-generated المطلوبة، وGradle wrapper أو طريقة build موثقة.
3. تشغيل وتسجيل: `flutter pub get`, `flutter gen-l10n`, `flutter analyze`, `flutter test`, `flutter build apk --debug`.
4. توفير محاكي أو جهاز Android وتشغيل smoke flow: Splash → Chat → اختيار صورة → Editor → operation → export.

### P1 — إزالة التنفيذ الوهمي من المسار الأساسي

1. استبدال `AiService` بواجهة واحدة تستخدم `SeikaService` وتمرر model paths والـ masks الصحيحة، أو إزالة طبقة `AiService` المضللة.
2. تنفيذ أو تعطيل UI بوضوح لعمليات غير مدعومة بدل إظهارها كأنها تعمل.
3. تنفيذ التخزين الدائم وربط history/settings/credits به.
4. استكمال الراوتر والشاشات الأساسية: onboarding، settings، models، history، paywall، compliance، recipes.

### P2 — نماذج وسياسات الإصدار

1. اختبار LaMa على صور وأقنعة صغيرة ومعالجة الأبعاد والذاكرة والفشل.
2. توفير Real-ESRGAN ONNX/NCNN متوافق، أو تغيير المنتج ليعلن صراحة أن upscale الحالي fallback وليس Real-ESRGAN.
3. إضافة cleanup للملفات المؤقتة وقيود الحجم والذاكرة.
4. مراجعة الأذونات وFileProvider وicons/splash وrelease signing وPlay requirements.

### P3 — الدفع والاختبارات

1. ربط `in_app_purchase` فعليًا مع products وpurchase updates وrestore وcredit deduction بعد نجاح الشراء فقط.
2. إضافة اختبارات unit/widget/integration لكل مسار حساس.
3. إضافة CI للتحليل والاختبار والبناء، وإضافة نتائج الأجهزة والأداء إلى المصفوفة.

## معيار القبول المقترح للإصدار Android الأول

لا يُعلن الإصدار جاهزًا إلا عند تحقق جميع الشروط التالية:

- ينجح `flutter analyze` و`flutter test` من clean checkout.
- ينجح Debug APK وRelease APK أو AAB من نفس الالتزام.
- يعمل المسار الأساسي على جهاز/محاكي Android دون MissingPlugin أو crash.
- عملية إزالة الخلفية/الإدخال بالقناع تستخدم LaMa فعلًا وتنتج ملفًا صالحًا.
- كل زر ظاهر إما ينفذ وظيفة حقيقية أو معلّم بوضوح كغير متاح؛ لا تبقى Scaffolds في المسار المعلن.
- التخزين، credits، offline behavior، وprivacy policy مختبرة ومتصلة بالواجهة.
- الدفع إما منفذ ومختبر في Sandbox، أو لا توجد واجهة Paywall توحي بوجود شراء.
- تكون خارطة الطريق والمصفوفة وBUILD audit محدثة بنفس commit ونتائج قابلة لإعادة الإنتاج.

## حدود هذا التدقيق

لم أعدّل كود التطبيق أو خارطة الطريق، ولم أزعم نجاح build أو runtime. سبب عدم تنفيذ Flutter verification هو أن أمر `flutter` غير موجود في بيئة الجلسة الحالية، رغم ذكر بيئة Flutter في الوثائق. كما لم يُنفذ اختبار جهاز Android لعدم توفر جهاز أو محاكي مثبت في الأدلة المفحوصة.

## الملفات المفحوصة الأساسية

- `ROADMAP.md`
- `docs/BUILD_AND_REPOSITORY_AUDIT.md`
- `docs/FEATURE_TEST_MATRIX.md`
- `lib/core/router.dart`
- `lib/core/constants.dart`
- `lib/services/model_manager.dart`
- `lib/services/seika_service.dart`
- `lib/services/smart_analysis_service.dart`
- `lib/services/ai_service.dart`
- `lib/services/storage_service.dart`
- `lib/services/billing_service.dart`
- `lib/services/batch_service.dart`
- `lib/features/editor/editor_controller.dart`
- `android/app/src/main/kotlin/com/productchat/studio/native/SeikaChannel.kt`
- `test/model_manager_test.dart`
- `test/smart_analysis_service_test.dart`

**آخر تحديث للتقرير:** 2026-09-13.
