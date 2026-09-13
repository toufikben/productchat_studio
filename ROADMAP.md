# ProductChat Studio — خارطة الطريق الحية

> **مصدر الحقيقة للتحقق:** [`docs/MODEL_INVENTORY.md`](docs/MODEL_INVENTORY.md) و[`docs/FEATURE_VERIFICATION_MATRIX.md`](docs/FEATURE_VERIFICATION_MATRIX.md). وجود بند هنا لا يعني أنه runtime-verified؛ الحالة لا تُرفع إلا بدليل قابل لإعادة الإنتاج.

> **آخر تحديث:** 2026-09-14 00:16 UTC
> **الحالة:** Android-first؛ iOS وWeb مؤجلان عمدًا إلى ما بعد إصدار Android.

## طريقة استخدام هذه الخارطة

هذه الوثيقة هي سجل العمل المركزي للمشروع. بعد كل مهمة مكتملة أو اكتشاف خطأ أو قرار تقني أو قانوني، تُحدَّث الحالة والملاحظات والاختبارات والالتزام المرتبط بها. لا تُعتبر أي ميزة مكتملة اعتمادًا على وجود واجهة فقط؛ يجب أن يكون لها تنفيذ واختبار موثق.

## الحالة المختصرة

| المجال | الحالة | الملاحظة |
|---|---|---|
| بيئة Flutter وAndroid | مكتمل للبناء المحلي | Flutter 3.47.4 وDart 3.13.3 وAndroid SDK 36 متاحة؛ `flutter analyze` و`flutter test` ناجحان |
| تدقيق المستودع | مكتمل كجرد، جزئي كتنفيذ | الجرد ومصفوفة التحقق محدثان؛ ما زالت شاشات وخدمات تحتاج تنفيذًا إنتاجيًا |
| Hugging Face | مكتمل كوجود، جزئي كتكامل | المستودع العام موجود وفيه LaMa وReal-ESRGAN؛ MI-GAN متوقف قانونيًا، وReal-ESRGAN غير موصول runtime |
| تحليل Dart | مكتمل حاليًا | `flutter analyze` بلا أخطاء بعد استعادة البيئة |
| اختبارات Dart | ناجح حاليًا | `flutter test`: 7 اختبارات ناجحة، تشمل AI operation contracts |
| Android Seika | مصدر/عقد/بناء مكتمل، runtime متبقٍ | LaMa graph والعقد والتحقق والـ cancellation والـ resource cleanup مضافة؛ يلزم جهاز/محاكي |
| Android APK/AAB | APK debug مكتمل، الجهاز/release متبقٍ | `app-debug.apk` بُني؛ لا يوجد جهاز أو محاكي في البيئة، وAAB/signing لاحقان |
| P4 وظائف المنتج الأساسية | جزئي | image picker وفتح المحرر فعليان؛ mask/chat/batch/history ما زالت متبقية |
| P5 التخزين والخصوصية | جزئي | SharedPreferences وLegal screen مضافان؛ cache retention وHistory/Settings الدائمين متبقيان |
| P6 النماذج المتقدمة | قرار مكتمل، runtime متبقٍ | Real-ESRGAN fallback موثق؛ لا يوجد ONNX/NCNN backend، وMI-GAN معطل قانونيًا |
| P10 اللغات والوصول | جزئي | العربية/الإنجليزية وRTL wiring وSemantics أساسية؛ 16 لغة واختبارات شاملة متبقية |
| الدفع | متبقٍ | Google Play Billing غير مربوط بالإنتاج أو Sandbox |
| iOS | مؤجل | لن يدخل في نطاق الإصدار الحالي |
| Web | مؤجل | لن يدخل في نطاق الإصدار الحالي |

## خارطة الطريق المرقمة

### 1. تأسيس بيئة البناء — مكتمل

- [x] تثبيت Flutter وDart.
- [x] تثبيت Android SDK وPlatform Tools وBuild Tools.
- [x] تثبيت Clang وCMake وNinja لدعم Native hooks.
- [x] قبول تراخيص Android.
- [x] تشغيل `flutter pub get` و`flutter gen-l10n`.

**التحقق:** `flutter analyze` و`flutter test` ناجحان.

### 2. تدقيق المستودع والاعتماديات — مكتمل

- [x] فحص بنية الملفات الأساسية.
- [x] إصلاح تعارض `intl` مع Flutter 3.47.4.
- [x] إزالة مولدات الكود غير المستخدمة والمتعارضة مع Dart 3.13.
- [x] تسجيل الفجوات في `docs/BUILD_AND_REPOSITORY_AUDIT.md`.
- [x] منع ملفات Flutter المؤقتة من Git.

### 3. مستودع النماذج والتراخيص — مكتمل جزئيًا

