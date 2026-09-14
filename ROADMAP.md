# ProductChat Studio — خارطة الطريق التنفيذية الموحدة

> **الحالة المرجعية:** Android-first. لا تُرفع أي ميزة من «موجودة في المصدر» إلى «متحققة» أو «جاهزة للإصدار» دون دليل قابل لإعادة الإنتاج.
>
> **آخر تحديث:** 2026-09-14
> **الفرع:** `main`
> **الالتزام المرجعي قبل هذا التحديث:** `c070172`
> **مصادر الحقيقة:** هذه الخارطة، `docs/FEATURE_VERIFICATION_MATRIX.md`، `docs/MODEL_INVENTORY.md`، ووثائق التحقق المرتبطة.

## 1. قاعدة الحالة

| الحالة | المعنى |
|---|---|
| **موجود في المصدر** | يوجد ملف أو class أو artifact يمكن الإشارة إليه. |
| **موصول** | يوجد مسار UI/controller إلى الخدمة أو الجسر. |
| **قابل للتنفيذ** | لا يعتمد على stub ويُنتج السلوك المتوقع أو فشلًا صريحًا. |
| **متحقق آليًا** | يوجد اختبار آلي ناجح مرتبط بالميزة. |
| **متحقق على Android** | بُني التطبيق وشُغّل المسار على جهاز أو Emulator مع دليل مسجل. |
| **جاهز للإصدار** | اجتاز التشغيل، الأداء، الأخطاء، الخصوصية، الترخيص، الدفع، التوقيع، وCI عند الحاجة. |

وجود شاشة أو dependency أو model file لا يثبت اكتمال الميزة.

## 2. قرار المنتج التجاري المعتمد من المواصفات المرفقة

### 2.1 الطبقات

| الطبقة | ما يحصل عليه المستخدم | الحالة التصميمية |
|---|---|---|
| **Free** | 3 صور شهريًا، PatchMatch فقط، مع علامة مائية | منفذ محليًا؛ device/quality verification متبقية |
| **Pro** | صور غير محدودة، النماذج المتاحة قانونيًا، دون علامة مائية، Batch، Brand Identity | مواصفة مطلوبة؛ entitlement وgates غير مكتملة |
| **Lifetime** | كل مزايا Pro إلى الأبد | مواصفة مطلوبة؛ منتج Google Play لم يُنشأ بعد |

**قيد قانوني:** عبارة «كل النماذج» لا تشمل MI-GAN أو أي نموذج غير مرخص. MI-GAN يبقى معطلًا حتى تصريح واضح لإعادة التوزيع التجاري، وReal-ESRGAN لا يُسمى AI inference ما دام artifact المتاح `.pth` غير موصول.

### 2.2 منتجات Google Play والأسعار المرجعية

الأسعار التالية هي المواصفة التجارية المرفقة، بينما السعر النهائي المعروض للمستخدم يجب أن يأتي من `ProductDetails.price` ومن إعدادات Google Play الإقليمية:

| المنتج | Product ID | النوع | السعر المرجعي |
|---|---|---|---:|
| Pro Monthly | `pro_monthly` | اشتراك auto-renewing | `$4.99/month` |
| Pro Yearly | `pro_yearly` | اشتراك auto-renewing | `$29.99/year` |
| 100 Credits | `credits_100` | One-time consumable | `$4.99` |
| 500 Credits | `credits_500` | One-time consumable | `$19.99` |
| 1200 Credits | `credits_1200` | One-time consumable | `$39.99` |
| Lifetime Access | `lifetime` | One-time non-consumable | `$79.99` أو ما يضبطه Play إقليميًا؛ المواصفة المرفقة تذكر نحو `22,000 DZD` للجزائر |

**تعارض يجب اعتباره مغلقًا في التوثيق:** الأسعار القديمة `$0.99/$3.99/$7.99` لـCredits و`$39.99/year` لـPro Yearly لم تعد هي المواصفة التجارية المستهدفة بعد وصول Billing v2. لا يعني ذلك أن Play Console محدث؛ يلزم إجراء بشري لمراجعة الأسعار هناك.

### 2.3 اقتصاد Credits

| العملية | التكلفة |
|---|---:|
| إزالة الخلفية | 1 Credit |
| إضافة ظل | 1 Credit |
| تحسين/Enhance | 2 Credits |
| تحرير محادثي / Inpaint | 3 Credits |
| فحص التوافق | 0 Credits |
| التصدير | 0 Credits |

القاعدة الذهبية: لا يُخصم الرصيد قبل نجاح العملية، ولا يُمنح رصيد شراء نهائيًا اعتمادًا على callback محلي فقط قبل Receipt Verification خادمي.

