# تقرير فحص خارطة الطريق وحالة التنفيذ

**المشروع:** ProductChat Studio
**المستودع:** `toufikben/productchat_studio`
**الفرع:** `main`
**الالتزام المفحوص:** `bcc84550801eba194f2f066d2bbe1cd73905b416`
**تاريخ الفحص:** 2026-09-14
**نطاق الفحص:** جميع ملفات Markdown في المستودع، خارطة الطريق، سجلات التحقق، سجل Git، ومصفوفات الميزات والدفع والأداء.

## 1. النتيجة التنفيذية

المشروع أصبح **أساس Android/Flutter قابلًا للبناء مع تنفيذات مصدرية حقيقية**، لكنه لم يصل بعد إلى **Release Candidate أو Production Ready**. أهم ما تحقق هو استعادة بيئة Flutter/Android، ربط مسار LaMa ONNX في Android، إزالة خداع `AiService` القديم، إضافة اختبارات عقود، بناء AAB موقع، تفعيل منتجات Google Play، وتحسين إدارة الإلغاء والمهلة والموارد.

العائق الرئيسي الآن ليس وجود الكود، بل **إثباته على Android فعليًا**. لا يوجد في الأدلة الحالية تشغيل على جهاز أو Emulator يثبت MethodChannel أو تحميل ONNX أو inference أو الإلغاء أو الأداء أو استقرار الذاكرة. كما أن الدفع ما زال **معالجة محلية لأحداث الشراء** وليس Receipt Verification خادميًا موثوقًا، ولا توجد بعد حالة `ProEntitlement` أو بوابات Pro فعلية.

### الحكم الحالي

| المحور | الحكم الحالي |
|---|---|
| البناء والتحليل والاختبارات | متحقق على مستوى المصدر/CI؛ آخر الأدلة تشير إلى نجاح `flutter analyze` و`flutter test` وبناء APK/AAB |
| Android runtime | غير متحقق؛ لا يوجد جهاز أو Emulator مسجل في الأدلة |
| LaMa ONNX | implementation موجود وعقد النموذج موثق؛ inference الميداني غير مثبت |
| Real-ESRGAN | غير منفذ؛ الموجود `.pth`، والتطبيق يستخدم Basic Bitmap fallback |
| المحرر | state/UI وoperation contracts موجودة؛ النتيجة الفعلية تتطلب Android runtime والتحقق من التدفق الكامل |
| Batch | موجود كأساس لمعالجة/نسخ الملفات؛ لا يطبق pipeline تحرير حقيقيًا بعد |
| التخزين | تحسن إلى SharedPreferences وفق handoff، لكن بعض الوثائق القديمة ما زالت تصفه كـ `Map` داخل الذاكرة؛ يجب توحيد الوثائق |
| الدفع | المنتجات والكود المحلي مفعّلان؛ Sandbox وbackend receipt verification وPro entitlement متبقية |
| الإصدار | AAB `1.0.2+3` مبني وموقع؛ الرفع إلى Internal Testing وقبول Upload Key واختبار الجهاز متبقية |
| iOS/Web | مؤجلان عمدًا بعد إصدار Android |

## 2. الملفات التي تمت قراءتها

تمت قراءة **25 ملف Markdown**:

- `ROADMAP.md`
- `AI_HANDOFF.md`
- `README.md`
- `docs/BUILD_AND_REPOSITORY_AUDIT.md`
- `docs/FEATURE_TEST_MATRIX.md`
- `docs/FEATURE_VERIFICATION_MATRIX.md`
- `docs/INFERENCE_CANCELLATION_TIMEOUT.md`
- `docs/INTEGRATION_TEST_PLAN_FLUTTER_KOTLIN_ONNX.md`
- `docs/KOTLIN_ONNX_MEMORY_LEAK_AUDIT.md`
- `docs/MODEL_INVENTORY.md`
- `docs/P0_PERFORMANCE_IMPLEMENTATION.md`
- `docs/P1_BUILD_VALIDATION.md`
- `docs/P2_CORE_AI_VALIDATION.md`
- `docs/P2_PERFORMANCE_REVIEW.md`
- `docs/P6_MODEL_DECISION.md`
- `docs/P7_BILLING_VALIDATION.md`
- `docs/P8_PERFORMANCE_BENCHMARK.md`
- `docs/RELEASE_SIGNING.md`
- `docs/ROADMAP_VERIFICATION_2026-09-13.md`
- `docs/ROADMAP_VERIFICATION_PLAN.md`
- `docs/SEIKA_ANDROID.md`
- `docs/SPRINT4_RECEIPT_SUBSCRIPTION_AUDIT.md`
- `docs/SPRINT5_RECEIPT_VERIFICATION_EXECUTION_PLAN.md`
- `docs/VALIDATION.md`
- `lib/services/onnx_edge_cases.md`