- [x] إنشاء [Toufikben/productchat-models](https://huggingface.co/Toufikben/productchat-models).
- [x] رفع `lama_fp32.onnx`.
- [x] رفع `RealESRGAN_x4plus.pth`.
- [x] رفع ملفات التراخيص وبطاقة النموذج.
- [x] تسجيل بصمات SHA-256.
- [ ] الحصول على تصريح واضح لإعادة توزيع أوزان MI-GAN التجارية — قرار قانوني خارجي.
- [ ] رفع MI-GAN بعد التحقق من الترخيص فقط — مؤجل وليس مانعًا لإصدار Android الأساسي.

### 4. ربط التطبيق بمستودع النماذج — مكتمل جزئيًا

- [x] ربط رابط LaMa الحقيقي.
- [x] ربط رابط Real-ESRGAN الحقيقي.
- [x] تعطيل رابط MI-GAN الوهمي بدل توزيعه دون ترخيص.
- [x] إضافة Model Manager فعلي للتنزيل والاستئناف والتحقق من checksum.
- [x] إضافة حذف وإعادة تنزيل النماذج.
- [x] إضافة جاهزية Offline بعد اكتمال التنزيل.

### 5. محرك Seika وONNX — مصدره مكتمل، runtime متبقٍ

- [x] إنشاء `SeikaService` في Dart.
- [x] إنشاء MethodChannel Android.
- [x] إضافة Baseline محلي للمعالجة.
- [x] دمج ONNX Runtime فعليًا داخل Android.
- [x] تشغيل LaMa ONNX بالقناع الحقيقي.
- [ ] تشغيل Real-ESRGAN أو نسخة ONNX/NCNN مناسبة لـ Android؛ الملف الحالي `.pth` وليس ONNX.
- [ ] دمج MI-GAN أو بديله بعد الحسم القانوني — اختياري للإصدار الأساسي.
- [x] تنفيذ CPU/NNAPI fallback مبدئي مع `RunOptions` للإلغاء والمهلة.
- [x] إضافة حدود الذاكرة وتصغير الصور الكبيرة وتنظيف الموارد المؤقتة.
- [x] إضافة verification cache للنموذج، cancellation، وnative hard timeout.
- [ ] تنفيذ Integration Tests على Android والتحقق من inference والذاكرة والزمن.

### 6. إكمال واجهات Android — متبقٍ

- [ ] تحويل الشاشات المتبقية من Scaffold إلى شاشات وظيفية.
- [ ] إكمال Onboarding.
- [ ] إكمال Paywall وCredits.
- [ ] إكمال Compliance وRecipes وSettings.
- [ ] إكمال Chat UI وربطه بمسار التعديل.
- [x] إكمال المحرر والطبقات وUndo/Redo وBefore/After — تنفيذ v4.
- [ ] إضافة الخلفيات والظلال والإضاءة والتصدير.
- [x] إضافة Batch الأساسي ومعالجة التقدم — تنفيذ v4.
- [ ] إكمال History وBrand Identity.

### 7. التخزين والخصوصية — متبقٍ

- [ ] ربط التخزين المحلي فعليًا بالتاريخ والإعدادات والأرصدة.
- [ ] إدارة الملفات المؤقتة والملفات المحفوظة.
- [ ] إضافة Privacy Policy وTerms داخل التطبيق.
- [ ] التأكد من عدم رفع صور المستخدمين دون موافقة.
- [ ] اختبار Offline والخصوصية.

### 8. اللغات وإمكانية الوصول — متبقٍ

- [ ] إكمال اللغات الـ16.
- [ ] اختبار RTL للعربية والفارسية والأردية.
- [ ] اختبار النصوص الطويلة والثيمات.
- [ ] إضافة Semantics وأحجام لمس مناسبة.

### 9. Credits والدفع — متبقٍ

- [ ] ربط Google Play Billing في Android.
- [ ] تعريف المنتجات والاشتراكات.
- [ ] خصم الرصيد بعد نجاح العملية فقط.
- [ ] استعادة المشتريات.
- [ ] اختبار Sandbox.
- [ ] إضافة طبقة iOS StoreKit لاحقًا.

### 10. الاختبارات والأداء — متبقٍ

- [ ] توسيع اختبارات Smart Analysis.
- [x] إضافة اختبارات contract لـ Seika/AI/Model Manager.
- [ ] إضافة اختبارات MethodChannel وIntegration Tests على Android.
- [ ] بناء APK Debug وRelease وAAB.
- [ ] اختبار جهاز Android منخفض ومتوسط وحديث.
- [ ] قياس الذاكرة والزمن وحجم التنزيل.
- [ ] اختبار انقطاع الشبكة والتنزيل المتقطع.

### 11. إعداد Android للإصدار — متبقٍ

- [ ] مراجعة Manifest والأذونات وFileProvider.
- [ ] إعداد الأيقونات وSplash واسم الحزمة.
- [ ] إنشاء Keystore خارج Git.
- [ ] إعداد signing آمن.
- [ ] فحص Google Play requirements.

### 11.1 بوابة قبول Android — متبقٍ قبل Release

- [ ] تشغيل LaMa cold/warm على emulator أو جهاز حقيقي.
- [ ] اختبار cancellation أثناء `session.run` وhard timeout.
- [ ] اختبار 30–100 inference مع heap/native profiling.
- [ ] التحقق من output image quality وportrait/landscape.
- [ ] قياس latency وpeak memory وCPU/NNAPI.
- [ ] تنظيف cache files وتحديد retention policy.

### 11.2 إكمال المنتج الأساسي — متبقٍ قبل Release

- [ ] إكمال image picker وmask creation وربطهما بالـ Chat/Editor.
- [ ] تطبيق editing pipeline الحقيقي في Batch بدل نسخ الملفات فقط.
- [ ] ربط History وSettings وBrand Identity بتخزين دائم.
- [ ] إكمال Privacy Policy وTerms وCompliance flow.
- [ ] تحديد استراتيجية Real-ESRGAN: ONNX/NCNN أو إعلان fallback بوضوح.
- [ ] تنفيذ Credits وGoogle Play Billing واختبار Sandbox.

### 12. iOS — مؤجل

- [ ] إنشاء Seika bridge لـ iOS.
- [ ] اختبار Core ML/ONNX Runtime.
- [ ] إعداد Camera وPhoto Library permissions.
- [ ] ربط StoreKit.
- [ ] إعداد signing وBundle Identifier.
- [ ] بناء IPA واختباره على جهاز حقيقي.

### 13. Web — مؤجل

- [ ] بناء Web.
- [ ] تحديد عمليات ONNX Runtime Web الممكنة.
- [ ] توفير fallback للميزات Native.
- [ ] اختبار الرفع والتصدير والنشر.

### 14. التوثيق وCI/CD — قيد التوسع

- [x] توثيق تدقيق البناء والمستودع.
- [x] توثيق نماذج Hugging Face وتراخيصها.
- [ ] إضافة تقارير الأداء والأجهزة.
- [ ] إضافة GitHub Actions للتحليل والاختبار والبناء.
- [ ] منع الأسرار وKeystore والنماذج غير المقصودة من Git.

## الاقتراحات والمخاطر الحالية

1. **الأولوية التقنية:** دمج LaMa ONNX أولًا لأنه متاح بترخيص واضح وبعقد إدخال/إخراج موثق.
2. **الأولوية القانونية:** لا تُرفع أوزان MI-GAN قبل الحصول على تصريح كتابي أو بطاقة نموذج واضحة تسمح بإعادة التوزيع التجاري.
3. **خطر Android:** لا يوجد حاليًا تحقق على جهاز Android حقيقي؛ نجاح تحليل Dart لا يثبت نجاح APK أو أداء ONNX على الهاتف.
4. **خطر المنتج:** وجود شاشات Scaffold وخدمات Stub يعني أن التطبيق ليس إصدارًا إنتاجيًا بعد، حتى لو كان البناء الأساسي ناجحًا.
5. **اقتراح الاختبارات:** إنشاء اختبارات لكل نموذج مع صور وقناع اصطناعي صغير، ثم اختبار checksum وذاكرة الجهاز قبل ربط الدفع.

## سجل التحديثات

| 2026-09-13 | توافق Seika/ONNX | استبدال الجسر التجريبي بجسر ONNX، إضافة `proguard-rules.pro` وONNX Runtime 1.19.0، مع إبقاء Real-ESRGAN fallback لأن artifact الحالي `.pth` وليس ONNX. التحقق الآلي مؤجل لغياب Flutter/Gradle في السياق الحالي. |

| التاريخ | التغيير | النتيجة |
|---|---|---|
| 2026-09-13 | إنشاء الخارطة الحية | توثيق الحالة والفجوات وآلية التحديث |
| 2026-09-13 | تأسيس بيئة Flutter/Android | `flutter analyze` و`flutter test` ناجحان |
| 2026-09-13 | إنشاء مستودع النماذج | LaMa وReal-ESRGAN مرفوعان؛ MI-GAN مؤجل قانونيًا |
| 2026-09-13 | ربط روابط النماذج | التطبيق يشير إلى Hugging Face الحقيقي |
| 2026-09-13 | بدء البند 5 | بدء دمج LaMa ONNX داخل Android |
| 2026-09-13 | Model Manager | تنزيل LaMa واستئنافه والتحقق من SHA-256 والحذف؛ `flutter analyze` بلا أخطاء و3 اختبارات ناجحة |
| 2026-09-13 | Integration Map v3 | استبدال iOS Seika stub بجسر baseline متوافق مع عقد Flutter، وإضافة PerformanceConfig وProGuard؛ ONNX iOS مؤجل لغياب Runner/Pod runtime قابل للبناء |
| 2026-09-13 | Integration Map v4 | استبدال Editor وBatch stubs، إضافة Controller وPanels وExportDialog وBatchService وتوثيق ONNX edge cases وإضافة مسارات Router؛ `flutter analyze` بلا أخطاء و3 اختبارات ناجحة |
| 2026-09-13 | قرار النطاق | تأجيل iOS وWeb؛ المتبقي الحالي يقتصر على إكمال Android والتحقق منه وإعداده للإصدار |

## قاعدة التحديث المستقبلية

بعد كل مهمة، سأقوم بثلاثة أشياء: تحديث مربعات الإنجاز والحالة، إضافة سجل مختصر بالتاريخ والالتزام، ثم إبلاغك بأي اقتراح أو خطأ أو تغيير في القرار قبل الانتقال للمرحلة التالية.
