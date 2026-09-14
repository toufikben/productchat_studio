# خطة Sprint 5 وتنفيذ خادم التحقق من الإيصالات

**المشروع:** ProductChat Studio  
**تاريخ الخطة:** 2026-09-14  
**الحالة الحالية:** Sprint 5/P8 بدأت على مستوى البروتوكول؛ Receipt Verification وPro Entitlement غير منفذين.  
**مصدر التدقيق:** [`SPRINT4_RECEIPT_SUBSCRIPTION_AUDIT.md`](SPRINT4_RECEIPT_SUBSCRIPTION_AUDIT.md)  
**الفرع المرجعي:** `main`، وآخر تدقيق منشور في commit `f9ce5fd`.

## 1. القرار التنفيذي

لا يجوز اعتبار Billing جاهزًا للإنتاج بمجرد نجاح `purchaseStream` داخل التطبيق. القيمة المالية يجب أن تُمنح بناءً على سجل خادمي موثوق، لأن `purchaseID` والحدث المحلي لا يكفيان لإثبات الملكية عبر الأجهزة أو منع إعادة التشغيل بعد حذف التخزين المحلي.

تتكون Sprint 5 من مسارين متوازيين:

1. **P8 Performance:** تنفيذ قياسات Android cold/warm، الذاكرة، cancellation، timeout، CPU/NNAPI، والاستقرار المتكرر وفق [`P8_PERFORMANCE_BENCHMARK.md`](P8_PERFORMANCE_BENCHMARK.md).
2. **Receipt Verification:** إنشاء API خادمي يتحقق من Purchase Token عبر Google Play Developer API، ويسجل المعاملات والاشتراكات في قاعدة بيانات بمعاملات ذرية، ثم يعيد Entitlement موثوقًا للتطبيق.

الانتقال إلى Release لا يعتمد على إغلاق مسار الأداء فقط؛ يجب إغلاق بوابة Internal Testing، واختبار الشراء الحقيقي، والتحقق الخلفي قبل أي إطلاق عام.

## 2. حالة بوابة Sprint 1–4

| Sprint | الحالة | ما ثبت | ما يمنع الإغلاق الكامل |
|---|---|---|---|
| Sprint 1 — Release upload | جزئية | Release signing، `INTERNET`، target SDK 36، وWorkflow بناء AAB موقع | رفع Internal Testing، قبول Upload Key، تثبيت الجهاز، وتسجيل أخطاء Play |
| Sprint 2 — Internal validation | غير مكتملة | قوائم الفحص والتوثيق | تثبيت النسخة من Play، اختبار التشغيل والـEditor وCredits والخصوصية، ومراجعة crashes |
| Sprint 3 — Product activation | جزئية | منتجات `credits_*` والاشتراكات مفعلة في Play Console | شراء فعلي بحساب اختبار مرخّص، واختبار pending/error/restore |
| Sprint 4 — Billing correctness | مكتملة على مستوى الكود الأساسي | فصل الاشتراكات عن Credits، منع restored consumable، واختبارات catalog/ledger | خادم التحقق، Pro entitlement، RTDN، والاختبار على جهاز |
| Sprint 5 — P8 + Verification | قيد التنفيذ | بروتوكول الأداء وتقرير التدقيق موجودان | القياسات runtime، خادم التحقق، وربط التطبيق بالخادم |

يُسمح ببدء Sprint 5، لكن ذلك لا يرفع حالة Sprint 1–4 إلى **Production Ready**.

## 3. خيارات البنية

| الخيار | الوصف | المزايا | القيود | التكلفة والتعقيد |
|---|---|---|---|---|
| **A — خدمة API مخصصة مع قاعدة بيانات وWorker إشعارات** | API HTTPS، قاعدة PostgreSQL، عامل لمعالجة Pub/Sub/RTDN، وحساب خدمة Google محفوظ في Secret Manager | تحكم كامل في المنح، الاشتراكات، التدقيق، والهجرة؛ مناسب لمنتج مالي قابل للنمو | يحتاج نشرًا ومراقبة وإدارة أسرار ونسخًا احتياطية | تعقيد متوسط إلى مرتفع؛ تكلفة تشغيل مستمرة بحسب الاستضافة |
| **B — Backend مُدار بواجهات Serverless** | وظائف HTTPS وقاعدة بيانات مُدارة وSecret Manager، مع Worker أو endpoint لمعالجة RTDN | إعداد أسرع، نسخ احتياطي ومراقبة أسهل، وعدد أقل من الخوادم | قيود المنصة، اعتماد أكبر على مزود واحد، واختبارات المعاملات تحتاج عناية | تعقيد منخفض إلى متوسط؛ مناسب للمرحلة الأولى |

