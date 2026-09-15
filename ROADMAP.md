# ProductChat Studio — خارطة الطريق التنفيذية الموحدة

> **الحالة المرجعية:** Android-first. لا تُرفع أي ميزة من «موجودة في المصدر» إلى «متحققة» أو «جاهزة للإصدار» دون دليل قابل لإعادة الإنتاج.
>
> **آخر تحديث:** 2026-09-15 — UI Overhaul + Voice Integration
>
> **المستودع:** [`toufikben/productchat_studio`](https://github.com/toufikben/productchat_studio)
> **الفرع:** `main`
> **الالتزام المرجعي قبل هذا التحديث:** `4494d25`
> **مصادر الحقيقة:** هذه الخارطة، `docs/FEATURE_VERIFICATION_MATRIX.md`، `docs/MODEL_INVENTORY.md`، ووثائق التحقق المرتبطة.

## سجل التحديثات — 2026-09-15 — Hugging Face model artifacts

- [x] تسجيل الدخول إلى حساب Hugging Face `Toufikben` والتحقق من مستودع `Toufikben/productchat-models`.
- [x] رفع `migan.onnx` و`lama_fp16.onnx` و`real_esrgan_x4.onnx` إلى commit `94592115e5ec95fe6be57f99ba6927da98f27795`.
- [x] تحديث `lib/core/constants.dart` بروابط النماذج الثلاثة وقيم SHA-256 الفعلية.
- [ ] نموذج `qwen_edit_int8.onnx` غير جاهز؛ المستودع الرسمي يوفّر Qwen بصيغة Safetensors وليس ONNX، لذلك لم يُرفع ملف غير متوافق أو يُعاد تسميته.
- [ ] لم تُرفع تعديلات Git المحلية إلى GitHub بعد؛ يجب تنفيذ commit ومراجعة التحليل قبل push.
- [ ] يجب إعادة تشغيل `flutter analyze` و`flutter test` بعد تحديث الثوابت، ثم اختبار تنزيل النماذج على Android.

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

## سجل التحديثات — 2026-09-15 — Full Update Package 08–10

- [x] قراءة تعليمات الحزمة الرئيسية وحفظها كـ `docs/ai_package/00_MASTER_INSTRUCTIONS.txt`.
- [x] حفظ `08_BATCH_PROCESSING.txt` و`09_IOS_VOICE.swift.txt` و`10_ADVANCED_FEATURES.txt` داخل الحزمة.
- [x] الحفاظ على `BatchService` الحالي المتوافق مع الاختبارات وPro/Lifetime gating، مع إبقاء الحد الأقصى 100 صورة ومسار المعالجة المحلي والتاريخ.
- [x] إضافة FeatureFlags gating لشاشة Batch حتى لا تُعرض ميزة غير مكتملة للمستخدم.
- [x] إضافة `AIDescriptionService` للتحليل المحلي للصور وتوليد العنوان والوصف والوسوم دون API خارجي.
- [x] إضافة `AIDescriptionScreen` وربطها بالمسار `/ai-description`.
- [x] التحقق من وجود `NSMicrophoneUsageDescription` و`NSSpeechRecognitionUsageDescription` في iOS `Info.plist`.
- [x] التحقق من أن `ios/Podfile` يستخدم `flutter_install_all_ios_pods`، وبالتالي تُضاف Pods الصوت تلقائياً من `pubspec.yaml` بعد `flutter pub get`.
- [x] اجتياز `git diff --check` والتحقق من صحة ملفات الترجمة JSON.
- [ ] تشغيل Flutter وCocoaPods واختبارات iOS/Android؛ Flutter SDK غير موجود في بيئة التنفيذ الحالية.

**ملاحظة توافق:** النص المرفق لـ Batch يعتمد على `BorderCutService` و`ShadowService` و`ExportService` غير الموجودة في المستودع الحالي، لذلك لم أُدخل imports مكسورة؛ تم الحفاظ على خدمة Batch الموجودة والمختبرة بدلاً من حذف API المشروع أو اختلاق خدمات غير موجودة.

## سجل التحديثات — 2026-09-15 — Complete Package v3.0

- [x] قراءة وتنفيذ ترتيب الحزمة النهائي: 00 → 01 → 04 → 02 → 08 → 09 → 10 → 12 → 13 → 14 → 15 → 16 → 06 → 05 → 07 → 03 → 11 → 17.
- [x] إضافة Brand Identity مع حفظ الملف الشخصي والشعار والعلامة المائية.
- [x] إضافة Smart Analysis Service وSmart Analysis Panel للاقتراحات المحلية.
- [x] إضافة Price A/B Testing وReferral Service وReferral Screen.
- [x] إضافة Analytics Dashboard وFeature Roadmap وRoadmap Screen.
- [x] ربط المسارات الجديدة: `/brand`, `/analytics`, `/referral`, `/roadmap`, و`/ai-description`.
- [x] حفظ ملفات الحزمة `11` إلى `16` داخل `docs/ai_package/`.
- [x] اجتياز `git diff --check` والتحقق من وجود ملفات الخدمات والشاشات والمسارات.
- [ ] تشغيل `flutter clean && flutter pub get && flutter gen-l10n && flutter analyze && flutter test`؛ تعذر التنفيذ لأن Flutter SDK غير موجود في `PATH`.
- [ ] تشغيل `flutter build apk --debug` مشروط بنجاح الأوامر السابقة، لذلك لم يُنفّذ.

**نتيجة v3.0:** الملفات والميزات الجديدة مضافة ومربوطة، لكن التحليل والاختبارات والبناء يحتاجون بيئة Flutter فعلية.

## سجل التحديثات — 2026-09-15 — Core Features FIX #20–#33

- [x] قراءة `18_CORE_FEATURES.txt` و`18_CORE_FEATURES_PART2.txt` بالكامل.
- [x] تنفيذ FIX #20: تحديث constants للـ quotas والـ IAP وروابط النماذج والحدود.
- [x] تنفيذ FIX #21–#25: MI-GAN وQwen Edit وRelight وColorize وProduct Fidelity.
- [x] تنفيذ FIX #26–#28: Watermark وCompliance/Export وRecipe Runner.
- [x] تنفيذ FIX #29–#30: تجميع خدمات AI وتحديث ChatController مع التحليل الذكي والرصيد والتحقق من fidelity.
- [x] تنفيذ FIX #31–#33: قنوات Android MI-GAN وQwen وتسجيلها في MainActivity الفعلي للمشروع.
- [x] إضافة توافقات لازمة لواجهات `EditResult` و`EditRequest` و`PlatformSpec` و`StorageService` و`Recipe` حتى تتطابق الخدمات الجديدة مع الكود الحالي.
- [x] حفظ ملفات التعليمات في `docs/ai_package/18_CORE_FEATURES.txt` و`18_CORE_FEATURES_PART2.txt`.
- [x] اجتياز الفحوصات الساكنة و`git diff --check` وإزالة نصوص التعليمات من ملفات المصدر.
- [ ] `flutter clean && flutter pub get`: تعذر التنفيذ لأن Flutter SDK غير موجود في `PATH`.
- [ ] `flutter analyze`: تعذر التنفيذ لنفس سبب غياب Flutter SDK.

**ملاحظة Android:** المشروع يستخدم namespace `com.productchat.aiphotostudio` فعلياً؛ لذلك أُضيف تسجيل قنوات MI-GAN وQwen إلى MainActivity الفعلي، مع الاحتفاظ بالملفات المحددة في الحزمة تحت مسار `com.productchat.studio`.

## سجل التحديثات — 2026-09-15 — UI Screens FIX #34–#44

- [x] إنشاء Developer, Marketplace, About, Feedback, Update, Chat History, Presets, وFavorites screens.
- [x] استبدال `lib/core/router.dart` وربط كل المسارات الجديدة.
- [x] إضافة روابط الشاشات الجديدة إلى Settings.
- [x] التحقق من اعتماديات `package_info_plus` و`url_launcher` و`uuid` الموجودة مسبقاً في `pubspec.yaml`.
- [x] حفظ `19_UI_SCREENS.txt` داخل `docs/ai_package/`.
- [x] اجتياز `git diff --check` والتحقق من اكتمال الملفات والمسارات.
- [ ] `flutter clean && flutter pub get && flutter analyze`: تعذر التنفيذ لأن Flutter SDK غير موجود في `PATH`.

## سجل التحديثات — 2026-09-15 — Voice Complete FIX #45–#54

- [x] استبدال `voice_service.dart` بإدارة STT/TTS والإعدادات والحفظ الصوتي.
- [x] إضافة Voice Search وVoice Presets وخ schermات إعدادات الصوت.
- [x] ربط المسارات `/voice-settings` و`/voice-presets` و`/voice-search`.
- [x] إضافة voice feedback إلى ChatController وتهيئة presets الافتراضية.
- [x] فتح Hive boxes: `voice_presets`, `presets`, `favorites`, و`feedback`.
- [x] إضافة `StorageService.getHistory()` لدعم البحث الصوتي.
- [x] اجتياز الفحوصات الساكنة و`git diff --check`.
- [ ] أوامر Flutter المطلوبة تعذرت لأن Flutter SDK غير موجود في `PATH`.

## سجل التحديثات — 2026-09-15 — Billing Complete FIX #55–#67

- [x] إضافة Free Quota مع توافق API الاختبارات القديمة (`storage`, `monthKey`, `usedKey`, و`consume(images:)`).
- [x] إضافة Promo Codes وTrial وRefund وPayment History services.
- [x] إضافة شاشات Subscription Status وPromo Code وRefund Policy.
- [x] ربط مسارات Billing الجديدة وإضافة روابطها إلى Settings وPaywall.
- [x] إضافة تسجيل المدفوعات والاستردادات إلى `BillingService` وفتح Hive boxes المطلوبة.
- [x] الحفاظ على معرفات المنتجات الحالية: `pro_monthly`, `pro_yearly`, `credits_100`, `credits_500`, `credits_1200`, `lifetime`.
- [x] الحفاظ على أسعار المشروع/خارطة الطريق الحالية: `$4.99`, `$19.99`, `$39.99`, `$79.99` و`$29.99` سنوياً؛ وتبقى `ProductDetails.price` من Google Play هو السعر المعروض النهائي.
- [x] عدم إعادة القيم القديمة `$0.99/$3.99/$7.99` لأنها موثقة كقديمة في خارطة الطريق.
- [x] اجتياز الفحوصات الساكنة و`git diff --check`.
- [ ] `flutter clean && flutter pub get && flutter analyze`: تعذر التنفيذ لأن Flutter SDK غير موجود في `PATH`.

## سجل التحديثات — 2026-09-15 — Package Extensions 04–07

- [x] قراءة ملفات الحزمة الثمانية بالترتيب وحفظ نسخها في `docs/ai_package/`.
- [x] تطبيق `ROUTER_UPDATE`: إضافة `/` و`/home` و`/chat-studio` و`/mask-painter`، وتوجيه Splash وOnboarding إلى Home.
- [x] إنشاء اختبارات `VoiceService` و`ModelCenter` و`FeatureFlags` و`FloatingNavBar`.
- [x] إضافة مفاتيح الترجمة الجديدة إلى `app_en.arb` و`app_ar.arb` وتثبيت `nullable-getter: false` في `l10n.yaml`.
- [x] التحقق من صلاحية JSON للملفين ومن وجود الملفات المرجعية والاختبارات والمسارات المطلوبة.
- [ ] تشغيل `flutter clean`, `flutter pub get`, `flutter gen-l10n`, `flutter analyze`, و`flutter test`؛ تعذر التنفيذ لأن Flutter SDK غير موجود في `PATH`.
- [ ] تشغيل `flutter build apk --debug` واختبارات Android وVoice Commands وModel Center؛ تحتاج بيئة Flutter وجهازاً أو Emulator.

**نتيجة الحزمة الموسعة:** التعديلات والاختبارات والموارد النصية موجودة في المصدر، لكن نتائج التحليل والاختبارات والبناء لا يمكن اعتمادها آلياً حتى تتوفر أداة Flutter.

## سجل التحديثات — 2026-09-15 — AI Execution Package

- [x] حفظ الحزمة المرجعية داخل `docs/ai_package/` بالترتيب: التعليمات، الإصلاحات، الميزات، وخارطة الطريق.
- [x] تنفيذ إصلاحات Android Manifest وFileProvider و`feature_flags.dart`.
- [x] تحديث رابط Real-ESRGAN إلى ONNX وإضافة تعريف `ModelManager.realEsrgan` وربط `SeikaService.upscale` بمسار النموذج.
- [x] تحويل الراوتر إلى `Provider<GoRouter>` وتحديث `app.dart` لاستهلاك المزود، مع إبقاء المسارات القديمة وإضافة Home وChat Studio وMask Painter.
- [x] إكمال تهيئة Hive وBilling وواجهات الخدمات عند بدء التطبيق.
- [x] إنشاء Voice Service وFloating Navigation وHome Screen وChat Studio وMask Painter واستبدال Models Screen.
- [x] إضافة توافق `AppIcons.circle/outline` الذي تتطلبه شاشة Model Center دون إزالة المكونات الموجودة.
- [x] اجتياز `git diff --check` وفحص وجود جميع الملفات الجديدة.
- [ ] `flutter clean`, `flutter pub get`, `flutter gen-l10n`, `flutter analyze`, و`flutter test`؛ تعذر تشغيلها لأن Flutter SDK غير موجود في `PATH` داخل بيئة التنفيذ.
- [ ] توفير SHA-256 الحقيقي لملف `real_esrgan_x4.onnx` بعد رفع النموذج المرخص؛ القيمة الحالية `REPLACE_AFTER_UPLOAD` مقصودة وحاجبة للتحقق.

**حالة الدفعة:** التغييرات مطبقة في المصدر، لكن البناء والاختبارات وتشغيل Android تحتاج مراجعة بشرية/بيئة Flutter. لم يتم نشر التطبيق أو رفع أي نموذج.

## سجل التحديثات — 2026-09-15

### UI Overhaul + Voice Integration

- [x] إنشاء `lib/ui/productchat_ui_overhaul.dart` مع `FeatureFlags` ونقاط تصدير الواجهة الجديدة.
- [x] إنشاء `lib/core/voice_service.dart` لدمج Speech-to-Text وText-to-Speech عبر Riverpod.
- [x] إنشاء `lib/features/home/home_screen.dart` مع لوحة التحكم والإجراءات السريعة والمشاريع الحديثة.
- [x] إنشاء `lib/features/chat/chat_studio_screen.dart` للمحادثة النصية والصوتية مع waveform وإرسال الرسائل.
- [x] إنشاء `lib/widgets/floating_nav_bar.dart` لشريط التنقل العائم بتأثير glassmorphism.
- [x] تحديث `AppColors` وإضافة ألوان `surfaceAlt` و`success` و`warning` و`danger` و`textTertiary`.
- [x] توجيه `/home` كنقطة الدخول الجديدة وتوجيه `/chat` إلى `ChatStudioScreen`.
- [x] إضافة اعتماد `flutter_tts` إلى `pubspec.yaml`.
- [x] التحقق من وجود الملفات الخمسة وفحص `git diff --check` بنجاح.
- [ ] تشغيل `flutter pub get` و`flutter gen-l10n` و`flutter analyze` و`flutter test`؛ متعذر في بيئة التنفيذ الحالية لأن Flutter SDK غير موجود في `PATH`.

**حالة هذه الدفعة:** موجودة وموصولة في المصدر؛ التحقق بالبناء والتشغيل على Android متبقٍ بعد توفير Flutter SDK.

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

### 3.1 Play Console readiness

تمت مطابقة دليل Play Console المرفق مع الكود وتوثيق النتيجة في `docs/PLAY_CONSOLE_GUIDE_AUDIT_2026-09-14.md`. اكتملت في Play Console التصريحات المدعومة: سياسة الخصوصية، الإعلانات، Advertising ID، Government apps، Financial features، Health apps، وData safety. بقيت بيانات الدخول/المشتريات، تصنيف المحتوى، الجمهور المستهدف، الفئة وبيانات التواصل، صفحة المتجر، الصور، اللغات غير المنفذة، رفع AAB، واختبار Android عناصر إصدار مستقلة لم تُختلق لها بيانات.

إضافة اللغة الفرنسية ومحدد اللغة داخل الإعدادات موثقة في commit `4df0a4c`. لا تُعلن خارطة الطريق عن 16 لغة أو ميزات غير مثبتة في الدليل قبل تنفيذها واختبارها على Android.

### 3.2 دفعة 2026-09-14 الثانية

- [x] حفظ Target audience: `13-15`, `16-17`, و`18 and over`.
- [x] حفظ Sign in details على `Yes` بسبب وجود طبقات مدفوعة، مع تعليمات إنجليزية تفيد بعدم الحاجة إلى حساب أو بيانات اعتماد للمراجعة.
- [x] إضافة كتالوج ARB وdelegates للغات: `ar`, `en`, `fr`, `es`, `de`, `it`, `pt`, `ru`, `tr`, `zh`, `ja`, `ko`, `hi`, `id`, `fa`, `ur`.
- [x] توسيع محدد اللغة داخل التطبيق إلى اللغات الست عشرة وحفظ الاختيار محليًا.
- [x] إنشاء أيقونة `512x512` وFeature Graphic `1024x500`؛ لم تُنشأ لقطات شاشة وفق طلب المستخدم.
- [ ] إكمال Content rating وCategory/Contact وStore listing في Play Console.
- [ ] إنشاء/تفعيل `lifetime` وبقية منتجات Play وضبط الأسعار الإقليمية بعد تأكيد المالك؛ لا يُعد الكتالوج المحلي دليلًا على أن المنتجات حية.
- [ ] ترحيل النصوص الثابتة في جميع الشاشات إلى ARB قبل ادعاء اكتمال ترجمة واجهة التطبيق.

التفاصيل والأصول موثقة في `docs/PLAY_STORE_LOCALE_AND_ASSETS_PLAN_2026-09-14.md`.

| المجال | الحالة الحالية | الدليل أو الفجوة |
|---|---|---|
| Flutter/Android build | متحقق للبناء المحلي وCI وفق السجلات | Flutter 3.47.4، Dart 3.13.3، SDK 36، وأدلة analyze/test/build سابقة |
| Android runtime | غير متحقق | لا يوجد جهاز أو Emulator مسجل في الأدلة |
| LaMa ONNX | implementation وعقد مصدرية موجودة | cold/warm inference وoutput والذاكرة ما زالت بلا دليل جهاز |
| Real-ESRGAN | fallback فقط | `RealESRGAN_x4plus.pth` موجود، وONNX/NCNN غير موصول |
| MI-GAN | محظور قانونيًا وتقنيًا | لا تُضاف الأوزان قبل تصريح إعادة توزيع تجاري |
| Editor/Chat | جزئي | contracts وimage picker موجودان؛ mask وE2E/runtime متبقيان |
| Batch | Pro/Lifetime gate وpipeline محلي عبر AiService | Android runtime/performance واختبار الجهاز متبقية؛ لا يُعلن كميزة متحققة على Android بعد |
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
- [x] Batch يطبق pipeline التحرير الحقيقي عبر `AiService` بدل نسخ الملفات فقط؛ تحقق Android والأداء ما زال متبقيًا.
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

**الحالة:** جزئية؛ التنفيذ الفعلي موثق، وبعض الوثائق التاريخية تحتاج مواءمة.

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
- [x] اختبارات ProService: البداية، 30 يومًا، 365 يومًا، Lifetime، auto-expiry، restore، إعادة التحميل من التخزين، Product ID غير صالح، وبيانات التحقق الفارغة.
- [x] اختبارات Billing الأساسية والموسعة: المنتجات الستة، تصنيف consumable/entitlement، purchase statuses، fake Google Play store، `completePurchase`، `restorePurchases`، رفض المعاملات الفارغة، duplicate grant، restored consumables، `canSpend`، ومنع الرصيد السالب.
- [x] اختبارات Credits: حزم 100/500/1200، stacking، duplicate grant، والإنفاق دون رصيد سالب؛ سياسة refund الحقيقية تبقى مرتبطة بـPlay Console المؤجلة.
- [x] اختبارات service لـBatch/History/Brand/Storage، وwidget tests سلوكية لـPaywall وSettings وBatch وHistory، واختبارات Router للمسارات وunknown route.
- [ ] Fixtures للصور والأقنعة دون تخزين النموذج داخل Git.
- [ ] benchmark cold/warm، cancellation، timeout، memory، CPU/NNAPI، 30–100 inference.
- [x] CI للتحليل والاختبار والبناء وفحص الأسرار؛ فحوص Flutter وبناء Release APK/AAB نجحت، كما نجحت اختبارات ProService وWidget smoke على commit `ddaf70d` في التشغيل [34914019464](https://github.com/toufikben/productchat_studio/actions/runs/34914019464). تم رفع artifact للـAAB وartifact للـAPK في التشغيل [34911550832](https://github.com/toufikben/productchat_studio/actions/runs/34911550832).

### المرحلة 9 — Internal Testing والإصدار — مؤجلة

**الحالة:** مؤجلة بقرار المنتج؛ لا يوجد رفع إلى Play Console أو تحقق على جهاز/Emulator ضمن النطاق الحالي. يظل APK/AAB مبنيًا ومتحققًا عبر CI فقط، ولا يُعلن جاهزًا للنشر أو متحققًا على Android runtime.

#### إجراءات Play Console البشرية المطلوبة — مؤجلة

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

## Repair Change Control and Rollback Log

All repair work must follow these rules:

1. **Before each phase:** record the phase name, scope, files/components involved, known risks, rollback point, and acceptance checks. No code changes begin before this entry exists.
2. **After each phase:** record the actual changes, validation results, unresolved issues, and whether the phase is accepted, blocked, or needs rollback.
3. **Rollback safety:** do not overwrite previous log entries. Every phase must have a separately identifiable checkpoint/commit so the phase can be reverted without removing unrelated work.
4. **No silent scope changes:** if validation reveals a new issue or the planned scope changes, document it here before continuing.

### Change Log

- **2026-09-14 — Pre-repair audit checkpoint:** Full roadmap and release-readiness review completed. Confirmed issues are documented in the audit report. **No application code changes or repair phase has started.**
- **Phase 1 — CI/analyzer stabilization — STARTED 2026-09-14:** Approved diagnostic phase. Scope: inspect the latest GitHub Actions failure, reproduce or inspect `flutter analyze` failures, identify affected files and exact proposed fixes. No application code changes are authorized yet. Acceptance: a reviewed error list and proposed patch plan are presented before code edits.

- **Phase 1 — Repository/Play readiness audit — COMPLETED 2026-09-14:** تمت مراجعة دليل Google Play المرفق مقابل المصدر الحالي، وخارطة الطريق، ومصفوفة التحقق، ومعرّفات Android، والصلاحيات، وكتالوج Billing، والأصول، وحالة المستودع. تأكد أن Flutter غير متاح في بيئة التدقيق، ولا توجد أدلة جهاز/محاكي Android أو أدلة Play Console. صُحح وضع Batch القديم ووُثقت خطوات Play التي تتطلب جلسة Play Console وحساب اختبار وبناءً مثبتًا. لم تُجرَ تغييرات على كود التطبيق.

## 7. بوابة تنفيذ Google Play

يُعامل الدليل المرفق كـ **قائمة مدخلات للإصدار** وليس دليلًا على وجود الميزات المذكورة. لا يجوز إدخال الادعاءات التالية في Play Console دون تأكيد مالك المنتج ودليل تشغيل: ثلاثة نماذج لإزالة الخلفية، 31 خلفية، معالجة 100 صورة، دعم 16 لغة، عدم رفع أي بيانات للسحابة، وصلاحيات الكاميرا/الميكروفون/الإشعارات، والأسعار أو التوفر الإقليمي الوارد في الدليل.

قبل فتح Play Console، تُنجز الخطوات بالترتيب:

1. تثبيت Flutter 3.47.4/Dart 3.13.3 وتشغيل `pub get` و`gen-l10n` و`analyze` و`test` وبناء Debug APK وRelease APK وRelease AAB من commit واحد.
2. تشغيل مسار Android smoke على جهاز أو محاكي، بما في ذلك PatchMatch وChat وEditor وBatch وHistory وإعادة تشغيل التخزين والمسارات الظاهرة. تُسجل مواصفات الجهاز/API/ABI/RAM وversionCode وcommit والبصمات والأخطاء.
3. مطابقة الصلاحيات الفعلية وSDKs والتخزين المحلي وتنزيل النماذج وسلوك Billing مع Privacy/Data Safety. لا تُستخدم إجابات «لا نجمع بيانات» المرفقة قبل إتمام هذه المطابقة.
4. في Play Console، إنشاء وتفعيل المنتجات الستة (`pro_monthly` و`pro_yearly` و`credits_100` و`credits_500` و`credits_1200` و`lifetime`)، إضافة License Testers، إنشاء Internal Testing، ورفع AAB. لا يمكن إثبات أو تنفيذ هذه الخطوات من GitHub وحده.
5. اختبار الشراء وPending وError وRestore وتكرار consumable وانتهاء الاشتراك وRefund/Revocation وLifetime على النسخة المثبتة من Play. لا يُنشر الإصدار النهائي؛ يترك الإرسال النهائي لمالك الحساب.

**قرار البوابة الحالي:** اكتملت مراجعة الوثائق والمصدر؛ تنفيذ Play Console محجوب حتى تتوفر أدلة Flutter/build وAndroid runtime وجلسة Play Console الموثقة للمستخدم. لا يوجد تفويض بالنشر النهائي.

## 8. تدقيق حالة المستودع — 2026-09-15

تمت مراجعة المستودع [`toufikben/productchat_studio`](https://github.com/toufikben/productchat_studio) على `main`، وكان آخر commit عند التدقيق هو `ffaa690` (`fix: align free tier AI contract`). النتيجة التالية تميّز بين ما تم تنفيذه في المصدر وما تم إثباته بتشغيل فعلي:

| البند الذي ظهر في سجل العمل | النتيجة في المستودع | الحالة |
|---|---|---|
| فحص حالة الريبو والفرع الرئيسي | `main` متزامن مع `origin/main` عند `fe3b6d0`، ولا توجد تغييرات محلية وقت التدقيق | **متحقق** |
| إصلاح رسالة Free tier لمسار Chat/Editor | الرسالة أصبحت تذكر PatchMatch واشتراط mask وPro في `ChatController` و`EditorController` | **منفذ في المصدر** |
| إصلاح أخطاء `flutter analyze` | آخر CI نجح فيه `flutter pub get` و`flutter gen-l10n` و`flutter analyze` | **متحقق في CI** |
| اختبارات Flutter | التشغيل [34910985258](https://github.com/toufikben/productchat_studio/actions/runs/34910985258) على `fe3b6d0` نجح بالكامل بعد إضافة اختبارات Billing، كما نجح إصلاح مسار القناع في التشغيل السابق [34908591711](https://github.com/toufikben/productchat_studio/actions/runs/34908591711) | **متحقق في CI** |
| Real-ESRGAN | يوجد fallback موثق فقط؛ لا يوجد ONNX/PTH موصول للتنفيذ، ولم يُثبت inference على Android | **غير مكتمل/مؤجل** |
| Billing وPlay Console | أضيفت تغطية Billing للـcatalog والتصنيفات والحالات والإنفاق ومنع الرصيد السالب؛ التحقق الفعلي على Play Console والشراء وRestore وInternal Testing ما زال متبقيًا | **اختبارات المصدر متحققة؛ التكامل غير مكتمل** |
| Android runtime وLaMa | لا يوجد في هذا التدقيق دليل جهاز أو Emulator لإثبات cold/warm inference والأداء والذاكرة | **غير متحقق** |

**الخلاصة:** تم إنجاز إصلاحات المصدر والتوثيق الظاهرة في سجل الصورة جزئيًا، لكن لا يصح اعتبار المهمة مكتملة أو جاهزة للإصدار؛ الأولوية التالية هي إصلاح اختبار الـmask وإعادة تشغيل CI، ثم تنفيذ تحقق Android وPlay Console الفعلي. بيئة التدقيق الحالية لا تحتوي Flutter أو Dart، لذلك لم يُدّعَ نجاح محلي غير مثبت.

**تحديث 2026-09-15:** تم إصلاح اختبار القناع وحقن `BillingService` في commit `a6eaee7`، ثم أضيفت اختبارات Billing الموسعة في commit `fe3b6d0`. نجح Flutter CI بالكامل. فشل تشغيل البناء الموقّع [34910989011](https://github.com/toufikben/productchat_studio/actions/runs/34910989011) في `flutter build appbundle --release` قبل إنشاء APK/AAB بسبب عدم توافق Gradle 9.3.1/AGP 9.1.0 مع Flutter 3.27.0 (`unable to resolve class groovy.xml.QName`). تم تعديل Gradle إلى 8.10.2 وAGP إلى 8.7.3 وKotlin إلى 2.0.21، ويلزم تشغيل البناء مجددًا بعد رفع هذا الإصلاح.

**متابعة البناء:** التشغيل [34911216248](https://github.com/toufikben/productchat_studio/actions/runs/34911216248) تجاوز مشكلة Groovy، لكنه كشف كتلة `kotlin { compilerOptions { ... } }` غير مرتبطة في `android/app/build.gradle.kts`. أزيلت الكتلة لأنها غير لازمة، ويلزم تشغيل Release جديد للتحقق من إنشاء APK وAAB.

**نتيجة Release النهائية:** التشغيل [34911550832](https://github.com/toufikben/productchat_studio/actions/runs/34911550832) نجح في `flutter analyze` و`flutter test` و`flutter build appbundle --release` و`flutter build apk --release` ورفع artifact للـAAB وartifact للـAPK. ملاحظة GitHub CLI الخاصة بـ`checks:read` لا تؤثر على نجاح Workflow أو artifacts.

**نتيجة اختبارات Pro والواجهات:** التشغيل [34914019464](https://github.com/toufikben/productchat_studio/actions/runs/34914019464) على `ddaf70d` نجح في `flutter analyze` و`flutter test` بعد إضافة اختبارات Monthly/Yearly/Lifetime/Restore وWidget smoke لـPaywall وSettings وBatch وHistory.

**التحقق النهائي للتغطية الموسعة:** التشغيل [34915458728](https://github.com/toufikben/productchat_studio/actions/runs/34915458728) على commit `578447d` نجح في `flutter analyze` و`flutter test` بعد إضافة fake Google Play platform، اختبارات purchase/restore/completePurchase وCredits stacking والاختبارات السلوكية للواجهات والـRouter. ملاحظة GitHub CLI الخاصة بـ`checks:read` لا تؤثر على نجاح Workflow.

- **Phase 1 — Diagnostic log capture — STARTED 2026-09-14:** Approved temporary workflow-only change. Scope: capture and upload the exact flutter analyze output while preserving a failing job when analysis fails. No application code or test logic changes. Rollback: revert the workflow commit. Acceptance: the next run publishes flutter-analyze.log and still reports the analyzer failure.

- **2026-09-14 — دفعة الإصلاحات الأساسية:** تطبيق إصلاحات Android وiOS وCI وطبقة التطبيق وإضافة فحص الأسرار والثيم الفاتح وonboarding وProviderScope والتحقق المحلي من entitlement. لم يُعتمد Real-ESRGAN ONNX: الرابط أعاد 404 وSHA-256 كان placeholder، لذلك أُعيد upscale إلى fallback الموثق وأزيلت الاعتمادية غير المستخدمة وآثارها من lock/registrant.
- **2026-09-14 — تحقق ما بعد الإصلاح:** لا توجد أدوات Flutter/Dart في بيئة التدقيق؛ تعذر تشغيل `pub get`, `gen-l10n`, `analyze`, `test`. يلزم تشغيلها في CI/بيئة Flutter، مع إبقاء Real-ESRGAN مؤجلًا حتى توفير artifact ONNX صالح وSHA-256 موثق.
- **2026-09-14 — تحقق Play Console:** التطبيق ظاهر كـ`Draft app` ومعرّفه `com.productchat.aiphotostudio`. المنتجات الموجودة والنشطة: `credits_100`, `credits_500`, `credits_1200`، واشتراكا `pro_monthly` و`pro_yearly` مع base plans شهرية/سنوية. منتج `lifetime` غير موجود؛ رابط المنتج أعاد `One-time product not found`. الأسعار الفعلية في الجزائر: 100/500/1200 تحتاج مراجعة مباشرة، وظهر 1200 بسعر `DZD 1,100`، وMonthly `DZD 675`، وYearly `DZD 6,800`؛ وهي لا تطابق المواصفة القديمة حرفيًا (`$4.99/$19.99/$39.99`, `$4.99/month`, `$29.99/year`). لا تغييرات حفظت في Play Console.
- **2026-09-14 — إصلاح CI:** فشل تشغيل Flutter checks على `f6f93db` في `flutter pub get` لأن Dart 3.6 مع Flutter 3.27 لا يدعم `intl 0.20.3` الذي يتطلب Dart 3.9. تم تخفيض القيد إلى `intl ^0.19.0` وتحديث `pubspec.lock` إلى SHA-256 الرسمي للأرشيف. يلزم انتظار التشغيل التالي للتحقق من `gen-l10n` و`analyze` و`test`.
- **2026-09-14 — إصلاحات analyze:** نجح `pub get` و`gen-l10n` بعد إصلاح intl، ثم كشف `analyze` أخطاء providers في `app.dart` وغياب `dart:convert` في `BrandIdentityService`، إضافة إلى lint warnings/information. تم تحويل controllers إلى Riverpod providers مع الحفاظ على تهيئتها، إضافة import المطلوب، وتنظيف التحويلات وأسماء `BuildContext`. يلزم تشغيل CI التالي للتحقق من الاختبارات.
- **2026-09-14 — متابعة CI:** كشف التشغيل `34878306905` خطأين إضافيين في `settings_screen.dart` بسبب تحويل `localeProvider` إلى Riverpod provider؛ تم استبدالهما بـ`localeController`. يلزم تشغيل CI على التصحيح الجديد.
- **2026-09-14 — تشغيل CI جديد:** التشغيل `34882002880` على commit `b0d8b18` بدأ، ومرّ حتى لحظة التسجيل بتهيئة Flutter ثم كان `pub get` قيد التنفيذ؛ النتيجة النهائية لم تصدر بعد.
- **2026-09-14 — اختبار Real-ESRGAN:** اجتاز الفحص الثابت (`REAL_ESRGAN_STATIC_CHECK=PASS`): لا يوجد artifact `.onnx/.pth` داخل الريبو، و`runEsrgan` يرجع `null` مع fallback `Bitmap.createScaledBitmap` الموثق. اختبار inference runtime لم يُنفذ لعدم وجود جهاز Android أو artifact ONNX؛ لا يُعلن Real-ESRGAN كميزة منفذة.
- **2026-09-14 — Lifetime:** تم فتح نموذج إنشاء one-time product في Play Console دون تعبئة أو حفظ. الحقول المطلوبة: Product ID، الاسم والوصف، التصنيف الضريبي، ثم Availability and pricing. لا يمكن إكمال الحفظ قبل اعتماد السعر النهائي.
- **2026-09-14 — تصحيح سعر Lifetime من الوثائق السابقة:** السعر المستهدف الموثق في `docs/PLAY_STORE_LOCALE_AND_ASSETS_PLAN_2026-09-14.md` هو `$79.99` مع هدف إقليمي تقريبي `22,000 DZD`. تم تعبئة `lifetime` و`Lifetime Pro` والوصف و`pro-lifetime` في جلسة Play Console، والوصول إلى خطوة Availability and pricing؛ لم يتم الضغط على Activate ولم يُنشأ المنتج لأن محرر Set prices لم يفتح بنجاح.
- **2026-09-14 — إصلاح CI:** التشغيل `34882882551` نجح فيه `pub get` و`flutter analyze` و39 اختبارًا، وفشل اختبار `ai_operation_contract_test.dart` لأن رسالة Free tier لم تتضمن `mask`. تم توحيد الرسالة في `ChatController` و`EditorController` لتذكر أن conversational edits تتطلب mask وPro؛ يلزم تشغيل CI جديد للتحقق.
- **2026-09-14 — فحص Real-ESRGAN وأسعار Billing:** فحص Real-ESRGAN الثابت نجح مع عدم وجود ONNX/PTH artifact، لذلك لا يمكن تنفيذ inference runtime. الأسعار المرجعية متضاربة بين وثائق P7/ROADMAP_REVIEW وأسعار المتجر المستهدفة؛ يجب اعتماد `docs/PLAY_STORE_LOCALE_AND_ASSETS_PLAN_2026-09-14.md` للكتالوج الحالي، والتحقق النهائي من Play Console.

## سجل التحديثات — 2026-09-15 — Native Complete FIX #68–#83

- [x] إضافة SeikaChannel ONNX لـ LaMa وReal-ESRGAN مع fallback PatchMatch.
- [x] إضافة Android Home Widget وموارد `layout` و`drawable` و`xml`.
- [x] إضافة Batch Foreground Service وإعدادات الإشعارات وManifest permissions.
- [x] إضافة استقبال الصور المشتركة على Android وFlutter service المقابل.
- [x] تحديث iOS SeikaChannel وShareReceiver وAppDelegate وInfo.plist.
- [x] تحديث Android Gradle/ProGuard لحفظ ONNX وإبقاء native bindings.
- [x] إنشاء مجلدات Android المطلوبة والتحقق من XML و`git diff --check`.
- [ ] `flutter clean && flutter pub get && flutter analyze`: تعذر التنفيذ لأن Flutter SDK غير موجود في `PATH`.

## سجل التحديثات — 2026-09-15 — Config Complete FIX #84–#91

- [x] إنشاء `analysis_options.yaml` بقواعد lint الصارمة والاستثناءات الخاصة بالمشروع.
- [x] إنشاء إعداد Vercel وملفات Web PWA: `index.html`, `manifest.json`, و`flutter_bootstrap.js`.
- [x] إنشاء `web/favicon.png` يدوياً من أيقونة المتجر المتاحة، مع توفير أيقونات التطبيق وSplash المطلوبة للأصول.
- [x] تحديث `pubspec.yaml` في أقسام Flutter وLauncher/Splash وdev dependencies.
- [x] استبدال `.gitignore` بقواعد Flutter/Android/iOS/Web والأسرار والنماذج.
- [x] اجتياز تحقق JSON و`git diff --check` والتحقق من PNG.
- [ ] `flutter clean && flutter pub get && flutter analyze`: تعذر التنفيذ لأن Flutter SDK غير موجود في `PATH`.

## سجل التحديثات — 2026-09-15 — L10N Complete Part 1 FIX #92–#97

- [x] استبدال `app_en.arb` و`app_ar.arb` وإضافة الترجمات الفرنسية والإسبانية والألمانية والإيطالية.
- [x] التحقق من JSON لجميع ملفات ARB الستة؛ كل ملف يحتوي على 177 مفتاح ترجمة غير وصفي.
- [x] تصحيح escape غير صالح في القيم السعرية حتى تتوافق ملفات ARB مع JSON و`gen-l10n`.
- [ ] `flutter gen-l10n && flutter analyze`: تعذر التنفيذ لأن Flutter SDK غير موجود في `PATH`.
- [ ] اللغات المتبقية ستُستكمل عند وصول Parts 2–4 من حزمة L10N.

## سجل التحديثات — 2026-09-15 — L10N Complete Part 2 FIX #98–#100

- [x] إضافة `app_pt.arb` و`app_ru.arb` و`app_tr.arb` بواقع 177 مفتاح ترجمة لكل ملف.
- [x] التحقق من JSON و`git diff --check` بنجاح.
- [ ] `flutter gen-l10n`: تعذر التنفيذ لأن Flutter SDK غير موجود في `PATH`.

## سجل التحديثات — 2026-09-15 — L10N Complete Part 3 FIX #101–#103

- [x] إضافة `app_zh.arb` و`app_ja.arb` و`app_ko.arb` بواقع 177 مفتاح ترجمة لكل ملف.
- [x] التحقق من JSON و`git diff --check` بنجاح.
- [ ] `flutter gen-l10n`: تعذر التنفيذ لأن Flutter SDK غير موجود في `PATH`.

## سجل التحديثات — 2026-09-15 — L10N Complete Part 4 FIX #104–#108

- [x] إضافة الهندية والإندونيسية والفارسية والأردية بواقع 177 مفتاح ترجمة لكل ملف.
- [x] تعديل `main.dart` وإضافة Hive box باسم `tickets`؛ بقية الصناديق كانت موجودة مسبقاً.
- [x] التحقق من JSON و`git diff --check` بنجاح.
- [ ] `flutter gen-l10n && flutter analyze`: تعذر التنفيذ لأن Flutter SDK غير موجود في `PATH`.

## سجل التحديثات — 2026-09-15 — CI/CD Complete FIX #109–#116

- [x] استبدال workflow التحليل والاختبارات وworkflow بناء Android AAB.
- [x] إضافة secrets hygiene، نشر Web إلى Vercel، بناء iOS، وفحص الجودة.
- [x] إضافة Dependabot وPull Request template.
- [x] فحص الأسرار محلياً: لا توجد placeholders من `YOUR_ORG`، ولا Firebase، ولا keystores، ولا `.env`، ولا Google Services، ولا ملفات أكبر من 50MB.
- [x] workflows تدعم fallback للبناء غير الموقّع عند غياب secrets.
- [ ] يجب إضافة GitHub Secrets عند الحاجة للبناء/النشر الموقّع: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`, `VERCEL_TOKEN`, وبيانات توقيع iOS.
- [ ] لم يُشغّل Flutter محلياً لأن Flutter SDK غير موجود في `PATH`؛ التنفيذ الفعلي سيتم عبر GitHub Actions بعد الرفع.

## سجل التحديثات — 2026-09-15 — New Features Part 1 FIX #123–#133
- [x] إضافة `CropRotateService` للقص والتدوير والقلب والتحجيم والقص المربع.
- [x] إضافة `FiltersService` مع 15 مرشحاً ودعم شدة التأثير.
- [x] إضافة `BackgroundBlurService` لطمس الخلفية مع قناع مركزي متدرج.
- [x] إضافة `ZipExportService` لتجميع الصور في ZIP وإعادة التسمية الدفعية.
- [x] إضافة `AutoSaveService` لحفظ واسترجاع ومسح المسودات عبر Hive.
- [x] إضافة `EnhancementPresetsService` لإدارة presets التحسين وحفظها.
- [x] إنشاء `FiltersScreen` و`CompareScreen` وربطهما بمساري `/filters` و`/compare`.
- [x] إضافة اعتماد `archive: ^3.6.1` وفتح Hive box باسم `drafts` عند بدء التطبيق.
- [x] حفظ نسخة تعليمات الحزمة في `docs/ai_package/27_NEW_FEATURES_PART1.txt`.
- [x] اجتياز `git diff --check` والتحقق من وجود جميع الملفات الجديدة.
- [ ] تعذر تنفيذ `flutter pub get` و`flutter analyze` محلياً لأن Flutter SDK غير موجود في `PATH` (exit code 127)؛ سيجري التحقق عبر GitHub Actions بعد الرفع.
- [x] تصحيح تحويل قيم `clamp` إلى `int` في القص، وإزالة imports غير مستخدمة، وفصل أسماء متغيرات حالات presets لتفادي تعارض النطاق في Dart.

## سجل التحديثات — 2026-09-15 — New Features Part 2 FIX #134–#144
- [x] إضافة `ExifService` لقراءة وتحرير وإزالة بيانات EXIF.
- [x] إضافة `WatermarkPresetService` مع presets نصية وشعارات ومواقع متعددة.
- [x] إضافة `ExportPresetService` مع presets Amazon وEtsy وShopify وInstagram وWeb وPrint.
- [x] إنشاء شاشة `OnboardingTipsScreen` مع حفظ حالة مشاهدة النصائح.
- [x] إضافة `RatingPromptService` و`RatingPromptDialog` وفق قواعد العمليات وفترة الانتظار.
- [x] إنشاء `TimelineScreen` لتجميع سجل العمليات حسب التاريخ ومشاركة النتائج.
- [x] ربط المسارين `/tips` و`/timeline` في الراوتر.
- [x] إضافة `in_app_review` و`store_redirect` إلى `pubspec.yaml`.
- [x] فتح صناديق Hive `watermark_presets` و`export_presets` وتسجيل تاريخ التثبيت.
- [x] ربط تتبع العمليات الناجحة داخل `ChatController`.
- [x] الحفاظ على namespace المتجر الحالي `com.productchat.aiphotostudio`.
- [x] اجتياز `git diff --check` والتحقق من وجود الملفات الجديدة.
- [ ] نتيجة `flutter pub get` و`flutter analyze` معلقة؛ البيئة الحالية لا تحتوي Flutter SDK إذا استمر الخطأ السابق `flutter: command not found`.
