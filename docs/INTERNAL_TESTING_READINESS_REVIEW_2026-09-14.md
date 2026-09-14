# مراجعة جاهزية Google Play Internal Testing

**التاريخ:** 2026-09-14  
**المستودع:** `toufikben/productchat_studio`  
**الفرع والمرجع:** `main`، آخر commit موثق في المراجعة `51c2794`  
**النطاق:** مصفوفة التحقق، خارطة الطريق، البناء، Billing، ومسار القبول قبل Internal Testing.

## الخلاصة التنفيذية

المشروع **ليس جاهزًا بعد لاعتبار Internal Testing مكتملًا**، لكنه يملك معظم البنية المصدرية اللازمة لبدء بوابة التحقق. العوائق الحالية تنقسم إلى ثلاث مجموعات: تحقق بناء لم يُعد تشغيله على آخر commit، تحقق Android فعلي غير موجود، وإعدادات Google Play Console البشرية غير المنفذة. لا توجد في الأدلة الحالية نتيجة تثبت تشغيل APK/AAB من commit `51c2794` على جهاز أو Emulator، ولا نتيجة تثبت إنشاء منتج `lifetime` أو اختبار شراء/استعادة فعلي.

## الحالة حسب المجال

| المجال | الحالة الحالية | هل يمنع Internal Testing؟ | الدليل المطلوب للإغلاق |
|---|---|---:|---|
| Flutter dependencies/analyze/test | موجودة في CI تاريخيًا، لكن لم تُعد على آخر commit | نعم | سجل `pub get`, `gen-l10n`, `analyze`, `test` على SHA الحالي |
| Debug APK | workflow ومشروع Android موجودان | نعم للتحقق المحلي | APK مبني ومثبت، مع SHA-256 وversionCode |
| Release APK | CI مهيأ للبناء والرفع | لاختبار التثبيت، نعم للإغلاق | artifact ناجح ومثبت على جهاز/Emulator |
| Release AAB | CI مهيأ للبناء والرفع | نعم للرفع إلى Play | artifact ناجح، signing وversionCode صحيحان |
| Signing | workflow يستخدم أسرار keystore مؤقتة | نعم | نجاح build دون تسريب أسرار، وفحص applicationId/versionCode |
| PatchMatch/Free | مصدر وfixtures وwatermark موجودة | نعم لاختبار smoke | تشغيل فعلي، شفافية، watermark، quota-after-success |
| LaMa | مصدر وعقد وcleanup موجودة | نعم إذا ظهر المسار في الإصدار | cold/warm، output، mask، timeout، cancellation، memory |
| Batch | Pro gate وAiService pipeline موجودان | نعم لمسار Pro | معالجة صورتين فعليًا، فشل ملف واستمرار البقية، History |
| History/Storage | versioned local metadata وdelete semantics | نعم للاختبار الأساسي | إغلاق/إعادة فتح، حفظ السجل، حذف output المولد |
| Billing catalog | IDs موجودة في الكود | نعم للشراء | المنتجات الستة موجودة ومطابقة في Play Console |
| Lifetime | موجود في الكتالوج فقط | نعم | إنشاء وتفعيل `lifetime` كـnon-consumable |
| License Tester | غير مثبت بالدليل | نعم للشراء | حساب الاختبار مضاف، propagation مكتمل |
| Restore/entitlement | local-first source موجود | نعم للشراء والاستعادة | Purchased/Restored/Pending/Error وexpiry/restore evidence |
| Privacy/Data Safety | شاشة Legal موجودة، مراجعة قانونية خارجية متبقية | نعم قبل التوزيع الداخلي المنظم | مراجعة Data Safety وPrivacy/Terms وتطابق سلوك التطبيق |
| Performance | protocol فقط | نعم قبل اعتبار الإصدار جاهزًا | latency، p95، memory، 30–100 عمليات، no OOM |

## المهام المطلوبة بالترتيب

### 1. تثبيت نسخة الاختبار

على بيئة تحتوي Flutter 3.47.4 وDart 3.13.3 وAndroid SDK 36 وJDK 17:

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

يجب حفظ نتيجة الأوامر مع SHA `51c2794` أو SHA جديد بعد أي إصلاح. لا يكفي الاعتماد على سجل CI قديم.

### 2. بناء artifacts من نفس المرجع