## 3. الحالة الحالية المختصرة

| المجال | الحالة الحالية | الدليل أو الفجوة |
|---|---|---|
| Flutter/Android build | متحقق للبناء المحلي وCI وفق السجلات | Flutter 3.47.4، Dart 3.13.3، SDK 36، وأدلة analyze/test/build سابقة |
| Android runtime | غير متحقق | لا يوجد جهاز أو Emulator مسجل في الأدلة |
| LaMa ONNX | implementation وعقد مصدرية موجودة | cold/warm inference وoutput والذاكرة ما زالت بلا دليل جهاز |
| Real-ESRGAN | fallback فقط | `RealESRGAN_x4plus.pth` موجود، وONNX/NCNN غير موصول |
| MI-GAN | محظور قانونيًا وتقنيًا | لا تُضاف الأوزان قبل تصريح إعادة توزيع تجاري |
| Editor/Chat | جزئي | contracts وimage picker موجودان؛ mask وE2E/runtime متبقيان |
| Batch | Pro/Lifetime gate وpipeline محلي عبر AiService | Android runtime/performance واختبار الجهاز متبقية |
| Storage/History | SharedPreferences versioned metadata وbounded local History | Android restart/device retention verification متبقية |
| Credits/Billing | كتالوج v2 محلي منفذ جزئيًا | IDs الستة وLifetime وشراء non-consumable مضافة في المصدر؛ backend وPlay Console ما زالا متبقيين |
| Free/Pro/Lifetime gates | ProService محلي منفذ جزئيًا | Lifetime/expiry/persistence لها خدمة واختبارات؛ لا تُعد entitlement إنتاجية قبل الخادم |
| Internal Testing | غير مغلق | رفع AAB وقبول Upload Key وتثبيت/اختبار الجهاز متبقية |
| iOS/Web | مؤجلان | خارج الإصدار Android الحالي |

## 4. خارطة التنفيذ المرحلية

### المرحلة 0 — توحيد الحقائق والوثائق

**الحالة:** قيد التنفيذ في هذا التحديث.

- [x] قراءة جميع ملفات Markdown الحالية والمرفقات الأربعة.
- [x] توحيد نموذج Free/Pro/Lifetime كهدف منتج.
- [x] توثيق Product IDs الجديدة بما فيها `lifetime`.
- [x] توثيق اقتصاد Credits الجديد.
- [x] فصل المواصفة المطلوبة عن الحالة المثبتة.
- [ ] تحديث الكود ومصفوفة الاختبار بعد تنفيذ Billing v2 الفعلي.
- [ ] التأكد من عدم وجود وثيقة لاحقة تعيد الأسعار القديمة أو تدعي تفعيل Lifetime.

**معيار الخروج:** كل سعر، gate، وميزة لها حالة صريحة: مطلوب، موجود، متحقق، محجوب، أو يحتاج إجراءً بشريًا.

### المرحلة 1 — تثبيت البناء وإعادة التحقق

**الحالة:** متحقق للبناء وفق الأدلة السابقة، وإعادة التشغيل على آخر commit مطلوبة.

- [x] Flutter/Dart وAndroid SDK وJDK موثقة.
- [x] ملفات Android الأساسية وAAB workflow موجودة.
- [x] Release signing عبر `android/key.properties` دون أسرار في Git.
- [x] Release CI يبني ويرفع APK بالإضافة إلى AAB.
- [ ] إعادة تشغيل `flutter pub get` و`flutter gen-l10n` و`flutter analyze` و`flutter test` من آخر commit.
- [ ] بناء Debug APK وRelease AAB من نفس commit وتسجيل الأرقام.
- [ ] توحيد نتائج CI مع مصفوفة التحقق.

### المرحلة 2 — عقد الخدمات والمسار الأساسي

**الحالة:** جزئية.

- [x] `SeikaService` وMethodChannel ومسارات العمليات الأساسية موجودة.
- [x] `AiService` لا يعيد input كنجاح وهمي وفق أحدث handoff.
- [ ] إكمال image picker + mask creation + Chat dispatch + Editor result end-to-end.
- [x] جعل Batch يطبق pipeline التحرير الحقيقي عبر `AiService` بدل نسخ الملفات فقط.
- [x] حفظ History بعد نجاح العملية فقط وربطه بمخرجات قابلة لإعادة الفتح.
- [ ] إبقاء الفشل صريحًا وعدم تسجيل نتيجة أو خصم Credits عند الفشل.

