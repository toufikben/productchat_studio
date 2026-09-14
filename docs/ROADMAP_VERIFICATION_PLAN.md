# خطة التحقق والتنفيذ الموحدة

**المشروع:** ProductChat Studio
**النطاق:** Android-first Flutter app
**آخر تحديث:** 2026-09-14
**مرجع التطبيق:** `main`؛ يجب تسجيل SHA لكل نتيجة تنفيذية.

## قاعدة الحالة

لا تكفي الملفات أو الواجهات أو dependencies لإثبات اكتمال الميزة. تعتمد الحالة على المراحل الآتية: **موجود في المصدر، موصول، قابل للتنفيذ، متحقق آليًا، متحقق على Android، جاهز للإصدار**. لا تنتقل الميزة إلى مرحلة لاحقة بلا evidence وtimestamp وcommit.

## مواصفة المنتج التجارية

يستهدف المنتج ثلاث طبقات: Free بثلاث صور شهريًا وPatchMatch وعلامة مائية؛ Pro بصور غير محدودة، النماذج المتاحة قانونيًا، دون watermark، وBatch وBrand Identity؛ وLifetime بكل مزايا Pro إلى الأبد. هذه مواصفة هدف وليست حالة تنفيذ مكتملة.

| المنتج | ID | النوع | السعر المرجعي |
|---|---|---|---:|
| Pro Monthly | `pro_monthly` | auto-renewing subscription | `$4.99/month` |
| Pro Yearly | `pro_yearly` | auto-renewing subscription | `$29.99/year` |
| 100 Credits | `credits_100` | one-time consumable | `$4.99` |
| 500 Credits | `credits_500` | one-time consumable | `$19.99` |
| 1200 Credits | `credits_1200` | one-time consumable | `$39.99` |
| Lifetime Access | `lifetime` | one-time non-consumable | `$79.99` أو السعر الإقليمي المعتمد |

لا تُعد أسعار Google Play المحلية أو Lifetime مفعلة في المستودع دليلًا حتى تُسجل من Play Console. لا تُضاف Credits دورية للاشتراكات بلا سياسة صريحة. اقتصاد العمليات هو: إزالة الخلفية 1، الظل 1، التحسين 2، conversational/inpaint 3، compliance 0، export 0.

## الحالة المثبتة والجِرد

| المجال | الحالة | الإجراء التالي |
|---|---|---|
| Flutter/Android build | build evidence موجود، إعادة التحقق على آخر commit مطلوبة | analyze/test/debug/release من clean checkout |
| LaMa | source/contract موجود؛ Android runtime غير مثبت | fixture، cold/warm، cancellation، memory، provider |
| Real-ESRGAN | `.pth` موجود، backend غير منفذ | ONNX/NCNN/TFLite بترخيص أو Basic fallback صريح |
| MI-GAN | غير مضاف بسبب الترخيص | لا artifact قبل تصريح تجاري مكتوب |
| Editor/Chat | contracts وimage picker موجودان؛ E2E جزئي | mask، dispatch، output، history |
| Batch | progress/UI موجود؛ pipeline الحقيقي متبقٍ | ربط jobs بعمليات التحرير/export |
| Storage | الوثائق متضاربة بين SharedPreferences وHive | تثبيت storage الفعلي ثم تحديث docs/tests |
| Billing | local handler وLocal Google Play entitlement؛ لا backend خارجي | Play Console وdevice testing، وreceipt backend مستبعد حاليًا |
| Internal Testing | غير مغلق | lifetime، license tester، AAB، device purchase |

## المراحل

### 0. Reconciliation

- [x] قراءة خرائط الطريق والوثائق والمرفقات الأربعة.
- [x] توحيد Free/Pro/Lifetime وProduct IDs الستة والاقتصاد.
- [x] فصل المطلوب عن الموجود والمتحقق.
- [ ] إزالة كل الإشارات غير المعتمدة للأسعار القديمة أو Lifetime المفعّل.

### 1. Build reproducibility

- [x] توثيق Flutter 3.47.4 وDart 3.13.3 وSDK 36 وJDK 17.
- [x] signing workflow وAAB evidence سابقان.
- [ ] إعادة `flutter pub get`, `flutter gen-l10n`, `flutter analyze`, `flutter test` على آخر commit.
- [ ] بناء APK/AAB وتسجيل artifact وSHA وversionCode.

### 2. Core product path

- [x] Seika MethodChannel وoperation contracts.
- [x] إزالة editor success الوهمي وفق آخر handoff.
- [ ] image picker + mask creation + Chat dispatch + Editor output.
- [ ] Batch editing pipeline بدل file copy.
- [x] History بعد output ناجح فقط، مع Free latest 5 وPro/Lifetime full history.

### 3. Android LaMa validation