```bash
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

قبل البناء Release يجب إعداد `android/key.properties` خارج Git. بعد البناء يجب تسجيل:

- `applicationId`: `com.productchat.aiphotostudio`.
- version name وversionCode.
- SHA-256 للـAPK والـAAB.
- commit SHA.
- Flutter/Gradle/JDK/Android SDK versions.
- نجاح التوقيع وعدم وجود أسرار في artifact أو logs.

### 3. Smoke test على Android

يجب تثبيت Debug APK أو Release APK على جهاز أو Emulator وتسجيل device model وAndroid API وABI وRAM.

المسار الأدنى:

1. فتح التطبيق دون `MissingPluginException` أو crash.
2. اختيار صورة صغيرة ثم صورة Portrait وLandscape.
3. تشغيل PatchMatch من Chat وEditor.
4. التأكد من الشفافية، watermark، وعدم استهلاك Free quota عند الفشل.
5. اختبار Editor undo/redo/reset/export.
6. اختبار Chat output وHistory.
7. اختبار Batch بحساب Pro/Lifetime على صورتين على الأقل.
8. جعل إحدى صور Batch تفشل والتأكد من استمرار البقية.
9. اختبار History بعد إغلاق وإعادة فتح التطبيق.
10. اختبار delete item وclear History.
11. فتح Settings وFAQ وModels وSupport وLegal وRecipes وCompliance وOnboarding.

### 4. التحقق من النماذج والأداء

إذا كان LaMa ظاهرًا في مسار الاختبار، يجب تنفيذ cold/warm inference وتسجيل output dimensions وmask semantics وprovider وlatency وmemory. يجب اختبار cancellation وtimeout وretry و30–100 عملية متتالية. لا تُعلن LaMa أو أي نموذج آخر Release-ready قبل حفظ هذا الدليل.

### 5. إعداد Google Play Console

الإجراءات البشرية المطلوبة:

1. التأكد من أن التطبيق مسجل بنفس `applicationId`.
2. إنشاء `lifetime` كمنتج non-consumable وتفعيله.
3. إنشاء ومراجعة `pro_monthly` و`pro_yearly` والمنتجات الثلاثة Credits.
4. مطابقة IDs حرفيًا مع `CreditProducts`.
5. مراجعة الأسعار الإقليمية والوصف واللغة.
6. إضافة حسابات License Tester.
7. إنشاء Internal Testing track.
8. رفع AAB، وليس APK، إلى Play Console.
9. معالجة versionCode أو Upload Key mismatch إن ظهر.
10. إضافة testers وتنزيل التطبيق من رابط Internal Testing، لا من APK جانبي فقط.

### 6. اختبار Billing على النسخة المثبتة من Play

يجب تسجيل callback والنتيجة لكل حالة:

| الحالة | المتوقع |
|---|---|
| Pro Monthly purchased | لا يُفعل محليًا دون expiry موثوق وفق التصميم الحالي؛ يجب أن تكون الرسالة واضحة |
| Pro Yearly purchased | نفس القيد حتى يتوفر مصدر expiry موثوق |
| Lifetime purchased | تفعيل Lifetime بعد `serverVerificationData` غير فارغ |
| Credits purchased | grant مرة واحدة فقط عند Purchased وpurchase ID صالح |
| Pending | لا grant ولا entitlement نهائي |
| Error | لا grant ولا خصم |
| Restored consumable | لا grant |
| Restore Lifetime | إعادة إرسال event وتفعيل entitlement إذا تحقق المرجع |
| Refund/Revocation | توثيق السلوك الحالي وحدود Local-first |

## تناقضات يجب إصلاحها في الوثائق قبل إعلان الجاهزية

1. `docs/FEATURE_VERIFICATION_MATRIX.md` يحتوي صفين باسم `compliance`; يجب دمجهما في صف واحد.
2. `ROADMAP.md` ما زال يحتوي في المرحلة 5.3 على بند قديم يقول إن Batch pipeline متبقٍ، رغم أن Batch أصبح مربوطًا بـ`AiService` في commit سابق. يجب تمييز المتبقي بأنه **native runtime/performance verification** فقط.
3. `ROADMAP.md` يذكر أحيانًا أن Paywall بثلاثة أقسام متبقٍ، بينما المصدر الحالي يعرض Lifetime/Subscriptions/Credits؛ يجب فصل source-complete عن Play Console verification.
4. `docs/BUILD_AND_REPOSITORY_AUDIT.md` يحتوي عبارات تاريخية عن تضارب Storage وplaceholder routes تحتاج تحديثًا بعد commits `51c2794`.
5. مصفوفة التحقق يجب ألا ترفع `lifetime` أو `pro.entitlement` إلى Release ready قبل Play evidence.

## قرار القبول المقترح

يمكن الانتقال إلى **تحضير Internal Testing** بعد نجاح الخطوات 1–3 ورفع AAB صالح. لا يمكن إعلان **Internal Testing verified** إلا بعد تثبيت النسخة من Play track وتشغيل smoke flow. لا يمكن إعلان **Release ready** قبل إغلاق LaMa/performance وBilling/restore وprivacy/signing evidence.

## ما لا يمكن إغلاقه من Git وحده

إنشاء منتجات Play، تفعيل Lifetime، إضافة License Testers، رفع AAB، قبول Upload Key، شراء المنتجات، استعادة المشتريات، واختبار refund/revocation كلها تتطلب حساب Google Play Console وجهاز/حساب اختبار. الكود والوثائق وحدهما لا يثبتان هذه البنود.