**المسار الأخف** هو تنفيذ API تحقق واحد وقاعدة بيانات مُدارة، مع تأجيل لوحة الإدارة إلى ما بعد Internal Testing. وفي كلا الخيارين يجب أن يبقى Google service account على الخادم فقط، وألا يصل أي سر إلى تطبيق Flutter أو Git.

## 4. نطاق الإصدار الأول للخادم

### 4.1 واجهة إرسال شراء

`POST /v1/billing/google-play/purchases/verify`

يجب أن يتطلب الطلب مصادقة المستخدم، وألا يقبل `userId` من جسم الطلب كمصدر ثقة.

```json
{
  "productId": "credits_500",
  "purchaseToken": "PLAY_PURCHASE_TOKEN",
  "purchaseId": "LOCAL_PURCHASE_ID",
  "packageName": "com.productchat.aiphotostudio",
  "appVersion": "1.0.2+3",
  "platform": "android"
}
```

قواعد التحقق:

- `packageName` يطابق قيمة الخادم الثابتة.
- `productId` موجود في allow-list الخادم، وليس في قيمة يرسلها العميل فقط.
- `purchaseToken` غير فارغ، ويُعامل كسر لا يُسجل كاملًا في logs.
- المستخدم مصادق عليه.
- الطلب يمر عبر rate limit وrequest id.
- إعادة إرسال نفس token تعيد النتيجة السابقة ولا تمنح القيمة مرة ثانية.

### 4.2 استجابة التحقق

```json
{
  "status": "verified",
  "purchaseType": "consumable",
  "productId": "credits_500",
  "transactionId": "GPA.0000-0000-0000-00000",
  "grantedCredits": 500,
  "entitlements": {
    "pro": false,
    "expiresAt": null
  },
  "ledgerEntryId": "ledger_123",
  "idempotent": false
}
```

الحالات المتوقعة هي `verified` و`already_processed` و`pending` و`rejected` و`temporarily_unavailable`. لا يعيد الخادم `verified` قبل نجاح Google Play Developer API وتطبيق قواعد المنتج.

### 4.3 واجهة مزامنة الحالة

`GET /v1/billing/entitlements`

تعيد الخادم حالة المستخدم الحالية:

```json
{
  "credits": 500,
  "pro": {
    "active": true,
    "productId": "pro_monthly",
    "expiresAt": "2026-10-14T06:00:00Z",
    "autoRenewing": true,
    "state": "ACTIVE"
  },
  "lastSyncedAt": "2026-09-14T06:40:00Z"
}
```

يجب أن تكون هذه الاستجابة **مصدر الحقيقة** لفتح Pro، مع سياسة cache قصيرة وآمنة عند انقطاع الشبكة. لا ينبغي أن يتحول انقطاع الشبكة إلى تمديد غير محدود للاشتراك.

### 4.4 واجهة RTDN

`POST /v1/webhooks/google-play/rtdn`

تصل رسالة Cloud Pub/Sub، ويجب تنفيذ ما يلي:

1. التحقق من أصل الرسالة وتوقيع/هوية Pub/Sub وفق إعداد الاستضافة.
2. فك `message.data` من Base64.
3. التحقق من `packageName`.
4. تسجيل `messageId` مرة واحدة لمنع التكرار.
5. استخراج `purchaseToken` دون وضعه في السجلات النصية.
6. استدعاء Google Play Developer API لجلب الحالة الكاملة؛ إشعار RTDN يخبر بتغير الحالة ولا يحتوي وحده على كل بيانات الشراء [3].
7. تحديث الاشتراك أو المعاملة داخل معاملة قاعدة بيانات.
8. إعادة HTTP 2xx بعد الحفظ أو وضع الرسالة في retry/dead-letter عند الفشل.

## 5. تكامل Google Play Developer API

### 5.1 المنتجات الاستهلاكية

للمنتجات `credits_100` و`credits_500` و`credits_1200` يستخدم الخادم:

```text
GET /androidpublisher/v3/applications/{packageName}/purchases/products/{productId}/tokens/{token}
```

