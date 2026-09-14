# P7 — Credits وGoogle Play Billing وBilling v2

**التاريخ:** 2026-09-14
**الحالة:** local billing foundation؛ Billing v2 وReceipt Verification غير مكتملين.

## المواصفة التجارية

| المنتج | ID | النوع | السعر المرجعي |
|---|---|---|---:|
| Pro Monthly | `pro_monthly` | auto-renewing subscription | `$4.99/month` |
| Pro Yearly | `pro_yearly` | auto-renewing subscription | `$29.99/year` |
| 100 Credits | `credits_100` | one-time consumable | `$4.99` |
| 500 Credits | `credits_500` | one-time consumable | `$19.99` |
| 1200 Credits | `credits_1200` | one-time consumable | `$39.99` |
| Lifetime Access | `lifetime` | one-time non-consumable | `$79.99` أو السعر الإقليمي |

المواصفة المرفقة تستهدف Free بثلاث صور شهريًا وPatchMatch وعلامة مائية؛ Pro بصور غير محدودة وBatch وBrand Identity ودون watermark؛ Lifetime بكل مزايا Pro إلى الأبد. لم تُثبت هذه الطبقات كمنفذة في التطبيق الحالي.

## الحالة الحالية

المنتجات الثلاثة `credits_100`, `credits_500`, `credits_1200` والاشتراكان `pro_monthly`, `pro_yearly` موثقان كمنتجات مفعلة في Play Console. لا يوجد دليل موثق على إنشاء وتفعيل `lifetime`. يجب أن ينشئه مالك Play Console ويضيف License Tester ويرفع AAB إلى Internal Testing.

الكود الحالي يملك `in_app_purchase` وpurchase stream وlocal ledger. حزم Credits فقط تصل إلى local grant عند purchased وPurchase ID صالح؛ pending/error لا تمنح Credits، وrestored consumables مرفوضة. الاشتراكات لا تمنح Credits محليًا. هذا **ليس** Receipt Verification ولا Pro entitlement خادميًا.

## اقتصاد Credits

إزالة الخلفية 1، shadow 1، enhance 2، conversational/inpaint 3، compliance 0، export 0. لا تخصم العملية قبل نجاحها، ولا تُسجل نتيجة فاشلة كنجاح.

## Billing v2 المطلوب

- إضافة المنتج السادس `lifetime` بعد Play Console.
- إنشاء `ProStatus` و`ProService` مع `isPro`, `isLifetime`, `expiry`, `daysRemaining`.
- حفظ `proExpiry` بصيغة ISO8601، auto-expiry للاشتراكات، وعدم انتهاء Lifetime.
- Paywall بثلاثة أقسام: Lifetime وSubscriptions وCredits.
- Settings يعرض حالة Pro وRestore، وBatch يملك Pro Gate، وHistory يطبق سياسة آخر 5 للمجاني/الكامل لـPro بعد تثبيت storage والسياسة.
- عدم grant لمنتج subscription أو restored consumable محليًا.
- عدم استخدام fallback price كسعر مؤكد؛ السعر الظاهر يجب أن يأتي من Google Play عندما يتوفر.
- عدم إعلان «كل النماذج» بما يشمل MI-GAN غير المرخص أو Real-ESRGAN غير الموصول.

## Receipt Verification قبل الإنتاج

يلزم backend موثوق مع مصادقة المستخدم، `POST /v1/billing/google-play/purchases/verify`، `GET /v1/billing/entitlements`، Google Play Developer API، unique token hash، transactional credit ledger، subscription state/expiry، RTDN dedup/retry، واختبارات replay/mismatch/pending/refund/expiry/revocation. يجب أن يبقى service account خارج التطبيق وGit.

ينبغي أن يبقى purchase في `pendingVerification` حتى يرد الخادم `verified` أو `already_processed`. لا يكفي `purchaseID` المحلي أو `completePurchase` لإثبات الملكية.

## الحالة والتحقق

| Check | Result |
|---|---|
| Product IDs الثلاثة للـCredits والاشتراكان | موثقة/مفعلة وفق سجلات Play السابقة |
| Lifetime product | Pending — إجراء Play Console بشري |
| Local purchase stream/ledger | موجود جزئيًا؛ يحتاج إعادة تشغيل tests على آخر commit |
| ProService/ProEntitlement | غير منفذ في التطبيق الحالي حسب الأدلة المتاحة |
| Sandbox/Test Card | Pending device وLicense Tester |
| Receipt/server verification | غير منفذ |
| Cross-device consumable restore | غير منفذ |
| Production billing | غير جاهز |

## إجراءات Play Console المطلوبة

1. إنشاء `lifetime` كـOne-time product وتفعيله.
2. ضبط الأسعار الستة وفق المواصفة الجديدة ومراجعة regional pricing.
3. إضافة حساب الاختبار إلى License Testing.
4. رفع AAB إلى Internal Testing.
5. تثبيت التطبيق واختبار purchased/pending/error/restored وMonthly/Yearly/Lifetime وCredits.
6. تسجيل device، app version، callbacks، ونتائج restore.

لا تُعتبر Billing جاهزة للإنتاج قبل إغلاق هذه الإجراءات وتنفيذ Receipt Verification وPro entitlement.