- [ ] تثبيت النموذج والتحقق من SHA-256.
- [ ] تشغيل cold/warm على device/emulator.
- [ ] التحقق من input names، mask semantics، output dimensions، portrait/landscape.
- [ ] cancellation أثناء `session.run`، hard timeout، retry، unload/reload.
- [ ] 30–100 inference مع Java/native memory وCPU/NNAPI وmedian/p95.

### 4. Model/legal boundary

- [x] Basic enhancement fallback موثق وليس Real-ESRGAN.
- [ ] اختيار backend موثق ومختبر إن أريد Real-ESRGAN.
- [ ] MI-GAN يبقى disabled حتى تصريح إعادة توزيع تجاري.

### 5. Billing v2: Free/Pro/Lifetime

- [ ] إضافة `lifetime` بعد إنشائه وتفعيله في Play Console.
- [ ] توحيد constants/display names/store prices/pack mapping.
- [ ] عدم استخدام اسم `pro` لحزمة Credits داخل الكود لتجنب الالتباس.
- [ ] إنشاء `ProStatus` و`ProService` مع expiry ISO8601 وauto-expiry وLifetime دائم.
- [ ] ربط Monthly بـ30 يومًا وYearly بـ365 يومًا بعد تحقق موثوق، لا callback محلي فقط.
- [ ] Paywall بثلاثة أقسام Lifetime/Subscriptions/Credits.
- [x] Free quota وwatermark وPatchMatch وEditor/Chat gates منفذة محليًا؛ fixtures أضيفت.
- [ ] Pro gates لـBatch/Brand/النماذج المعتمدة؛ History آخر 5 للمجاني والكامل لـPro إذا ثبتت السياسة.
- [ ] لا grant للـCredits عند pending/error/restored؛ ولا خصم قبل نجاح العملية.
- [x] Settings/Batch/History/Brand تعرض الحالة الحقيقية فقط وتطبق Pro/Lifetime gates محليًا.

### 6. Receipt Verification backend

**الحالة:** مستبعد وفق قرار Local-first. يعتمد الإصدار الحالي على Google Play Billing وRestore داخل التطبيق، مع توثيق أن ذلك لا يوفر إثباتًا ماليًا مستقلًا ضد APK معدل أو refund أثناء offline.

- [x] استبعاد Firebase وSupabase وServerless وBackend SaaS.
- [x] حفظ fingerprint محلي بدل Purchase Token الخام.
- [ ] اختبار Purchased/Restored/Pending/Error وRefund/Revocation عند توفر جهاز وGoogle Play.
- [ ] يبقى Backend ذاتي خيارًا مستقبليًا فقط إذا أصبح التحقق المالي المستقل شرطًا تجاريًا.

### 7. Storage/privacy

- [ ] حسم Hive أو SharedPreferences في الكود أولًا ثم تحديث الوثائق.
- [ ] credits/history/settings/locale/theme versioned.
- [ ] clamp للرصيد ومنع double grant/negative balance.
- [ ] Privacy/Terms/Compliance وoffline tests.
- [ ] عدم رفع الصور دون موافقة.

### 8. Test/performance/CI

- [ ] `integration_test/` فعلي وfixtures صور/أقنعة صغيرة.
- [ ] Pro/Billing/Credits unit tests وPaywall/Settings/Batch/History widget tests.
- [ ] MethodChannel contract وAndroid integration tests.
- [ ] GitHub Actions analyze/test/build/secrets.

### 9. Internal Testing/release

**إجراءات بشرية مطلوبة:** إنشاء Lifetime وتفعيله؛ إضافة License Tester؛ مراجعة الأسعار؛ رفع AAB؛ حل Upload Key mismatch؛ تثبيت النسخة واختبار Test Card وrestore. لا يمكن تنفيذ هذه الإجراءات من Git وحده.

**معيار الخروج:** clean checkout ينجح، Android smoke flow ينجح، LaMa runtime evidence محفوظ، كل UI معلن فعلي أو disabled بوضوح، Pro/Lifetime يتبعان entitlement موثوقًا، وreceipt/ledger/Play testing مكتملة قبل الإطلاق العام.

## مؤجل

iOS وWeb وStoreKit وMI-GAN غير المرخص وReal-ESRGAN backend غير المختار وتوسيع اللغات إلى 16 وAdMob خارج Android release الحالي.

## مصادر مرتبطة

- `ROADMAP.md`
- `docs/FEATURE_VERIFICATION_MATRIX.md`
- `docs/MODEL_INVENTORY.md`
- `docs/P8_PERFORMANCE_BENCHMARK.md`
- `docs/SPRINT5_RECEIPT_VERIFICATION_EXECUTION_PLAN.md`
- `docs/RELEASE_SIGNING.md`

**آخر تحديث:** 2026-09-14.