هذا المسار يعيد حالة الشراء والاستهلاك، ويتطلب OAuth scope `https://www.googleapis.com/auth/androidpublisher` [2]. يجب قبول المعاملة فقط عندما تكون حالتها ناجحة، والمنتج مطابقًا، والكمية مدعومة، ولم يسجل token سابقًا.

### 5.2 الاشتراكات

للمنتجين `pro_monthly` و`pro_yearly` يستخدم الخادم:

```text
GET /androidpublisher/v3/applications/{packageName}/purchases/subscriptionsv2/tokens/{token}
```

يعيد هذا المسار `subscriptionState` و`acknowledgementState` و`lineItems` و`expiryTime` وبيانات التجديد والـlinked token، ويتطلب OAuth scope نفسه [1]. يجب ألا تعتمد الخدمة على اسم المنتج من العميل فقط؛ يجب مطابقة `lineItems.productId` مع token الذي أعاده Play.

### 5.3 سياسة الحالات

| حالة Google Play | Pro | Credits | الإجراء |
|---|---:|---:|---|
| Active / purchased | نعم عند الاشتراك | منح مرة واحدة للـconsumable | حفظ الحالة والمعاملة |
| Pending | لا | لا | إبقاء المعاملة pending وإعادة المحاولة |
| Canceled قبل الانتهاء | نعم حتى `expiryTime` حسب الحالة | لا Grant جديد | حفظ cancellation ووقت الانتهاء |
| Expired | لا | لا | إبطال Pro |
| Revoked/refunded/voided | لا | عكس أو تجميد القيمة وفق سياسة المنتج | سجل تدقيق وتعويض/استرداد مضبوط |
| Grace period / account hold | وفق سياسة المنتج | لا Grant جديد تلقائيًا | تحديث الحالة وإظهارها للمستخدم |

لا يتم استنتاج هذه الحالات من نص واجهة المستخدم. مصدرها هو رد Google API بعد جلب الحالة الكاملة.

## 6. نموذج البيانات المقترح

### `billing_accounts`

يحتوي على `user_id`، وقت الإنشاء، وآخر مزامنة. لا يخزن Purchase Token في سجل عادي مكشوف.

### `google_play_purchases`

| الحقل | الغرض |
|---|---|
| `id` | معرف داخلي |
| `user_id` | مالك الحساب الداخلي |
| `package_name` | منع خلط التطبيقات |
| `product_id` | allow-list المنتج |
| `purchase_token_hash` | مفتاح فريد غير قابل للعرض في logs |
| `order_id` | معرف Play إن توفر |
| `purchase_type` | consumable أو subscription |
| `purchase_state` | pending/purchased/canceled/voided/expired |
| `acknowledgement_state` | حالة acknowledgement |
| `quantity` | الكمية المدعومة |
| `raw_response_encrypted` | اختياري مع retention محدود |
| `first_verified_at` | أول تحقق ناجح |
| `last_verified_at` | آخر مزامنة |
| `created_at` / `updated_at` | التدقيق |

يجب فرض unique constraint على `purchase_token_hash`، مع قيد إضافي يمنع منح المنتج نفسه مرتين بسبب اختلاف `purchaseId` المحلي.

### `credit_ledger`

يسجل كل حركة Credits كـ`grant` أو `spend` أو `reversal` مع `purchase_record_id` و`amount` و`idempotency_key`. عملية التحقق وإنشاء grant وتحديث الرصيد يجب أن تنفذ في **معاملة واحدة**.

### `subscription_entitlements`

يسجل `user_id` و`product_id` و`state` و`expiry_time` و`auto_renewing` و`linked_purchase_token_hash` و`last_order_id` و`last_rtdn_message_id`.

### `webhook_events`

يحفظ `message_id` وhash الرسالة ونوعها وحالة المعالجة ووقت الاستلام. unique constraint على `message_id` يمنع معالجة RTDN مرتين.

## 7. الأمن والخصوصية

- حفظ Google service account في Secret Manager أو متغيرات بيئة سرية للخادم فقط.
- منح الحساب أقل OAuth scope مطلوب.
- تقييد API بالـTLS ومصادقة المستخدم وrate limiting.
- عدم تسجيل Purchase Token أو بيانات المستخدم الحساسة في logs.
- تخزين hash للـtoken، وتشفير raw response إن احتجنا الاحتفاظ به.
- عدم قبول مبلغ أو عدد Credits من العميل.
- عدم الثقة في `purchaseID` المحلي كبديل عن token Google.
- استخدام idempotency keys وunique database constraints.
- إضافة audit log للمنح والإلغاء والاسترداد.
- وضع retention policy وحذف raw purchase payload بعد انتهاء الحاجة القانونية/التشغيلية.
- اختبار replay، token من package مختلف، product mismatch، وuser mismatch.