## 3. ما تم إنجازه فعليًا

### 3.1 البناء والبيئة

- تثبيت وتوثيق Flutter `3.47.4` وDart `3.13.3`.
- تجهيز Android SDK وCompile SDK 36 وJDK 17.
- استعادة ملفات مشروع Android المولدة وربطها بالجسر المخصص.
- نجاح `flutter pub get` و`flutter gen-l10n` و`flutter analyze` و`flutter test` وفق سجلات التحقق.
- بناء Debug APK وبناء Release AAB موقع عبر GitHub Actions.
- توحيد هوية الحزمة إلى `com.productchat.aiphotostudio`.
- إضافة توقيع Release عبر `android/key.properties` دون وضع الأسرار أو keystore في Git.
- إضافة INTERNET إلى Manifest الأساسي.
- معالجة مشاكل Java وR8 ورفع `targetSdk` إلى 36.

**الدليل المهم:** workflow `34807820712` نجح في التحليل والاختبارات وبناء AAB الموقع ورفع artifact؛ سُجل حجم يقارب 76 MB للـAAB في أحدث الوثائق.

### 3.2 النماذج ومصدر الحقيقة

- إنشاء مستودع النماذج العام `Toufikben/productchat-models`.
- توفير `lama_fp32.onnx` مع SHA-256:
  `1faef5301d78db7dda502fe59966957ec4b79dd64e16f03ed96913c7a4eb68d6`.
- توفير `RealESRGAN_x4plus.pth` مع SHA-256:
  `4fa0d38905f75ac06eb49a7951b426670021be3018265fd191d2125df9d682f1`.
- توثيق عقد LaMa:
  - image: `[1, 3, 512, 512]`
  - mask: `[1, 1, 512, 512]`
  - قيمة mask = `1` للحذف و`0` للإبقاء
  - output RGB بقيم `[0,255]`
- إبقاء MI-GAN خارج التوزيع بسبب عدم حسم ترخيص إعادة التوزيع التجاري.
- توثيق أن `.pth` لا يعمل مباشرة مع `onnxruntime-android`.

### 3.3 Seika وONNX وإدارة الموارد

- إنشاء/ربط `SeikaService` وMethodChannel `productchat/studio/seika`.
- إضافة مسار Android لـ LaMa ONNX وإنشاء tensors وتشغيل `session.run`.
- إضافة CPU fallback ومحاولة NNAPI.
- إضافة cancellation عبر `RunOptions.setTerminate(true)` أثناء inference.
- إضافة native hard timeout افتراضيه 180 ثانية.
- نقل عمليات native إلى single-thread executor لمنع حجب واجهة Flutter.
- إضافة sampled decode وحدود للأبعاد والـoutput.
- إغلاق `OrtSession.Result` و`OnnxTensor` و`RunOptions` و`SessionOptions` في مسارات `finally`.
- إضافة cleanup للـBitmaps والـFileOutputStream ودورة حياة Activity.
- إضافة verification cache لتجنب إعادة SHA-256 الكامل في كل عملية عندما لا تتغير metadata.

**مهم:** هذه التحسينات مثبتة بالقراءة الساكنة وبناء التطبيق، وليست شهادة runtime خالية من التسرب أو ناجحة الأداء.

### 3.4 المحرر والتحليل والعمليات

- إزالة سلوك `AiService.apply` القديم الذي كان يعيد مسار الإدخال كنجاح وهمي.
- ربط العمليات بمسارات `SeikaService` وإرجاع `EditResult` صريح عند النجاح أو الفشل.
- منع إدخال نتيجة فاشلة إلى history.
- إضافة image picker فعلي إلى المحرر.
- إضافة editor state وUndo/Redo وBefore/After وLayers وExportDialog.
- إضافة Smart Analysis لتحليل الصورة واقتراح حتى خمس عمليات.
- إضافة Batch state/progress الأساسي.
- إضافة اختبارات contract لـ AI/Seika/Model Manager.

