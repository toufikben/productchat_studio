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
| `build.android` | نعم | نعم | نعم | نعم وفق السجلات السابقة | لا | لا | Flutter 3.47.4/SDK 36؛ Release CI يبني AAB وAPK؛ إعادة التحقق من آخر commit مطلوبة |
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
| `batch` | نعم | نعم | نعم | Pending | لا | لا | Pro/Lifetime gate و100-image limit وAiService processing وHistory؛ native runtime/performance pending |
| `brand.identity` | نعم | نعم | نعم | Pending | لا | لا | Pro/Lifetime gate وlocal persistence وUI مضافة؛ لا device/widget evidence |
| `storage` | نعم | نعم | جزئي | Pending | لا | لا | SharedPreferences versioned metadata؛ Credits/quota/Pro migration وrestart verification pending |
| `billing.local` | نعم | نعم | جزئي | Pending | لا | لا | Credits IDs وstream وlocal ledger وrestore عند init؛ الاختبارات لم تُشغل لغياب Flutter |
| `billing.v2.catalog` | نعم | نعم | جزئي | Pending | لا | لا | IDs الستة وLifetime non-consumable وPaywall sections مضافة؛ Play Console/backend pending؛ الاختبار لم يُشغل لغياب Flutter |
| `pro.entitlement` | نعم | جزئي | جزئي | Pending | لا | لا | `ProService` المحلي يدعم expiry/Lifetime/persistence؛ ليس server-authoritative بعد؛ الاختبار لم يُشغل |
| `free.tier` | نعم | نعم | جزئي | Pending | لا | لا | PatchMatch gate وwatermark وquota-after-success في Editor/Chat؛ alpha/device tests متبقية |
| `lifetime` | مواصفة فقط | لا | لا | لا | لا | لا | منتج one-time غير منشأ وفق الأدلة المتاحة |
| `chat` | نعم | نعم | جزئي | لا | لا | لا | يحتاج E2E image/mask/dispatch/result |
| `history` | نعم | نعم | نعم | Pending | لا | لا | versioned bounded entries، latest 5/full history، delete/clear يحذف المخرجات المتاحة؛ اختبار مضاف ولم يُشغل لغياب Flutter |
| `settings` | نعم | نعم | جزئي | Pending | لا | لا | Pro/Lifetime status وexpiry وRestore وروابط المسارات؛ device/Flutter test pending |
| `onboarding` | نعم | نعم | جزئي | لا | لا | لا | Getting started content and route added; no persistence/widget evidence |
| `recipes` | نعم | نعم | جزئي | لا | لا | لا | Local editing recipes and route added; action automation remains future work |
| `compliance` | نعم | نعم | جزئي | لا | لا | لا | Review checklist and UI are present; legal certification and platform-specific runtime verification are not claimed |
| `localization` | نعم | جزئي | جزئي | لا | لا | لا | العربية/الإنجليزية؛ الهدف 16 غير محسوم |
| `privacy.terms` | نعم | نعم | جزئي | لا | لا | لا | local-only processing، versioned metadata، وdelete semantics موثقة؛ legal review خارجي متبقٍ |
| `faq.support.models` | نعم | نعم | جزئي | لا | لا | لا | FAQ, support guidance, and model capability screens added and linked from Settings |
| `receipt.verification` | نعم | نعم | جزئي | Pending | لا | لا | المسار المحلي يحفظ SHA-256 fingerprint لمرجع Billing ولا يحفظ Token الخام؛ Backend وGoogle Developer API مستبعدان حاليًا |
| `p8.performance` | بروتوكول فقط | لا | لا | لا | لا | لا | runtime measurements pending device/emulator |

## Billing v2 acceptance evidence

لا تُرفع حالات `free.tier` أو `pro.entitlement` أو `lifetime` إلى Yes إلا بعد اختبار ProService، purchase stream، restore، expiry، gates، وPlay evidence. لا تُمنح Credits نهائيًا من callback محلي فقط بعد اعتماد Receipt Verification.

لكل تحديث يجب تسجيل: test path/name، command، commit، device/OS عند التحقق الميداني، limitations، وfallback.
