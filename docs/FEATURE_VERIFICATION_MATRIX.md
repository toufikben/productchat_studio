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
| `edit.remove_background` | نعم | نعم | جزئي | لا | لا | لا | flood fallback أو LaMa quality غير مقيسة |
| `edit.upscale` | نعم | نعم | جزئي | لا | لا | لا | bounded Bitmap fallback |
| `edit.shadow` | نعم | نعم | جزئي | لا | لا | لا | compositing baseline بلا device test |
| `edit.export` | نعم | جزئي | جزئي | لا | لا | لا | contract موجود؛ E2E pending |
| `editor.state` | نعم | نعم | جزئي | جزئي | لا | لا | history/undo/state؛ output runtime pending |
| `batch` | نعم | نعم | جزئي | لا | لا | لا | UI/progress؛ pipeline يحتاج ربطًا بعمليات التحرير |
| `storage` | نعم | جزئي | جزئي | جزئي | لا | لا | handoff يذكر SharedPreferences، والمواصفة المرفقة تقترح Hive؛ القرار الفعلي pending |
| `billing.local` | نعم | نعم | جزئي | جزئي | لا | لا | Credits IDs وstream وlocal ledger؛ لا trusted backend |
| `billing.v2.catalog` | نعم | نعم | جزئي | Pending | لا | لا | IDs الستة وLifetime non-consumable وPaywall sections مضافة؛ Play Console/backend pending؛ الاختبار لم يُشغل لغياب Flutter |
| `pro.entitlement` | نعم | جزئي | جزئي | Pending | لا | لا | `ProService` المحلي يدعم expiry/Lifetime/persistence؛ ليس server-authoritative بعد؛ الاختبار لم يُشغل |
| `free.tier` | مواصفة فقط | لا | لا | لا | لا | لا | 3 صور/شهر، PatchMatch، watermark مطلوبة ولم تُثبت |
| `lifetime` | مواصفة فقط | لا | لا | لا | لا | لا | منتج one-time غير منشأ وفق الأدلة المتاحة |
| `chat` | نعم | نعم | جزئي | لا | لا | لا | يحتاج E2E image/mask/dispatch/result |
| `history` | جزئي | جزئي | جزئي | لا | لا | لا | نص/تنفيذ مقترح؛ policy Free آخر 5 تحتاج إثباتًا |
| `settings` | جزئي | جزئي | جزئي | لا | لا | لا | locale/theme وبعض wiring؛ Pro/restore v2 pending |
| `onboarding` | نعم | لا | لا | لا | لا | لا | scaffold أو غير موصول وفق الأدلة السابقة |
| `compliance` | جزئي | جزئي | جزئي | لا | لا | لا | قائمة ثابتة وUI غير مكتمل |
| `localization` | نعم | جزئي | جزئي | لا | لا | لا | العربية/الإنجليزية؛ الهدف 16 غير محسوم |
| `privacy.terms` | جزئي | جزئي | جزئي | لا | لا | لا | route/مواد موجودة جزئيًا؛ policy/flow يحتاج مراجعة |
| `receipt.verification` | لا | لا | لا | لا | لا | لا | API/Google Developer API/ledger/RTDN غير منفذة |
| `p8.performance` | بروتوكول فقط | لا | لا | لا | لا | لا | runtime measurements pending device/emulator |

## Billing v2 acceptance evidence

لا تُرفع حالات `free.tier` أو `pro.entitlement` أو `lifetime` إلى Yes إلا بعد اختبار ProService، purchase stream، restore، expiry، gates، وPlay evidence. لا تُمنح Credits نهائيًا من callback محلي فقط بعد اعتماد Receipt Verification.

لكل تحديث يجب تسجيل: test path/name، command، commit، device/OS عند التحقق الميداني، limitations، وfallback.