## 8. خطة تنفيذ مرحلية

| المرحلة | الأعمال | ناتج قابل للمراجعة | معيار الخروج |
|---:|---|---|---|
| 0 | تثبيت القرار المعماري، package name، product allow-list، هوية المستخدم، وبيئة الاستضافة | ADR وملف config غير سري | لا توجد قيم مالية أو أسرار في التطبيق |
| 1 | إنشاء API contract وschema وerror codes | OpenAPI أو وثيقة تعاقدية واختبارات validation | الطلبات غير الصحيحة تُرفض قبل Google API |
| 2 | إنشاء Google service account وصلاحيات Play Console خارج Git | secret setup موثق دون قيمة السر | الخادم فقط يستطيع طلب API |
| 3 | تنفيذ verifier للـconsumables | adapter لـ`purchases.products.get` مع fake client | valid/pending/invalid/mismatch/duplicate tests |
| 4 | تنفيذ المعاملة والـledger | migrations وunique constraints | exactly-once grant تحت retry وconcurrency |
| 5 | تنفيذ verifier للاشتراكات | adapter لـ`subscriptionsv2.get` | active/expired/canceled/hold/grace/revoked tests |
| 6 | تنفيذ Entitlement API وربطه بالتطبيق | client sync وPro state model | Pro يتبع الحالة الخادمية ولا يعتمد على callback المحلي |
| 7 | تنفيذ RTDN وdead-letter/retry | Pub/Sub endpoint وevent table | renew/cancel/expire/refund reconciliation |
| 8 | إزالة المنح المالي المحلي أو تحويله إلى pending فقط | BillingService client update | لا Grant نهائي دون رد خادمي verified |
| 9 | اختبار Internal Testing | سجل جهاز وحساب اختبار وPlay Console | شراء Credits واشتراك واستعادة وإعادة تشغيل مجتازة |
| 10 | الإطلاق التدريجي | dashboards وalerts وrollback plan | لا أخطاء مالية غير مفسرة خلال فترة المراقبة |

## 9. تغييرات Flutter المطلوبة

1. إضافة هوية مستخدم مصادق عليها قبل شراء أي قيمة.
2. استخراج Purchase Token من `PurchaseDetails` بطريقة يدعمها Android plugin المستخدم، دون وضعه في logs.
3. إرسال token إلى `POST /v1/billing/google-play/purchases/verify`.
4. إبقاء المعاملة في حالة `pendingVerification` حتى رد الخادم.
5. منح Credits فقط من استجابة خادمية `verified` أو `already_processed`.
6. جعل `restorePurchases()` يبدأ مزامنة الخادم بدل منح Credits محليًا.
7. إضافة `ProEntitlement` يحتوي `active` و`state` و`expiresAt` و`lastSyncedAt`.
8. قفل الميزات Pro وفق entitlement الخادمي.
9. التعامل مع `temporarily_unavailable` دون منح قيمة، مع retry محدود وbackoff.
10. إبقاء `completePurchase` في مكانه وفق متطلبات plugin، مع الفصل الواضح بين إكمال معاملة المتجر ومنح القيمة الخادمية.

## 10. الاختبارات المطلوبة

### اختبارات الخادم

- token صالح لمنتج Credits معروف.
- token صالح لمنتج غير معروف.
- package name خاطئ.
- token من تطبيق آخر.
- token فارغ أو malformed.
- Google API timeout و429 و5xx.
- pending purchase.
- duplicate request متزامن عشرات المرات.
- duplicate RTDN بنفس `messageId`.
- refund/voided purchase.
- subscription active، expired، canceled، grace، hold، revoked.
- linked purchase token عند ترقية/تبديل الخطة.
- عدم تسريب token في السجلات.

### اختبارات Flutter

- `pending` لا يمنح Credits.
- `error` لا يمنح Credits.
- `restored` consumable لا يمنح Credits.
- subscription purchased/restored لا يمنح Credits مباشرة.
- رد الخادم `verified` يمنح النتيجة مرة واحدة.
- رد `already_processed` لا يكرر المنح.
- فشل الخادم يبقي المعاملة قابلة لإعادة المحاولة دون grant محلي.
- Pro ينشط فقط مع entitlement active.
- Pro ينتهي عند expiry أو revoked.
- `completePurchase` لا يُعامل كدليل تحقق خادمي.