### 3.5 التخزين والخصوصية واللغات

- إضافة SharedPreferences للحالة المحلية وفق `AI_HANDOFF.md`، مع حفظ locale/theme وبعض بيانات الدفع.
- إضافة مسار Privacy/Terms داخل التطبيق وفق سجل handoff.
- ربط العربية والإنجليزية وRTL wiring أساسي وlocalization delegates وSemantics أساسية.

### 3.6 الدفع وGoogle Play

- ربط `in_app_purchase` وpurchase stream.
- تفعيل المنتجات التالية في Play Console:
  - `credits_100`
  - `credits_500`
  - `credits_1200`
  - `pro_monthly`
  - `pro_yearly`
- فصل consumable Credits عن subscriptions.
- منح Credits فقط لمنتجات Credits المعروفة وبعد purchase ناجح وpurchase ID غير فارغ.
- منع duplicate grant محليًا عبر ledger idempotent.
- عدم منح Credits من `pro_monthly` أو `pro_yearly` تلقائيًا.
- إضافة Paywall واستعادة المشتريات وواجهات loading/error diagnostics.
- رفض restored consumables في المسار المحلي بعد Sprint 4 hardening.
- عدم إضافة AdMob حاليًا بقرار منتج موثق.

## 4. ما تبقى قبل مواصلة العمل

### أولوية P0 — إثبات Android runtime

هذه هي الخطوة الأهم قبل اعتبار LaMa أو Android جاهزين:

1. توفير Android Emulator أو جهاز فعلي.
2. تثبيت AAB/ APK وتشغيل المسار الأساسي: Splash → Chat → اختيار صورة → Editor.
3. تنزيل LaMa عبر Model Manager والتحقق من SHA-256.
4. تشغيل cold inference ثم warm inference بصورة وقناع ثابتين.
5. التحقق من output path، صلاحية الصورة، الأبعاد، واتجاه mask.
6. اختبار portrait/landscape والصور الكبيرة والصور التالفة والأبعاد غير المتطابقة.
7. اختبار cancellation داخل `session.run` وhard timeout ثم تشغيل inference جديد بعد الإلغاء.
8. تنفيذ 30–100 inference متتابعة مع Java/native heap profiling.
9. قياس CPU مقابل NNAPI وmedian/p95 للزمن.
10. اختبار unload/reload وbackground/foreground وActivity destroy/reopen.
11. تسجيل الجهاز، نسخة Android، ABI، RAM، app version، model checksum، provider، والنتائج في مصفوفة التحقق.

### أولوية P1 — إكمال المنتج الأساسي

- إكمال إنشاء القناع وربط image picker بالـChat والـEditor.
- جعل Chat يرسل العملية ويعرض النتيجة الحقيقية.
- تحويل Batch من نسخ ملفات إلى pipeline تحرير/export حقيقي.
- ربط History وSettings وBrand Identity بتخزين دائم قابل لإعادة الفتح.
- إزالة `Feature scaffold` والواجهات النصية من المسارات الظاهرة، أو إخفاؤها حتى اكتمالها.
- إضافة routes المطلوبة فقط بعد أن تصبح الشاشات قابلة للاستخدام.
- إكمال export وbackgrounds وshadows وlighting وفق النطاق المطلوب.
- إضافة cleanup/retention policy للصور الناتجة في `cacheDir`.

### أولوية P1 — توحيد التوثيق

توجد تناقضات يجب إصلاحها قبل الاعتماد على الوثائق كمصدر حالة:

- `BUILD_AND_REPOSITORY_AUDIT.md` وبعض الوثائق الأقدم ما زالت تشير إلى `AiService` أو `StorageService` كـstubs، بينما `AI_HANDOFF.md` و`ROADMAP.md` يسجلان إصلاحات لاحقة.
- `FEATURE_TEST_MATRIX.md` قديم ويصف scaffolds واختبارات معلقة، ولا يعكس المصفوفة الأحدث بالكامل.
- بعض السجلات تشير إلى Android target SDK 35، بينما خارطة الطريق والتغييرات الحديثة تشير إلى target/compile API 36؛ يجب تثبيت القيمة الفعلية في وثيقة واحدة.
- `P0_PERFORMANCE_IMPLEMENTATION.md` يصف cancellation وtimeout كمتبقية، بينما `INFERENCE_CANCELLATION_TIMEOUT.md` يوثق تنفيذها لاحقًا. يجب إبقاء P0 كـhistorical record أو إضافة حالة superseded.
- `ROADMAP.md` يعلن بعض البنود “مكتملة” على مستوى التنفيذ، لكن الأدق إضافة فصل صريح بين source-complete وruntime-verified.
- يجب تحديث كل الوثائق إلى آخر commit والأدلة الفعلية، وعدم نقل نتائج قديمة على أنها تحقق حالي.