### المرحلة 3 — LaMa Android runtime

**الحالة:** source/build complete، runtime متبقٍ.

- [x] LaMa artifact وعقد graph وSHA-256 موثقة.
- [x] CPU/NNAPI fallback وcancellation وnative timeout وresource cleanup موجودة في المصدر.
- [ ] تشغيل cold/warm inference على Emulator أو جهاز.
- [ ] اختبار input/mask names وmask semantics والصور portrait/landscape.
- [ ] اختبار decode failure، أبعاد غير متطابقة، oversized input، unload/reload.
- [ ] اختبار cancellation داخل `session.run` وhard timeout ثم retry.
- [ ] تسجيل latency وpeak Java/native memory وprovider.
- [ ] تنفيذ 30–100 عملية متتابعة وعدم وجود crash/OOM/deadlock أو نمو ذاكرة غير مفسر.

**معيار الخروج:** output صالح ومختلف عن source، مع سجل جهاز وAndroid API وABI وRAM وcommit وchecksum.

### المرحلة 4 — نماذج التحسين والقرارات القانونية

**الحالة:** قرار المنتج الحالي مكتمل، runtime اختياري.

- [x] تسمية fallback بأنه Basic enhancement لا Real-ESRGAN.
- [ ] اختيار ONNX export أو NCNN/TFLite بترخيص وbenchmark، أو إبقاء fallback نهائيًا مع تغيير الواجهة بوضوح.
- [ ] الحصول على تصريح MI-GAN إن كان مطلوبًا، ثم مراجعة artifact/license/runtime قبل الإضافة.
- [ ] عدم إضافة أي model binary أو claim غير مثبت.

### المرحلة 5 — Free/Pro/Lifetime وBilling v2

**الحالة:** تنفيذ المصدر المحلي الأولي مكتمل جزئيًا في commit هذه الدفعة؛ التكامل مع Play Console واختبارات الجهاز متبقية، وBackend الخارجي مستبعد بقرار Local-first.

#### 5.1 Product catalog

- [x] إضافة `lifetime` إلى كتالوج التطبيق كـnon-consumable؛ إنشاء المنتج وتفعيله في Play Console متبقٍ.
- [x] توحيد constants وdisplay names وcredits-per-pack ومدة الاشتراكات المرجعية.
- [x] إعادة تسمية الثابت الذي يستخدم `pro` لحزمة `credits_1200` إلى `largePack`.
- [x] Paywall يعرض أقسام Lifetime وSubscriptions وCredits، وأسعار المتجر الفعلية عند توفرها.

#### 5.2 Pro entitlement — Local Google Play Entitlement

- [x] إنشاء `ProService` مع `isPro` و`isLifetime` و`expiry` و`daysRemaining`.
- [x] تخزين `proExpiry` كسلسلة ISO8601 وفق المواصفة.
- [ ] تفعيل Monthly لمدة 30 يومًا وYearly لمدة 365 يومًا بعد event Google Play صالح؛ لا تُستنتج مدة الاشتراك من callback محلي وحده.
- [x] تمثيل Lifetime دون expiry بعد event Google Play، مع بقاء Lifetime دائمًا في الخدمة المحلية.
- [x] auto-expiry للاشتراك في حالة الخدمة المحلية.
- [x] حفظ SHA-256 fingerprint لمرجع الشراء وعدم حفظ المرجع الخام.
- [x] رفض تفعيل Lifetime من Boolean أو Product ID دون `serverVerificationData` صادر عن Billing.
- [x] Billing يطلب `restorePurchases` عند بدء جلسة Billing؛ restored consumables لا تمنح Credits.
- [ ] restore يزيل entitlement عند إثبات غياب Lifetime من Google Play.

#### 5.3 Gates وتجربة المستخدم

