# Feature verification matrix

**آخر تحديث:** 2026-09-14
**مرجع الحالة:** `main`؛ يجب إضافة commit/device لكل تحقق جديد.

## معاني الأعمدة

- **Source:** يوجد تنفيذ أو artifact.
- **Wired:** يوجد مسار فعلي من UI/controller إلى الخدمة أو الجسر.
- **Executable:** لا يعتمد على stub ويُنتج السلوك المتوقع أو فشلًا صريحًا.
- **Automated:** يوجد اختبار آلي مناسب.
- **Android verified:** بُني وشُغّل على جهاز/Emulator مع evidence.
- **Release ready:** اجتاز runtime/performance/privacy/license/billing/signing عند الحاجة.

| Feature ID | Source | Wired | Executable | Automated | Android verified | Release ready | Evidence / gap |
|---|---:|---:|---:|---:|---:|---:|---|
| `build.android` | نعم | نعم | نعم | نعم وفق السجلات السابقة | لا | لا | Flutter 3.47.4/SDK 36/AAB evidence؛ إعادة التحقق من آخر commit مطلوبة |
| `models.lama` | نعم | جزئي | جزئي | جزئي | لا | لا | Model Manager/checksum وSeika source؛ لا device inference |
| `models.realesrgan` | نعم | لا | لا | لا | لا | لا | `.pth` فقط؛ Basic fallback، لا Real-ESRGAN runtime |
| `models.migan` | جزئي | لا | لا | لا | لا | لا | لا weights بسبب الترخيص |
| `analysis.smart` | نعم | نعم | نعم | جزئي | لا | لا | يحتاج fixtures واختبار جودة الترتيب |
| `edit.inpaint` | نعم | نعم | جزئي | جزئي | لا | لا | LaMa contract وEditResult؛ native runtime/mask/output pending |
| `edit.remove_background` | نعم | نعم | جزئي | Pending | لا | لا | PatchMatch Android محلي، Free watermark، fixtures وquality checks مضافة؛ device runtime pending |
| `edit.upscale` | نعم | نعم | جزئي | لا | لا | لا | bounded Bitmap fallback |
| `edit.shadow` | نعم | نعم | جزئي | لا | لا | لا | compositing baseline بلا device test |
| `edit.export` | نعم | جزئي | جزئي | لا | لا | لا | contract موجود؛ E2E pending |
| `editor.state` | نعم | نعم | جزئي | جزئي | لا | لا | history/undo/state؛ output runtime pending |
| `batch` | نعم | نعم | جزئي | Pending | لا | لا | Pro/Lifetime gate و100-image limit وprogress؛ pipeline ما زال ينسخ الملفات بدل تطبيق التحرير |
| `brand.identity` | نعم | نعم | نعم | Pending | لا | لا | Pro/Lifetime gate وlocal persistence وUI مضافة؛ لا device/widget evidence |
| `storage` | نعم | جزئي | جزئي | جزئي | لا | لا | handoff يذكر SharedPreferences، والمواصفة المرفقة تقترح Hive؛ القرار الفعلي pending |
| `billing.local` | نعم | نعم | جزئي | Pending | لا | لا | Credits IDs وstream وlocal ledger وrestore عند init؛ الاختبارات لم تُشغل لغياب Flutter |
| `billing.v2.catalog` | نعم | نعم | جزئي | Pending | لا | لا | IDs الستة وLifetime non-consumable وPaywall sections مضافة؛ Play Console/backend pending؛ الاختبار لم يُشغل لغياب Flutter |
| `pro.entitlement` | نعم | جزئي | جزئي | Pending | لا | لا | `ProService` المحلي يدعم expiry/Lifetime/persistence؛ ليس server-authoritative بعد؛ الاختبار لم يُشغل |
| `free.tier` | نعم | نعم | جزئي | Pending | لا | لا | PatchMatch gate وwatermark وquota-after-success في Editor/Chat؛ alpha/device tests متبقية |
| `lifetime` | مواصفة فقط | لا | لا | لا | لا | لا | منتج one-time غير منشأ وفق الأدلة المتاحة |
| `chat` | نعم | نعم | جزئي | لا | لا | لا | يحتاج E2E image/mask/dispatch/result |
| `history` | نعم | نعم | نعم | Pending | لا | لا | durable local entries؛ Free latest 5 وPro/Lifetime full history؛ اختبار مضاف ولم يُشغل لغياب Flutter |
| `settings` | نعم | نعم | جزئي | Pending | لا | لا | Pro/Lifetime status وexpiry وRestore وروابط المسارات؛ device/Flutter test pending |
| `onboarding` | نعم | لا | لا | لا | لا | لا | scaffold أو غير موصول وفق الأدلة السابقة |
| `compliance` | جزئي | جزئي | جزئي | لا | لا | لا | قائمة ثابتة وUI غير مكتمل |
| `localization` | نعم | جزئي | جزئي | لا | لا | لا | العربية/الإنجليزية؛ الهدف 16 غير محسوم |
| `privacy.terms` | جزئي | جزئي | جزئي | لا | لا | لا | route/مواد موجودة جزئيًا؛ policy/flow يحتاج مراجعة |
| `receipt.verification` | نعم | نعم | جزئي | Pending | لا | لا | المسار المحلي يحفظ SHA-256 fingerprint لمرجع Billing ولا يحفظ Token الخام؛ Backend وGoogle Developer API مستبعدان حاليًا |
| `p8.performance` | بروتوكول فقط | لا | لا | لا | لا | لا | runtime measurements pending device/emulator |

## Billing v2 acceptance evidence

لا تُرفع حالات `free.tier` أو `pro.entitlement` أو `lifetime` إلى Yes إلا بعد اختبار ProService، purchase stream، restore، expiry، gates، وPlay evidence. لا تُمنح Credits نهائيًا من callback محلي فقط بعد اعتماد Receipt Verification.

لكل تحديث يجب تسجيل: test path/name، command، commit، device/OS عند التحقق الميداني، limitations، وfallback.