### أولوية P1 — الدفع الموثوق

الدفع لا يُعد Production Ready قبل:

1. تحديد هوية مستخدم مصادق عليها.
2. إنشاء backend HTTPS للتحقق من Purchase Token.
3. استخدام Google Play Developer API للـconsumables والاشتراكات.
4. إنشاء ledger خادمي بمعاملة ذرية وunique token constraint.
5. نقل Credits إلى حالة `pendingVerification` وعدم منحها نهائيًا من callback المحلي فقط.
6. إنشاء `ProEntitlement` يتضمن `active` و`state` و`expiresAt` و`lastSyncedAt`.
7. ربط ميزات Pro بالـentitlement الخادمي.
8. إضافة RTDN وdeduplication وretry/dead-letter.
9. إضافة اختبارات pending/error/purchased/restored والشراء المتكرر والـrefund/expiry/revocation.
10. تنفيذ Internal Testing بحساب Play مرخص وجهاز فعلي.

### أولوية P2 — قرار Real-ESRGAN

يوجد قرار صحيح حاليًا: عدم تسمية Bitmap scaling باسم Real-ESRGAN. يجب اختيار أحد المسارات:

- توفير ONNX export صالح ومختبر على Android.
- استخدام NCNN/TFLite أو backend Android مناسب بترخيص واضح.
- الإبقاء على “Basic enhancement fallback” وإزالة أي ادعاء بأن Real-ESRGAN يعمل runtime.

MI-GAN يبقى مؤجلًا قانونيًا ولا ينبغي إضافة أوزانه قبل تصريح مكتوب.

### أولوية P2 — الاختبارات والجاهزية

- إضافة `integration_test/` فعليًا؛ الخطة موجودة لكن المجلد غير موجود.
- إضافة fixtures للصور والأقنعة دون تخزين نموذج 208 MB داخل Git.
- إضافة MethodChannel mock tests كاملة لكل العمليات والأخطاء.
- إضافة widget tests للراوتر والشاشات وحالات loading/error/empty.
- إضافة CI دائم للتحليل والاختبار والبناء وفحص الأسرار.
- توسيع اللغات أو تقليص الهدف المعلن من 16 لغة؛ الحالة الحالية العربية/الإنجليزية فقط.
- اختبار RTL للعربية والفارسية والأردية، والنصوص الطويلة والثيمات وأحجام اللمس.
- مراجعة FileProvider وpermissions وicons وsplash وData Safety وprivacy declarations.

## 5. ترتيب العمل المقترح الآن

| الترتيب | المهمة | سبب الأولوية | معيار الإنجاز |
|---:|---|---|---|
| 1 | توفير Emulator/جهاز Android | كل بوابات runtime والدفع محجوبة بدونه | الجهاز ظاهر في `adb devices` و`flutter devices` |
| 2 | تشغيل Smoke + LaMa fixture | يثبت أن implementation تعمل خارج المصدر | output صالح ومسجل مع الجهاز والcommit |
| 3 | تنفيذ benchmark والإلغاء والذاكرة | يثبت الاستقرار والأداء | median/p95 وheap/native evidence و30–100 runs |
| 4 | إكمال image mask وChat/Editor E2E | يحول native capability إلى feature منتج | العملية تنتج output أو failure واضحًا |
| 5 | رفع AAB إلى Internal Testing | يثبت قابلية التثبيت وPlay acceptance | Upload Key مقبول والنسخة مثبتة |
| 6 | تنفيذ شراء Sandbox | يثبت callbacks والمنتجات الفعلية | سجل شراء/restore/pending/error موثق |
| 7 | بناء Receipt Verification وPro Entitlement | شرط الإنتاج المالي | backend tests وserver-authoritative state |
| 8 | توحيد الوثائق والمصفوفات | منع تضارب الحالة | كل claim مرتبط بـcommand/commit/device evidence |
| 9 | مراجعة الإصدار النهائي | منع نشر ميزات وهمية أو غير موثقة | لا scaffolds في المسار المعلن ولا claims غير مثبتة |