- [x] إضافة عداد Free شهري دائم بحد 3 صور، مع تدوير تلقائي حسب UTC month وعرض المتبقي في Paywall.
- [x] تنفيذ PatchMatch محليًا في Android عبر corner-seeded connected mask وpatch propagation/random search وشفافية PNG.
- [x] ربط Free quota بمساري Editor وChat؛ لا تُستهلك الحصة إلا بعد output ناجح.
- [x] حصر Free في PatchMatch background removal ورفض العمليات الأخرى بوضوح.
- [x] إضافة fixtures قابلة لإعادة التوليد واختبارات حفظ الأبعاد وPNG وFree watermark.
- [x] تطبيق Free watermark بعد نجاح PatchMatch وقبل استهلاك الحصة.
- [ ] اختبار جودة alpha على fixtures وأجهزة Android وضبط thresholds/الأداء.
- [x] Editor يوضح أدوات Pro المقفلة للمجاني ويعرض أخطاء gate بدل إسقاطها بصمت.
- [x] Chat يعرض حالة Free/Pro والحصة ويطبق gate وwatermark في مسار Free.
- [x] Batch Pro/Lifetime gate بحد 100 صورة مع رسالة واضحة للمجاني.
- [x] Brand Identity Pro/Lifetime gate مع حفظ محلي للهوية.
- [ ] Batch يطبق pipeline التحرير الحقيقي بدل نسخ الملفات فقط.
- [ ] الميزات المعتمدة قانونيًا والنماذج المتاحة فعليًا.
- [ ] تقييد العمليات المذكورة في المواصفة كـPro-only فقط بعد تحديد مسار تنفيذها الفعلي.
- [ ] Paywall بثلاثة أقسام: Lifetime، Subscriptions، Credits.
- [x] Settings يعرض حالة Pro/Lifetime، expiry، Restore، وروابط Paywall/Brand/History/Batch.
- [x] Batch يعرض Pro Gate لغير المشتركين ويمنع الاختيار قبل الترقية.
- [x] History يسجل النتائج الناجحة فقط؛ يعرض آخر 5 للمجاني والتاريخ الكامل لـPro/Lifetime.
- [ ] عدم عرض ميزة على أنها متاحة إذا كانت غير منفذة أو محظورة قانونيًا.

#### 5.4 Credits delivery

- [ ] حزم Credits الثلاث تستخدم purchase flow المناسب للـconsumables.
- [ ] لا grant عند pending أو error أو restored consumable.
- [ ] لا خصم قبل نجاح العملية؛ التكلفة مركزية وفق جدول الاقتصاد أعلاه.
- [ ] منع duplicate grant محليًا وخادميًا.
- [ ] عدم تحويل الاشتراك أو Lifetime إلى Credits دورية ما لم تُعتمد سياسة منفصلة صراحة.

### المرحلة 6 — Receipt Verification وEntitlement Backend

**الحالة:** مستبعد وفق قرار Local-first؛ Google Play Billing وRestore هما مصدر الملكية، مع توثيق حدود الحماية المحلية.

- [x] استبعاد Firebase وSupabase وServerless وBackend SaaS من التصميم.
- [x] اعتماد Google Play Billing و`restorePurchases` و`serverVerificationData` المحلي كمصدر الملكية المتاح للتطبيق.
- [x] توثيق أن SHA-256 fingerprint وledger المحلي يمنعان التكرار العرضي ولا يمثلان تحققًا ماليًا خادميًا.
- [ ] إعادة فحص Google Play عند فتح التطبيق وعند Restore، مع إزالة entitlement عند غياب عملية Lifetime.
- [ ] اختبار حالات Purchased/Restored/Pending/Error وRefund/Revocation عند عودة الاتصال.
- [ ] إبقاء خيار Backend ذاتي مستقبليًا فقط إذا أصبح منع APK المعدل أو التحقق المالي المستقل شرطًا تجاريًا.

### المرحلة 7 — التخزين والخصوصية

**الحالة:** جزئية ومتضاربة في الوثائق.

- [x] تثبيت SharedPreferences كـmetadata store فعلي؛ الصور والنماذج تبقى ملفات محلية، ولا يُستخدم Hive في هذا المسار.
- [x] حفظ Brand Identity وHistory بطريقة versioned مع schema version.
- [ ] ترحيل Credits/Free quota/Pro status إلى versioned envelope موحد.
- [ ] منع الرصيد السالب.
- [x] إدارة History retention بحد 100، وحذف عنصر/مسح السجل مع حذف المخرجات المتاحة.
- [x] تحديث Privacy/Terms لمسار التخزين المحلي وعمليات الحذف.
- [ ] توثيق عدم رفع الصور دون موافقة صريحة.
- [ ] اختبار إغلاق/إعادة فتح التطبيق وOffline بعد تنزيل النموذج.

### المرحلة 8 — الاختبارات والأداء وCI

**الحالة:** قيد التنفيذ على مستوى البروتوكول.

