# ProductChat Studio — خارطة الطريق الحية

> **مصدر الحقيقة للتحقق:** [`docs/MODEL_INVENTORY.md`](docs/MODEL_INVENTORY.md) و[`docs/FEATURE_VERIFICATION_MATRIX.md`](docs/FEATURE_VERIFICATION_MATRIX.md). وجود بند هنا لا يعني أنه runtime-verified؛ الحالة لا تُرفع إلا بدليل قابل لإعادة الإنتاج.

> **آخر تحديث:** 2026-09-14 05:48 UTC
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
| Android APK/AAB | AAB مبني، Upload Key يحتاج مطابقة Play Console | Workflow `34796595278` نجح؛ Play Console رفض الرفع لأن المتوقع SHA1 `20:EE:07:1E:9D:51:09:C1:29:D7:9B:6A:74:C1:AD:DC:81:96:88:5C` بينما AAB الحالي موقّع بـ `1A:D8:32:67:8E:A5:BE:19:AF:F4:B0:30:95:A3:5D:7D:89:02:10:00`; يلزم استخدام المفتاح الأصلي أو Reset Upload Key |
| P4 وظائف المنتج الأساسية | جزئي | image picker وفتح المحرر فعليان؛ mask/chat/batch/history ما زالت متبقية |
| P5 التخزين والخصوصية | جزئي | SharedPreferences وLegal screen مضافان؛ cache retention وHistory/Settings الدائمين متبقيان |
| P6 النماذج المتقدمة | قرار مكتمل، runtime متبقٍ | Real-ESRGAN fallback موثق؛ لا يوجد ONNX/NCNN backend، وMI-GAN معطل قانونيًا |
| P10 اللغات والوصول | جزئي | العربية/الإنجليزية وRTL wiring وSemantics أساسية؛ 16 لغة واختبارات شاملة متبقية |
| P7 Credits والدفع | منتجات Credits الفعلية مفعلة، Sandbox متبقية | `credits_100` و`credits_500` و`credits_1200` أصبحت Active في Play Console ومتاحة في 173 دولة/منطقة؛ الكود محدث إلى `1.0.1+2`؛ الاشتراكات واختبار Sandbox والتحقق الخلفي متبقية |
| الإعلانات | غير مخطط لها حاليًا | لا توجد AdMob SDK أو وحدات إعلانية؛ النموذج التجاري الحالي Credits مع اشتراك اختياري، والإعلانات ستضر بتجربة محرر صور محلي ولم تُطلب في الخارطة |
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

- [x] ربط `in_app_purchase` وpurchase stream.
- [x] تعريف product IDs في كود التطبيق.
- [x] تعريف `pro_monthly` و`pro_yearly` واستخدام purchase API المناسب للاشتراكات.
- [x] اعتماد الأسعار: 0.99/3.99/7.99 USD للـ Credits و4.99 شهريًا/39.99 سنويًا لـ Pro.
- [x] خصم الرصيد بعد نجاح العملية فقط.
- [x] منع منح الرصيد مرتين لنفس purchase ID.
- [x] إضافة Paywall وواجهة restore.
- [x] إنشاء مسودة التطبيق في Google Play Console بالمعرف `com.productchat.aiphotostudio`.
- [x] تحديد أسعار Credits ومزايا وفترات الاشتراك قبل إنشاء المنتجات المالية.
- [x] إنشاء وتفعيل `credits_100` و`credits_500` و`credits_1200` في Google Play Console؛ الحالة Active ومتاحة في 173 دولة/منطقة.
- [x] تعريف subscription products في الكود قبل إنشائها في Play Console.
- [ ] إنشاء وتفعيل `pro_monthly` و`pro_yearly` في Google Play Console ثم اختبار Sandbox على جهاز/حساب اختبار.
- [ ] إضافة receipt verification/backend ledger للـ consumables واستعادتها عبر الأجهزة.
- [ ] إضافة طبقة iOS StoreKit لاحقًا.

**قرار الإعلانات:** لا تُضاف AdMob في الإصدار الحالي. لا يوجد بند إعلانات في خارطة المنتج، والاعتماد على Credits/اشتراك يحافظ على تجربة تحرير الصور والخصوصية المحلية. يُعاد تقييم AdMob فقط إذا ظهرت حاجة تجارية مثبتة.

### 10. الاختبارات والأداء — متبقٍ

- [ ] توسيع اختبارات Smart Analysis.
- [x] إضافة اختبارات contract لـ Seika/AI/Model Manager.
- [ ] إضافة اختبارات MethodChannel وIntegration Tests على Android.
- [ ] بناء APK Debug وRelease وAAB.
- [ ] اختبار جهاز Android منخفض ومتوسط وحديث.
- [ ] قياس الذاكرة والزمن وحجم التنزيل.
- [ ] اختبار انقطاع الشبكة والتنزيل المتقطع.

### 11. إعداد Android للإصدار — Sprint 1 قيد التنفيذ

