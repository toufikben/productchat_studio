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

المواصفة المرفقة تستهدف Free بثلاث صور شهريًا وPatchMatch وعلامة مائية؛ Pro بصور غير محدودة وBatch وBrand Identity ودون watermark؛ Lifetime بكل مزايا Pro إلى الأبد. طبقة الكتالوج و`ProService` المحلي أضيفتا الآن، لكن gates الكاملة والـentitlement الخادمي لم تُثبت بعد.

## الحالة الحالية

المنتجات الثلاثة `credits_100`, `credits_500`, `credits_1200` والاشتراكان `pro_monthly`, `pro_yearly` موثقان كمنتجات مفعلة في Play Console. لا يوجد دليل موثق على إنشاء وتفعيل `lifetime`. يجب أن ينشئه مالك Play Console ويضيف License Tester ويرفع AAB إلى Internal Testing.

الكود الحالي يملك `in_app_purchase` وpurchase stream وlocal ledger، ويدعم IDs الستة مع Lifetime كـnon-consumable. حزم Credits فقط تصل إلى local grant عند purchased وPurchase ID صالح؛ pending/error لا تمنح Credits، وrestored consumables مرفوضة. `ProService` يمثل expiry/Lifetime محليًا ويحفظ SHA-256 fingerprint لمرجع Google Play دون حفظ المرجع الخام.

## اقتصاد Credits

إزالة الخلفية 1، shadow 1، enhance 2، conversational/inpaint 3، compliance 0، export 0. لا تخصم العملية قبل نجاحها، ولا تُسجل نتيجة فاشلة كنجاح.

## Free quota وRestore المحلي

يحتفظ التطبيق بعداد دائم مستقل عن Credits لثلاث صور مجانية في كل شهر UTC. عند تحميل شهر جديد يُصفّر العداد تلقائيًا، ولا يسمح العداد بطلبات صفرية أو تتجاوز الحد. يظهر المتبقي في Paywall. أصبح العداد مربوطًا بمسار PatchMatch في Editor وChat، ويُستهلك بعد نجاح الناتج فقط.

عند بدء جلسة Billing يطلب التطبيق `restorePurchases`. أحداث restored للمنتجات الاستهلاكية تُرفض ولا تمنح Credits، بينما Lifetime يمكن حفظه محليًا بعد وجود `serverVerificationData` غير فارغ. فشل Restore لا يمسح entitlement محليًا، لأن التطبيق يعمل Local-first، لكن إعادة فحص الإبطال/الاسترداد الفوري تتطلب توفر Google Play.

## PatchMatch المحلي للمجاني

يستخدم مسار `removeBackground` في Android الآن `PatchMatchRemover` محليًا بدل `floodRemove` وحده. يبدأ المسار ببذور زوايا الصورة، يبني قناعًا متصلًا محافظًا للخلفية، ثم يحسن مراجع الرقع عبر propagation وrandom search لرقع 3×3، ويصدر PNG بخلفية شفافة. لا يحتاج هذا المسار شبكة أو نموذجًا خارجيًا. يسمح Free بهذا المسار فقط؛ وبعد نجاحه يطبق `FreeWatermarkService` علامة `PRODUCTCHAT STUDIO  •  FREE` قبل استهلاك الحصة. توجد fixtures واختبارات أبعاد/PNG، بينما alpha quality وAndroid runtime ما زالت متبقية.

## Billing v2 المطلوب

- إضافة المنتج السادس `lifetime` بعد Play Console.
- إنشاء `ProStatus` و`ProService` مع `isPro`, `isLifetime`, `expiry`, `daysRemaining`.
- حفظ `proExpiry` بصيغة ISO8601، auto-expiry للاشتراكات، وعدم انتهاء Lifetime.
- Paywall بثلاثة أقسام: Lifetime وSubscriptions وCredits.
- Settings يعرض حالة Pro وRestore، وBatch يملك Pro Gate، وHistory يطبق سياسة آخر 5 للمجاني/الكامل لـPro بعد تثبيت storage والسياسة.
- عدم grant لمنتج subscription أو restored consumable محليًا.
- عدم استخدام fallback price كسعر مؤكد؛ السعر الظاهر يجب أن يأتي من Google Play عندما يتوفر.
- عدم إعلان «كل النماذج» بما يشمل MI-GAN غير المرخص أو Real-ESRGAN غير الموصول.

## قرار Local-first

لا يستخدم الإصدار الحالي Firebase أو Supabase أو Cloud Functions أو Backend SaaS. يعتمد التطبيق على Google Play Billing و`restorePurchases` ومرجع `serverVerificationData` الذي توفره مكتبة Billing، ثم يحفظ بصمة SHA-256 محلية فقط. هذا يمنع التكرار والأخطاء العادية ويحافظ على Lifetime بعد الاستعادة، لكنه لا يساوي تحققًا خادميًا مستقلًا ولا يمنع APK معدلًا.

يُعاد فحص Google Play عند الشراء والاستعادة وعند فتح التطبيق متى كان Billing متاحًا. إذا لم توجد عملية Lifetime صالحة في نتائج Google Play، يُزال entitlement المحلي. لا يُستخدم Email وحده كمصدر ملكية ولا يُحفظ Purchase Token الخام.

## الحالة والتحقق

| Check | Result |
|---|---|
| Product IDs الثلاثة للـCredits والاشتراكان | موثقة/مفعلة وفق سجلات Play السابقة |
| Lifetime product | Pending — إجراء Play Console بشري |
| Local purchase stream/ledger | موجود جزئيًا؛ يحتاج إعادة تشغيل tests على آخر commit |
| ProService/ProEntitlement | غير منفذ في التطبيق الحالي حسب الأدلة المتاحة |
| Sandbox/Test Card | Pending device وLicense Tester |
| Receipt/server verification | مستبعد في الإصدار Local-first؛ خيار مستقبلي فقط |
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