- [ ] تشغيل `integration_test/` الفعلي، إذ إن الخطة موجودة والمجلد غير مثبت حاليًا.
- [ ] اختبارات ProService: البداية، 30 يومًا، 365 يومًا، Lifetime، auto-expiry، restore.
- [ ] اختبارات Billing: المنتجات الستة، purchase statuses، completePurchase، duplicate grant، restored consumables.
- [ ] اختبارات Credits: 100/500/1200، stacking، refund، وعدم النزول تحت الصفر.
- [x] اختبارات service لـBatch/History/Brand/Storage؛ widget tests لـPaywall وSettings وBatch وHistory والراوتر ما زالت مطلوبة.
- [ ] Fixtures للصور والأقنعة دون تخزين النموذج داخل Git.
- [ ] benchmark cold/warm، cancellation، timeout، memory، CPU/NNAPI، 30–100 inference.
- [ ] CI للتحليل والاختبار والبناء وفحص الأسرار.

### المرحلة 9 — Internal Testing والإصدار

**الحالة:** غير مغلقة.

#### إجراءات Play Console البشرية المطلوبة

- [ ] إنشاء one-time product باسم `lifetime`، وصف Lifetime Access، السعر المرجعي `$79.99` أو السعر الإقليمي المعتمد، ثم تفعيله.
- [ ] إضافة حساب المالك إلى License Testing وانتظار propagation وفق تعليمات Play Console.
- [ ] مراجعة أسعار المنتجات الستة في Play Console وفق المواصفة الجديدة.
- [ ] رفع AAB إلى Internal Testing.
- [ ] معالجة Upload Key mismatch إن تكرر؛ المطلوب استخدام المفتاح الأصلي أو إجراء Reset رسمي من Play Console.
- [ ] تثبيت النسخة بحساب اختبار مرخص وتسجيل callbacks والشراء والاستعادة.

#### معيار قبول الإصدار Android

- [ ] Analyze وTest وDebug/Release build من clean checkout.
- [ ] smoke flow بلا MissingPlugin أو crash.
- [ ] LaMa output صالح ومتحقق على Android.
- [ ] cancellation/timeout/retry وmemory evidence مسجلة.
- [ ] كل زر ظاهر ينفذ وظيفة حقيقية أو يذكر أنه غير متاح.
- [ ] Free/Pro/Lifetime gates مطابقة لـentitlement موثوق.
- [ ] Receipt verification وledger وRTDN مكتملة أو لا توجد واجهة شراء إنتاجية.
- [ ] التوقيع والخصوصية والتراخيص وData Safety وrollback موثقة.

## 5. مؤجل عمدًا

- iOS وStoreKit وCore ML.
- Web وONNX Runtime Web.
- إضافة MI-GAN دون ترخيص مكتوب.
- Real-ESRGAN backend ما لم يُعتمد مسار ONNX/NCNN/TFLite.
- توسيع اللغات إلى 16 قبل تثبيت كونها شرط إصدار.
- AdMob؛ لا توجد مواصفة له في المنتج الحالي.

## 6. سجل هذا التحديث

| التاريخ | التغيير |
|---|---|
| 2026-09-14 | **دفعة تصحيحات كبيرة مخططة قبل التنفيذ:** versioned storage، retention/delete semantics، Batch options الفعلية، Restore/شراء أوضح، UX gates، اختبارات الخدمات والواجهات، وتوحيد وثائق الحالة. Play Console وAndroid device evidence تبقى إجراءات تحقق خارجية. |
| 2026-09-14 | **نتيجة الدفعة الكبيرة:** Batch/History/Storage/Restore/UX hardening منفذة؛ Batch يدعم remove background أو add shadow عبر AiService، وHistory versioned bounded مع delete، وCI/Play/device/widget verification ما زالت متبقية. |
| 2026-09-14 | إزالة شاشات FAQ/Models/Support الوهمية واستبدالها بمحتوى UX فعلي وربطها من Settings؛ تحديث Legal لمسار التخزين المحلي والحذف الآمن. |
| 2026-09-14 | إزالة Onboarding/Recipes/Compliance placeholders، إضافة محتوى صريح وروابط routes، وتحديث مصفوفة التحقق دون ادعاء اعتماد قانوني. |
| 2026-09-14 | قراءة خارطة الطريق الحالية ووثائق التحقق والدفع والأداء والمرفقات الأربعة كاملًا على مستوى المحتوى المتاح. |
| 2026-09-14 | اعتماد Billing v2 كمواصفة هدف: ستة Product IDs، Lifetime، Free/Pro/Lifetime، الأسعار الجديدة، واقتصاد Credits. |
| 2026-09-14 | فصل المواصفة المطلوبة عن حالة المصدر وPlay Console، وتسجيل الإجراءات البشرية التي لا ينفذها GitHub أو الكود تلقائيًا. |

لا تُعتبر المواصفات الجديدة منفذة لمجرد إدراجها هنا؛ كل بند سيُرفع فقط مع commit واختبار ودليل مناسب.