- [x] إضافة INTERNET إلى Manifest الأساسي للـ Release.
- [ ] مراجعة Manifest والأذونات وFileProvider.
- [ ] إعداد الأيقونات وSplash واسم الحزمة.
- [ ] إنشاء Keystore خارج Git (ينفذه مالك المشروع محليًا).
- [x] إعداد signing آمن عبر `android/key.properties` دون أسرار في Git؛ بناء Release يفشل بوضوح عند غياب الملف.
- [ ] فحص Google Play requirements.

**Sprint 1 — بوابة الرفع الداخلي:** تم تحديث إعداد Release وCI وManifest، وإضافة Workflow توقيع، وتشغيل `flutter analyze` و`flutter test` وبناء AAB Release موقع بنجاح. المتبقي: تنزيل Artifact `productchat-studio-release-aab`، رفعه إلى Internal Testing، وتسجيل أخطاء Play Console أو بدء اختبار التطبيق.

**تصحيح خطأ الرفع القديم:** رسالة Play Console كانت تخص `app-release.aab` سابقًا يستهدف API 34 ويضم Play Core 1.10.3. تم رفع `targetSdk` في المصدر إلى 36؛ يجب بناء AAB جديد وعدم إعادة رفع الملف القديم. أكد المالك أن الرفع السابق فشل ولم يُسجّل أي إصدار، لذلك يبقى `versionCode=1` (`1.0.0+1`) صالحًا للنسخة التالية.

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
| 2026-09-14 | Play Console وpackage identity | إنشاء مسودة `AI Photo Studio Chat`، وتثبيت `com.productchat.aiphotostudio` في الكود وPlay Console؛ `com.productchat.studio` بقيت مسودة قديمة ولم تُحذف تلقائيًا |
| 2026-09-14 | Monetization decision | اعتماد Credits مع اشتراك اختياري، وعدم إضافة AdMob حاليًا؛ أضيفت subscription IDs وميزات Pro المقترحة إلى Flutter، وإنشاء المنتجات ينتظر Play Console |
| 2026-09-14 | Sprint 1 release hardening | إزالة Debug signing من Release، اعتماد `android/key.properties` المحلي مع فشل واضح عند غيابه، إضافة INTERNET إلى main Manifest، توحيد Flutter CI إلى 3.47.4، وإضافة وثيقة إعداد الأسرار؛ التحقق وبناء AAB والرفع الداخلي متبقية |
| 2026-09-14 | إصلاح رفض AAB القديم | توثيق رسالة Play Console الخاصة بـ targetSdk 34 وPlay Core 1.10.3، ورفع `targetSdk` إلى API 36؛ يلزم بناء AAB جديد والتحقق من dependency tree قبل الرفع |
| 2026-09-14 | بناء AAB عبر GitHub Actions | إضافة workflow يدوي `build-release-aab.yml` يبني AAB موقعًا باستخدام أسرار يضيفها المالك، ويرفع artifact للتنزيل؛ لم تُحفظ أي أسرار في الريبو |
| 2026-09-14 | إصلاح فشل Build الأول | فشل التشغيل `34795627452` بسبب مسار Java ثابت غير صالح في `android/gradle.properties`؛ أزيل المسار ليستخدم Gradle `JAVA_HOME` الذي يضبطه GitHub Actions؛ التحليل والاختبارات والأسرار كانت ناجحة |
| 2026-09-14 | إصلاح فشل R8 في Build الثالث | التشغيل `34795926358` تجاوز مشكلة Java ووصل إلى R8، ثم فشل بسبب مراجع Flutter الاختيارية لـ Deferred Components/Play Core غير المستخدمة؛ أضيفت `-dontwarn` محددة دون إضافة Play Core القديم؛ يلزم إعادة بناء AAB |
| 2026-09-14 | نجاح Sprint 1 Build | التشغيل `34796595278` نجح على commit `229bc72`: الأسرار، التحليل، الاختبارات، R8، التوقيع، وبناء AAB ورفع Artifact؛ الملف `app-release.aab` بحجم 79.1 MB؛ الخطوة التالية Internal Testing |
| 2026-09-14 | Play Console Upload Key mismatch | Play Console رفض AAB الموقع بالمفتاح الجديد؛ expected SHA1 `20:EE:07:1E:9D:51:09:C1:29:D7:9B:6A:74:C1:AD:DC:81:96:88:5C`، uploaded SHA1 `1A:D8:32:67:8E:A5:BE:19:AF:F4:B0:30:95:A3:5D:7D:89:02:10:00`; يلزم استعادة المفتاح الأصلي أو طلب Reset Upload Key قبل إعادة البناء |
| 2026-09-14 | Billing code release `1.0.1+2` | تحديث purchase handling لقبول purchased/restored، رفض transaction ID الفارغ، تثبيت loading/error diagnostics، وتوسيع اختبارات Credits؛ إنشاء المنتجات وSandbox يتطلبان حساب Play Console وجهاز اختبار |

## قاعدة التحديث المستقبلية

بعد كل مهمة، سأقوم بثلاثة أشياء: تحديث مربعات الإنجاز والحالة، إضافة سجل مختصر بالتاريخ والالتزام، ثم إبلاغك بأي اقتراح أو خطأ أو تغيير في القرار قبل الانتقال للمرحلة التالية.
