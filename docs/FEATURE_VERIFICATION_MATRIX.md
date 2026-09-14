# Feature verification matrix

**آخر تحقق:** 2026-09-13  
**Application commit before P1:** `fb20f125134d381bbc655883008a4f214aebde74`  
**P1 evidence:** [`P1_BUILD_VALIDATION.md`](P1_BUILD_VALIDATION.md)

## حالات التحقق

- **Source:** يوجد تنفيذ أو artifact في المصدر.
- **Wired:** يوجد مسار UI/controller إلى الخدمة أو الجسر.
- **Executable:** لا يعتمد على stub ويُنتج السلوك المتوقع.
- **Automated:** يوجد اختبار آلي مناسب.
- **Android verified:** تم البناء والتشغيل على Android.
- **Release ready:** اجتاز الأداء والخصوصية والترخيص والدفع والتوقيع عند الحاجة.

| Feature ID | Source | Source | Wired | Executable | Automated | Android verified | Release ready | Evidence / gap |
|---|---|---:|---:|---:|---:|---:|---:|---|
| `models.lama` | `model_manager.dart`, `constants.dart` | نعم | جزئي | جزئي | جزئي | لا | لا | Download/checksum موجودان؛ UI وruntime غير مثبتين |
| `models.realesrgan` | `constants.dart`, HF artifact | نعم | لا | لا | لا | لا | لا | artifact `.pth`؛ `runEsrgan` يعيد `null` |
| `models.migan` | constants/card | جزئي | لا | لا | لا | لا | لا | غير موجود قانونيًا/تقنيًا |
| `analysis.smart` | `smart_analysis_service.dart` | نعم | نعم | نعم | جزئي | لا | لا | اختبار invalid path فقط؛ لا توجد image fixtures كافية |
| `edit.inpaint` | `seika_service.dart`, `SeikaChannel.kt` | نعم | نعم | جزئي | جزئي | لا | لا | Named LaMa inputs/output guards added; native runtime still unverified |
| `edit.remove_background` | `SeikaChannel.kt` | نعم | نعم | جزئي | لا | لا | لا | fast path flood fallback؛ الجودة غير مقيسة |
| `edit.upscale` | `SeikaChannel.kt` | نعم | نعم | جزئي | لا | لا | لا | Bitmap fallback؛ Real-ESRGAN غير منفذ |
| `edit.shadow` | `SeikaChannel.kt` | نعم | نعم | جزئي | لا | لا | لا | compositing baseline بلا اختبار |
| `edit.export` | `SeikaChannel.kt`, editor UI | نعم | جزئي | جزئي | لا | لا | لا | contract موجود؛ end-to-end غير مثبت |
| `editor.state` | `editor_controller.dart`, `ai_service.dart` | نعم | نعم | جزئي | جزئي | لا | لا | Stub removed; operations return explicit `EditResult`; native runtime still unverified |
| `batch.basic` | `batch_service.dart`, `batch_screen.dart` | نعم | نعم | جزئي | لا | لا | لا | ينسخ الملفات إلى temp ولا يطبق editing pipeline |
| `storage` | `storage_service.dart` | نعم | لا | لا | لا | لا | لا | Map في الذاكرة فقط |
| `billing` | `billing_service.dart`, `paywall_screen.dart`, dependency | نعم | نعم | جزئي | جزئي | لا | Purchase stream وledger idempotent واختبارات الرصيد موجودة؛ Play Console products وSandbox وreceipt verification غير منفذة |
| `chat` | `chat_controller.dart`, `chat_screen.dart` | نعم | نعم | جزئي | لا | لا | لا | يحتاج فحص flow وصور ونتائج حقيقية |
| `onboarding` | `onboarding_screen.dart` | نعم | لا | لا | لا | لا | لا | `Feature scaffold` |
| `settings` | settings screens | نعم | لا | لا | لا | لا | لا | عدة شاشات نصية/Scaffold |
| `history` | `history_screen.dart` | نعم | لا | لا | لا | لا | لا | نص فقط وتخزين غير موجود |
| `compliance` | `compliance_service.dart`, screen | نعم | جزئي | جزئي | لا | لا | لا | قائمة منصات ثابتة؛ UI scaffold |
| `localization` | `app_en.arb`, `app_ar.arb` | نعم | جزئي | جزئي | لا | لا | لا | لغتان ظاهرتان؛ RTL/overflow غير مختبر |
| `android.build` | Android files | نعم | نعم | نعم | نعم | لا | لا | `targetSdk=36`؛ Workflow `34796595278` بنى AAB Release موقعًا بحجم 79.1 MB بعد نجاح analyze/test وR8؛ INTERNET في main Manifest؛ يلزم اختبار جهاز ورفع Internal Testing |
| `privacy.terms` | feature files | جزئي | لا | لا | لا | لا | لا | لا توجد سياسة مكتملة داخل المسار المنتج |

## Rules for updates

بعد كل تغيير، حدّث الأعمدة فقط بناءً على دليل جديد، وأضف:

- test name/path أو command.
- commit.
- جهاز Android وOS إذا كان التحقق ميدانيًا.
- limitation أو fallback صريح.

لا تستخدم `Yes` لمجرد أن dependency أو screen موجودة.