## 6. الخلاصة العملية

يمكن مواصلة العمل من الوضع الحالي دون إعادة بناء الأساس. نقطة الانطلاق الصحيحة هي **Android runtime validation**، وليست إضافة شاشات جديدة أو نماذج إضافية. الكود الحالي يملك أساسًا مناسبًا لاختبار LaMa، لكن لا ينبغي رفع حالة `models.lama` أو `edit.inpaint` إلى Android verified قبل نجاح اختبارات D-01/D-02، cancellation أو timeout، دورة unload/load، اختبار ذاكرة أساسي، والتحقق من output fixture.

وبالتوازي، يجب اعتبار الدفع الحالي **Billing foundation / local purchase handler** فقط. لا ينبغي تسويق Pro أو اعتبار Credits آمنة للإطلاق العام حتى يكتمل backend receipt verification والـledger الخادمي و`ProEntitlement`.

**الوضع النهائي في هذا الفحص:** المشروع قابل للبناء ومهيأ للانتقال إلى اختبار Android ميداني، لكنه ليس جاهزًا للإصدار العام بعد.


## 7. تدقيق صياغة Credits والمشتريات الشهرية/السنوية

### الصياغة المعتمدة في خارطة الطريق

النموذج التجاري المكتوب في الوثائق يتكون من مسارين منفصلين:

| النوع | Product ID | طبيعة الشراء | القيمة المعلنة | طريقة المعالجة |
|---|---|---|---:|---|
| حزمة Credits ابتدائية | `credits_100` | شراء مرة واحدة، consumable | 100 Credits مقابل 0.99 USD | `buyConsumable` ثم إضافة الرصيد بعد purchase ناجح |
| حزمة Credits قياسية | `credits_500` | شراء مرة واحدة، consumable | 500 Credits مقابل 3.99 USD | `buyConsumable` ثم إضافة الرصيد بعد purchase ناجح |
| حزمة Credits كبيرة | `credits_1200` | شراء مرة واحدة، consumable | 1200 Credits مقابل 7.99 USD | `buyConsumable` ثم إضافة الرصيد بعد purchase ناجح |
| Pro شهري | `pro_monthly` | اشتراك auto-renewing شهري | 4.99 USD/month | `buyNonConsumable` كحدث entitlement؛ لا يمنح Credits حاليًا |
| Pro سنوي | `pro_yearly` | اشتراك auto-renewing سنوي | 29.99 USD/year وفق Billing v2 | `buyNonConsumable` كحدث entitlement؛ لا يمنح Credits حاليًا |

بالتالي فإن عبارة **الشراء الكلي/لمرة واحدة** تنطبق على حزم Credits فقط، وليس على Pro. أما Pro فليس شراءً دائمًا أو lifetime؛ هو اشتراك دوري شهري أو سنوي يتطلب entitlement نشطًا وتجديدًا/انتهاءً/إلغاءً موثقًا.

### ما تؤكده صياغة الكود

في `lib/services/billing_service.dart`، الكود يفصل صراحة بين `consumableIds` و`subscriptionIds`. الدالة `creditsFor()` تعيد قيمة فقط للمنتجات الثلاثة `credits_100` و`credits_500` و`credits_1200`، بينما `pro_monthly` و`pro_yearly` لا يملكان أي mapping إلى Credits. كما أن `shouldGrantCredits()` يرفض أي Subscription ID، ولا يمنح الرصيد إلا عند `PurchaseStatus.purchased` مع Purchase ID غير فارغ.

ويستخدم الكود `buyConsumable` لحزم Credits و`buyNonConsumable` للاشتراكات. هذه تسمية API في حزمة Flutter وليست دليلًا على أن الاشتراك شراء دائم؛ الوثائق نفسها تصفه كاشتراك auto-renewing، ولذلك يجب أن تعتمد الملكية النهائية على التحقق من حالة الاشتراك وليس على مجرد استدعاء `completePurchase`.

### الصياغة الظاهرة في Paywall

تظهر شاشة الشراء حاليًا النصوص التالية بالإنجليزية:

- العنوان: `Credits`
- الرصيد: `Available credits`
- الاشتراك: `<product.title> — Pro subscription`
- وصف الاشتراك: `Subscription entitlement; Pro access is verified separately`
- وصف حزم Credits: `<amount> credits`
- التنبيه: `Credits are added only after a purchased transaction with a valid transaction ID. Pending and failed purchases never add credits.`
- زر الاستعادة: `Restore purchases`

هذه الصياغة متوافقة مع القرار الحالي؛ فهي لا تدعي أن الاشتراك يمنح Credits، وتذكر أن Pro access يحتاج تحققًا منفصلًا. لكن النص لا يوضح للمستخدم أن Pro **شهري أو سنوي**، ولا يوضح أن حزم Credits **شراء مرة واحدة**، كما لا يعرض سياسة أو مزايا Pro لأن هذه المزايا لم تُحسم بعد.

### تكلفة عمليات التحرير الحالية

الكود يعرّف تكلفة العمليات كما يلي:

| العملية | التكلفة الحالية |
|---|---:|
| إزالة الخلفية | 1 Credit |
| إضافة ظل | 1 Credit |
| التحسين/التكبير | 2 Credits |
| Inpaint أو conversational edit | 3 Credits |
| Export | 0 Credits |

يتم فحص الرصيد قبل العملية، ثم خصمه بعد وصول نتيجة native ناجحة. العملية الفاشلة لا تخصم Credits. هذه القيم موجودة في المصدر، لكنها تحتاج توثيقًا في نص المنتج أو إعداد مركزي واحد حتى لا تختلف الواجهة عن التنفيذ مستقبلًا.

### ملاحظات صياغية وتسموية

1. اسم الثابت `CreditProducts.pro = 'credits_1200'` قد يسبب التباسًا لأنه يستخدم كلمة `pro` لحزمة Credits، في حين أن `pro_monthly` و`pro_yearly` هما اشتراكا Pro. الأفضل إعادة تسميته إلى `large` أو `maxPack`.
2. `pro_monthly` و`pro_yearly` لا يفتحان أي ميزة Pro حاليًا؛ الوثائق صحيحة في اعتبارهما entitlement events فقط، لكن ظهور زر الشراء قد يوحي للمستخدم بأن المزايا ستفتح فورًا.
3. لا توجد حاليًا سياسة Credits دورية للاشتراك: لا توجد كمية شهرية أو سنوية، ولا rollover، ولا expiration، ولا تعريف لمزايا Pro. يجب عدم إضافة هذه الوعود إلى Paywall قبل اعتمادها وتنفيذها.
4. مصطلح `restore purchases` لا يعني استعادة حزم Credits المستهلكة على Google Play. يمكن أن يخدم الاشتراكات أو المنتجات غير المستهلكة، لكن الاستعادة العابرة للأجهزة لحزم Credits تحتاج backend ledger موثوقًا.
5. الأسعار المحلية المذكورة في P7 هي تقريبًا 100 و550 و1,100 دينار جزائري لحزم Credits، و675 دينارًا شهريًا و6,800 دينار سنويًا لـPro. هذه أسعار إقليمية تقريبية من Play Console وليست بديلًا عن السعر الديناميكي الذي يعرضه `ProductDetails.price` داخل التطبيق.

### الصياغة المقترحة للمستخدم لاحقًا

ينبغي أن يوضح Paywall، بعد حسم مزايا Pro، الفرق بهذه الصورة:

> **حزم Credits — شراء مرة واحدة:** استخدم Credits لتنفيذ عمليات تحرير الصور. الرصيد المشتراة لا يُعاد من خلال `restore purchases` بعد استهلاكه، والاستعادة العابرة للأجهزة تتطلب حسابًا ومزامنة خادمية.
>
> **Pro شهري / Pro سنوي — اشتراك متجدد تلقائيًا:** يفتح مزايا Pro طوال فترة الاشتراك النشط. لا يمنح Credits تلقائيًا إلا إذا اعتمدت سياسة منفصلة لذلك. يتوقف الوصول عند انتهاء الاشتراك أو إلغائه وفق حالة Google Play التي يتحقق منها الخادم.

حتى تنفيذ `ProEntitlement` وReceipt Verification، يجب إبقاء النص الحالي محافظًا، وعدم وصف Pro بأنه شراء كلي أو ضمان Credits شهرية.