### اختبارات أمنية

- replay لنفس token من مستخدم آخر.
- تعديل `productId` أو `packageName`.
- brute force على endpoint.
- Pub/Sub message غير موثوق.
- raw response وtoken في logs أو crash reports.

## 11. متطلبات Sprint 5 / P8 بالتوازي

لا ينبغي أن يمنع بناء الخادم تنفيذ القياسات. يجب تشغيل البروتوكول في [`P8_PERFORMANCE_BENCHMARK.md`](P8_PERFORMANCE_BENCHMARK.md):

- جهاز منخفض ومتوسط وحديث متى أمكن.
- cold/warm LaMa.
- cancellation وhard timeout.
- 30–100 inference متتالية.
- peak Java/native memory.
- CPU مقابل NNAPI.
- صور 1MP و12MP.
- lifecycle background/resume/destroy.

لكل نتيجة يجب تسجيل الجهاز وAndroid API وABI وRAM ونسخة التطبيق وchecksum النموذج وprovider. لا تُستخدم تقديرات الأداء الحالية كبديل عن القياس.

## 12. معايير القبول النهائية

لا تُغلق Receipt Verification أو Sprint 5 قبل تحقق جميع البنود الآتية:

- خادم منشور عبر HTTPS مع مصادقة ومراقبة.
- Google service account خارج Git والتطبيق.
- تحقق consumables عبر `purchases.products.get`.
- تحقق subscriptions عبر `purchases.subscriptionsv2.get`.
- unique token constraint وtransactional ledger.
- RTDN مع deduplication وretry/dead-letter.
- Pro entitlement active/expired/canceled/revoked موثق ومختبر.
- Flutter لا يمنح Credits نهائيًا من callback محلي وحده.
- اختبارات unit/integration/security ناجحة.
- Internal Testing purchase وrestore ناجحان بحساب مرخص.
- P8 runtime results محفوظة مع median/p95 وmemory evidence.
- سياسة rollback عند فشل verifier أو Google API.
- لا توجد أسرار أو Purchase Tokens في Git أو logs.

## 13. المخاطر والقرارات المؤجلة

| الخطر | الأثر | المعالجة |
|---|---|---|
| عدم وجود هوية مستخدم | لا يمكن ربط الشراء بالحساب | تنفيذ auth قبل cross-device restore |
| Google API quota أو outage | تأخر المنح | pending state، retry محدود، ومراقبة |
| اختلاف token بين plugin والمنصة | فشل التحقق | Android integration test واستخراج token موثق |
| refund بعد منح Credits | خسارة مالية | RTDN/voided reconciliation وسياسة reversal |
| subscription replacement | entitlement مزدوج أو خاطئ | linked token وlatest line item state |
| تخزين قيمة محليًا قبل الرد | replay/grant غير موثوق | local state pending فقط |
| غياب جهاز Android | لا إثبات runtime أو purchase | توفير Emulator/جهاز Internal Testing |

## 14. الترتيب التنفيذي المقترح

1. تثبيت هوية المستخدم وقرار الاستضافة.
2. إنشاء API contract وdatabase migrations.
3. تنفيذ verifier للمنتجات الاستهلاكية والـledger الذري.
4. تنفيذ verifier للاشتراكات وPro entitlement.
5. تنفيذ Flutter pending/server-grant flow.
6. إضافة RTDN والـreconciliation.
7. توسيع اختبارات Flutter والخادم والأمن.
8. تشغيل Sprint 5 performance benchmark على Android.
9. تنفيذ Internal Testing للشراء والاستعادة.
10. تحديث [`ROADMAP.md`](../ROADMAP.md)، [`FEATURE_VERIFICATION_MATRIX.md`](FEATURE_VERIFICATION_MATRIX.md)، و[`P7_BILLING_VALIDATION.md`](P7_BILLING_VALIDATION.md) بأدلة commands وruns والأجهزة.

## المراجع

[1]: https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptionsv2/get "Google Play Developer API — purchases.subscriptionsv2.get"

[2]: https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.products/get "Google Play Developer API — purchases.products.get"

[3]: https://developer.android.com/google/play/billing/rtdn-reference "Google Play Billing — Real-time developer notifications reference guide"
