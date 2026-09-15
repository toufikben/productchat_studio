# تقرير فحص Flutter وGitHub Workflow

**المشروع:** `toufikben/productchat_studio`  
**تاريخ الفحص:** 2026-09-15  
**النطاق:** فحص `flutter analyze` الكامل، مراجعة `voice_service.dart` و`watermark_preset_service.dart`، ومراجعة Workflow إصدار Android وأسرار GitHub.

## الخلاصة التنفيذية

انتهى `flutter analyze` برمز خروج **1**، وسجّل **411 مشكلة**. توجد أخطاء ترجمة نوعية حقيقية، وليست مجرد تحذيرات، لذلك لا يمكن اعتبار التحليل نظيفًا رغم أن Gradle نجح في إنتاج APK وAAB Release. أكثر المشاكل تركّزًا في خدمات تعتمد على بيانات `dynamic` القادمة من Hive، ومنها الخدمتان المطلوبتان في هذا التقرير.

تم بناء APK وAAB Release موقّعين محليًا خلال الفحص السابق، لكن مفتاح التوقيع المحلي ليس هو أسرار GitHub. كما أن صلاحية قراءة أسرار GitHub عبر `gh secret list` أعادت **HTTP 403**، ولذلك لا يمكن الجزم من بيئة الفحص بأن أسرار المستودع موجودة أو صحيحة. لا يحتوي المستودع المحلي على `android/key.properties` أو keystore متعقّب في Git.

## النتيجة الرقمية لـ `flutter analyze`

| البند | النتيجة |
|---|---:|
| الأمر | `flutter analyze --no-fatal-infos --no-fatal-warnings` |
| رمز الخروج | `1` |
| إجمالي المشكلات | `411` |
| النطاق المطلوب | أخطاء `error` في المصدر، مع ملاحظات `warning` و`info` |
| التحليل بعد إزالة YAML duplicate key | نعم |

## أخطاء `voice_service.dart`

### الأخطاء المباشرة

- `error • The argument type 'dynamic' can't be assigned to the parameter type 'bool'.  • lib/services/voice_service.dart:93:20 • argument_type_not_assignable`
- `error • The argument type 'dynamic' can't be assigned to the parameter type 'bool'.  • lib/services/voice_service.dart:94:16 • argument_type_not_assignable`
- `error • The argument type 'dynamic' can't be assigned to the parameter type 'bool'.  • lib/services/voice_service.dart:95:22 • argument_type_not_assignable`
- `error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/voice_service.dart:96:15 • argument_type_not_assignable`
- `error • The argument type 'dynamic' can't be assigned to the parameter type 'double'.  • lib/services/voice_service.dart:97:17 • argument_type_not_assignable`
- `error • The argument type 'dynamic' can't be assigned to the parameter type 'double'.  • lib/services/voice_service.dart:98:12 • argument_type_not_assignable`
- `error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/services/voice_service.dart:123:69 • argument_type_not_assignable`

### السبب التقني

الدالة `VoiceSettings.fromMap` تستقبل `Map` غير مقيّدة النوع، ولذلك تصبح قيم مثل `m['voiceFeedback']` من النوع `dynamic`. يتم تمرير هذه القيم مباشرة إلى معاملات تتطلب `bool` أو `String` أو `double`. هذا يفسّر أخطاء `argument_type_not_assignable` في الأسطر 93–98 تقريبًا.

الخدمة تحتوي أيضًا على اعتماد مباشر على `Hive.box('settings')` داخل constructor عبر `_loadSettings`. إذا لم يكن الصندوق مفتوحًا، فسيفشل إنشاء `VoiceService` بـ `HiveError`. ظهر هذا فعليًا في اختبارات الصوت عندما لم تتم تهيئة `WidgetsFlutterBinding` أو Hive قبل إنشاء الخدمة.

هناك مشكلة دورة حياة إضافية: `FlutterTts()` يُنشأ كحقل eagerly عند إنشاء `VoiceService`. هذا يربط إنشاء الخدمة بوجود binary messenger، ويؤدي إلى فشل اختبارات الوحدة التي تنشئ الخدمة قبل `WidgetsFlutterBinding.ensureInitialized()`.

### الإصلاح المقترح

ينبغي تحويل factory إلى `Map<String, dynamic>` مع تحويلات صريحة وآمنة، مثل `m['voiceFeedback'] as bool? ?? true`، واستخدام دوال تحويل دفاعية للأرقام. ينبغي كذلك جعل تحميل Hive مشروطًا بكون الصندوق مفتوحًا أو حقن مخزن إعدادات، وتأجيل إنشاء `FlutterTts` إلى `init()` أو توفير adapter قابل للاستبدال في الاختبارات.

## أخطاء `watermark_preset_service.dart`

### الأخطاء المباشرة

- `error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/watermark_preset_service.dart:50:9 • argument_type_not_assignable`
- `error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/watermark_preset_service.dart:51:11 • argument_type_not_assignable`
- `error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/watermark_preset_service.dart:52:11 • argument_type_not_assignable`
- `error • The argument type 'dynamic' can't be assigned to the parameter type 'String?'.  • lib/services/watermark_preset_service.dart:53:11 • argument_type_not_assignable`
- `error • The argument type 'dynamic' can't be assigned to the parameter type 'String?'.  • lib/services/watermark_preset_service.dart:54:15 • argument_type_not_assignable`
- `error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/watermark_preset_service.dart:55:15 • argument_type_not_assignable`
- `error • The argument type 'dynamic' can't be assigned to the parameter type 'double'.  • lib/services/watermark_preset_service.dart:56:12 • argument_type_not_assignable`
- `error • The argument type 'dynamic' can't be assigned to the parameter type 'double'.  • lib/services/watermark_preset_service.dart:57:14 • argument_type_not_assignable`
- `error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/watermark_preset_service.dart:58:17 • argument_type_not_assignable`
- `error • The argument type 'dynamic' can't be assigned to the parameter type 'int'.  • lib/services/watermark_preset_service.dart:59:15 • argument_type_not_assignable`
- `error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/watermark_preset_service.dart:60:12 • argument_type_not_assignable`
- `error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/services/watermark_preset_service.dart:121:57 • argument_type_not_assignable`
- `error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/services/watermark_preset_service.dart:132:50 • argument_type_not_assignable`

### السبب التقني

الدالة `WatermarkPreset.fromMap` تستخدم `Map` غير مقيّدة النوع. لذلك تصبح جميع الحقول `dynamic` قبل تمريرها إلى constructor الذي يتطلب أنواعًا ثابتة. يظهر ذلك في `id`, `name`, `type`, `position`, `scale`, `opacity`, `fontFamily`, `fontSize`, و`color`.

توجد المشكلة نفسها في `getAll`, `update`, و`remove` عند استدعاء `Map.from` على قيم Hive غير المضمونة النوع. يجب التحقق من أن القيمة `Map` فعلًا، ثم تحويلها إلى `Map<String, dynamic>` قبل تمريرها إلى `fromMap`.

كما تعتمد الخدمة على `Hive.box(_boxName)` مباشرة. إذا لم يُفتح صندوق `watermark_presets` قبل الاستخدام فستحدث `HiveError` وقت التشغيل. لا يوجد في هذه الخدمة مسار تهيئة واضح أو dependency injection للصندوق، مما يصعّب اختبارها.

### الإصلاح المقترح

استخدام `factory WatermarkPreset.fromMap(Map<String, dynamic> m)`، مع تحويلات صريحة للحقول وقيم افتراضية آمنة. يجب إضافة helper واحد لتحويل عناصر Hive، ورفض العناصر غير الصالحة بدل إسقاط استثناء غير واضح. يفضّل حقن `Box` أو خدمة تخزين وفتح الصندوق في bootstrap المركزي للتطبيق.

## مشاكل إضافية بارزة في التحليل

يوضح توزيع الأخطاء أن المشكلة ليست محصورة في الخدمتين:

| الملف | عدد أخطاء `error` |
|---|---:|
| `lib/services/watermark_preset_service.dart` | 13 |
| `lib/services/auto_save_service.dart` | 8 |
| `lib/services/export_preset_service.dart` | 8 |
| `lib/services/payment_history_service.dart` | 7 |
| `lib/services/voice_presets_service.dart` | 7 |
| `lib/services/voice_service.dart` | 7 |
| `lib/features/editor/presets_screen.dart` | 6 |
| `lib/features/chat/voice_search_screen.dart` | 1 |
| `lib/services/brand_service.dart` | 1 |


تتكرر أخطاء `dynamic` في خدمات مثل `payment_history_service.dart` و`voice_presets_service.dart`. كما ظهرت أخطاء اختبار وتهيئة سابقة في Billing وFree Quota وFlutter TTS وواجهات smoke tests. هذه المشاكل لا تمنع دائمًا بناء Flutter Release، لكنها تمنع اعتبار الكود سليمًا أو اجتياز CI الذي يشغّل analyzer.

## مراجعة GitHub Workflow

Workflow الإصدار موجود في `.github/workflows/build-release-aab.yml` ويستخدم Flutter 3.27.0 وJava 17. وهو يدعم مسار توقيع بأسرار `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, و`KEY_ALIAS`. أضيف fallback لإنشاء توقيع مؤقت داخل runner عند غياب الأسرار؛ هذا مناسب لإنتاج artifact تجريبي، لكنه **ليس بديلًا عن keystore الإنتاج** لأن المفتاح المؤقت لا يبقى بين التشغيلات.

محاولة قراءة أسماء الأسرار من GitHub عبر `gh secret list` فشلت بـ HTTP 403. لذلك يحتاج مالك المستودع إلى التحقق من إعداد الأسرار يدويًا أو منح صلاحية Actions المناسبة. يجب عدم وضع قيم الأسرار في المستودع أو في هذا التقرير.

## حالة artifacts السابقة

تم التحقق سابقًا من ملفات Release التالية:

| الملف | الحجم التقريبي | حالة التوقيع |
|---|---:|---|
| `app-release.apk` | 121 MB | APK Signature Scheme v2 صالح، signer واحد |
| `app-release.aab` | 77 MB | مبني وموقّع عبر keystore المحلي |

هذه artifacts صالحة للبناء المحلي، لكنها لا تثبت أن GitHub Actions سيستخدم keystore الإنتاج الصحيح حتى يتم التحقق من أسرار المستودع.

## توصيات مرتبة حسب الأولوية

1. إصلاح أخطاء `dynamic` في `voice_service.dart` و`watermark_preset_service.dart` أولًا، لأنهما أخطاء ترجمة واضحة ومحددة.
2. إصلاح بقية أخطاء `argument_type_not_assignable` حتى يصل `flutter analyze` إلى صفر أخطاء.
3. جعل Hive وFlutter TTS قابلين للتهيئة والحقن في الاختبارات.
4. التحقق من أسرار GitHub الأربعة من إعدادات المستودع، مع استخدام keystore الإنتاج الثابت فقط للإصدارات المنشورة.
5. إبقاء fallback المؤقت مخصصًا للمعاينات، وعدم نشر artifact الناتج منه إلى Google Play.
6. إعادة تشغيل `flutter test` و`flutter analyze` ثم workflow الإصدار بعد الإصلاحات.

## حدود الفحص

لم أغيّر `voice_service.dart` أو `watermark_preset_service.dart` في هذه الجولة، لأن المطلوب كان **عرض الأخطاء والمشاكل وتسليم نتيجة التحليل في ملف واحد**. كما لم أستطع قراءة قيم أسرار GitHub بسبب HTTP 403، ولم أكشف أي قيمة سرية.

## الملحق: المخرجات الكاملة لـ `flutter analyze`

المقطع التالي هو سجل التحليل الكامل كما أُنتج في بيئة الفحص، مع الحفاظ على رسائل `error` و`warning` و`info` ومواقعها:

```text
Analyzing productchat_studio...                                 

warning • Unused import: 'package:go_router/go_router.dart' • lib/app.dart:3:8 • unused_import
   info • Sort directive sections alphabetically • lib/core/router.dart:5:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:6:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:7:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:8:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:10:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:14:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:15:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:17:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:19:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:21:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:23:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:25:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:27:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:30:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:32:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:35:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:36:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:37:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:38:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:40:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:44:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/core/router.dart:45:1 • directives_ordering
   info • Use 'const' with the constructor to improve performance • lib/core/theme.dart:34:27 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • lib/core/theme.dart:34:73 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • lib/core/theme.dart:34:100 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • lib/core/theme.dart:34:133 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • lib/core/theme.dart:34:150 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • lib/core/theme.dart:36:225 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • lib/core/theme.dart:36:286 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • lib/core/theme.dart:36:323 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • lib/core/theme.dart:36:340 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • lib/core/theme.dart:36:368 • prefer_const_constructors
   info • Use 'late' for private members with a non-nullable type • lib/features/advanced/ai_description_screen.dart:19:23 • use_late_for_private_fields_and_variables
   info • The private field _tone could be 'final' • lib/features/advanced/ai_description_screen.dart:23:10 • prefer_final_fields
   info • Sort directive sections alphabetically • lib/features/batch/batch_screen.dart:3:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/features/batch/batch_screen.dart:6:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/features/billing/paywall_screen.dart:3:1 • directives_ordering
warning • The member 'state' can only be used within 'package:state_notifier/state_notifier.dart' or a test • lib/features/billing/paywall_screen.dart:93:59 • invalid_use_of_visible_for_testing_member
warning • The member 'state' can only be used within instance members of subclasses of 'package:state_notifier/state_notifier.dart' • lib/features/billing/paywall_screen.dart:93:59 • invalid_use_of_protected_member
   info • The import of 'package:flutter/services.dart' is unnecessary because all of the used elements are also provided by the import of 'package:flutter/material.dart' • lib/features/billing/promo_code_screen.dart:2:8 • unnecessary_import
warning • The value of the field '_result' isn't used • lib/features/billing/promo_code_screen.dart:19:16 • unused_field
   info • Sort directive sections alphabetically • lib/features/billing/subscription_status_screen.dart:6:1 • directives_ordering
warning • Unused import: '../../services/pro_service.dart' • lib/features/billing/subscription_status_screen.dart:7:8 • unused_import
   info • Sort directive sections alphabetically • lib/features/billing/subscription_status_screen.dart:8:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/features/billing/subscription_status_screen.dart:10:1 • directives_ordering
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/billing/subscription_status_screen.dart:102:25 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'showDialog' can't be inferred • lib/features/billing/subscription_status_screen.dart:273:5 • inference_failure_on_function_invocation
warning • Unused import: 'package:flutter/material.dart' • lib/features/chat/chat_controller.dart:1:8 • unused_import
   info • Sort directive sections alphabetically • lib/features/chat/chat_controller.dart:9:1 • directives_ordering
   info • The import of '../../services/ai/migan_service.dart' is unnecessary because all of the used elements are also provided by the import of '../../services/ai_service.dart' • lib/features/chat/chat_controller.dart:9:8 • unnecessary_import
   info • The import of '../../services/ai/qwen_edit_service.dart' is unnecessary because all of the used elements are also provided by the import of '../../services/ai_service.dart' • lib/features/chat/chat_controller.dart:10:8 • unnecessary_import
   info • The import of '../../services/ai/relight_service.dart' is unnecessary because all of the used elements are also provided by the import of '../../services/ai_service.dart' • lib/features/chat/chat_controller.dart:11:8 • unnecessary_import
   info • Sort directive sections alphabetically • lib/features/chat/chat_controller.dart:12:1 • directives_ordering
   info • The import of '../../services/ai/colorize_service.dart' is unnecessary because all of the used elements are also provided by the import of '../../services/ai_service.dart' • lib/features/chat/chat_controller.dart:12:8 • unnecessary_import
   info • Sort directive sections alphabetically • lib/features/chat/chat_controller.dart:17:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/features/chat/chat_controller.dart:18:1 • directives_ordering
   info • The parameter 'billing' is not used in the constructor • lib/features/chat/chat_controller.dart:69:38 • avoid_unused_constructor_parameters
warning • The value of the field '_migan' isn't used • lib/features/chat/chat_controller.dart:75:9 • unused_field
warning • The value of the field '_upscale' isn't used • lib/features/chat/chat_controller.dart:79:9 • unused_field
   info • Use an if-null operator to convert a 'null' to a 'bool' • lib/features/chat/chat_controller.dart:129:9 • use_if_null_to_convert_nulls_to_bools
   info • Missing an 'await' for the 'Future' computed by this expression • lib/features/chat/chat_controller.dart:184:9 • unawaited_futures
   info • Use 'const' with the constructor to improve performance • lib/features/chat/chat_controller.dart:332:16 • prefer_const_constructors
warning • The value of the local variable 'input' isn't used • lib/features/chat/chat_history_screen.dart:60:11 • unused_local_variable
   info • Missing an 'await' for the 'Future' computed by this expression • lib/features/chat/chat_screen.dart:63:7 • unawaited_futures
   info • Use a raw string to avoid using escapes • lib/features/chat/chat_screen.dart:218:29 • use_raw_strings
warning • Unused import: '../../widgets/app_widgets.dart' • lib/features/chat/voice_search_screen.dart:9:8 • unused_import
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/features/chat/voice_search_screen.dart:130:39 • argument_type_not_assignable
   info • Sort directive sections alphabetically • lib/features/editor/editor_controller.dart:8:1 • directives_ordering
   info • The referenced name isn't visible in scope • lib/features/editor/editor_controller.dart:245:13 • comment_references
   info • Sort directive sections alphabetically • lib/features/editor/editor_screen.dart:7:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/features/editor/editor_screen.dart:8:1 • directives_ordering
warning • Unused import: '../../widgets/app_widgets.dart' • lib/features/editor/filters_screen.dart:6:8 • unused_import
   info • Closure should be a tearoff • lib/features/editor/mask_painter_screen.dart:37:39 • unnecessary_lambdas
   info • Unnecessary duplication of receiver • lib/features/editor/mask_painter_screen.dart:44:5 • cascade_invocations
   info • Statements in a for should be enclosed in a block • lib/features/editor/mask_painter_screen.dart:197:30 • curly_braces_in_flow_control_structures
warning • Unused import: 'dart:convert' • lib/features/editor/presets_screen.dart:1:8 • unused_import
warning • The generic type 'Map<dynamic, dynamic>' should have explicit type arguments but doesn't • lib/features/editor/presets_screen.dart:27:32 • strict_raw_type
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/features/editor/presets_screen.dart:28:9 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/features/editor/presets_screen.dart:29:11 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/features/editor/presets_screen.dart:30:43 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/features/editor/presets_screen.dart:31:31 • argument_type_not_assignable
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/editor/presets_screen.dart:42:22 • inference_failure_on_function_invocation
  error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/features/editor/presets_screen.dart:43:65 • argument_type_not_assignable
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/editor/presets_screen.dart:53:16 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/editor/presets_screen.dart:58:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the constructor 'Map.from' can't be inferred • lib/features/editor/presets_screen.dart:60:17 • inference_failure_on_instance_creation
  error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/features/editor/presets_screen.dart:60:26 • argument_type_not_assignable
   info • Statements in a for should be enclosed in a block • lib/features/editor/presets_screen.dart:63:27 • curly_braces_in_flow_control_structures
   info • Sort directive sections alphabetically • lib/features/home/home_screen.dart:5:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/features/home/home_screen.dart:9:1 • directives_ordering
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/home/home_screen.dart:70:29 • inference_failure_on_function_invocation
   info • Use 'const' with the constructor to improve performance • lib/features/home/home_screen.dart:119:13 • prefer_const_constructors
   info • Use 'const' literals as arguments to constructors of '@immutable' classes • lib/features/home/home_screen.dart:120:25 • prefer_const_literals_to_create_immutables
   info • Use 'const' with the constructor to improve performance • lib/features/home/home_screen.dart:121:17 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • lib/features/home/home_screen.dart:122:26 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • lib/features/home/home_screen.dart:129:17 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • lib/features/home/home_screen.dart:130:26 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • lib/features/home/home_screen.dart:137:17 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • lib/features/home/home_screen.dart:138:26 • prefer_const_constructors
   info • Sort directive sections alphabetically • lib/features/settings/about_screen.dart:4:1 • directives_ordering
   info • Use 'const' with the constructor to improve performance • lib/features/settings/about_screen.dart:25:17 • prefer_const_constructors
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/analytics_screen.dart:15:31 • inference_failure_on_function_invocation
warning • The generic type 'Box<dynamic>' should have explicit type arguments but doesn't • lib/features/settings/analytics_screen.dart:16:28 • strict_raw_type
   info • Sort directive sections alphabetically • lib/features/settings/developer_screen.dart:9:1 • directives_ordering
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/developer_screen.dart:28:28 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/developer_screen.dart:29:21 • inference_failure_on_function_invocation
   info • Use of an async 'dart:io' method • lib/features/settings/developer_screen.dart:38:15 • avoid_slow_async_io
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/developer_screen.dart:84:24 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/developer_screen.dart:94:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/developer_screen.dart:103:34 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/developer_screen.dart:119:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/developer_screen.dart:128:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/developer_screen.dart:129:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/developer_screen.dart:146:30 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/developer_screen.dart:147:30 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/developer_screen.dart:148:30 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/developer_screen.dart:149:30 • inference_failure_on_function_invocation
   info • Use 'const' with the constructor to improve performance • lib/features/settings/developer_screen.dart:160:11 • prefer_const_constructors
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/favorites_screen.dart:16:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/favorites_screen.dart:21:16 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/favorites_screen.dart:26:22 • inference_failure_on_function_invocation
   info • Statements in a for should be enclosed in a block • lib/features/settings/favorites_screen.dart:28:27 • curly_braces_in_flow_control_structures
   info • The import of 'package:flutter/services.dart' is unnecessary because all of the used elements are also provided by the import of 'package:flutter/material.dart' • lib/features/settings/feedback_screen.dart:2:8 • unnecessary_import
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/feedback_screen.dart:42:22 • inference_failure_on_function_invocation
warning • Don't use 'BuildContext's across async gaps • lib/features/settings/feedback_screen.dart:55:19 • use_build_context_synchronously
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/marketplace_screen.dart:24:12 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/marketplace_screen.dart:27:12 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/marketplace_screen.dart:31:16 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/marketplace_screen.dart:43:16 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/marketplace_screen.dart:55:16 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/marketplace_screen.dart:203:24 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'post' can't be inferred • lib/features/settings/marketplace_screen.dart:215:29 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/marketplace_screen.dart:228:24 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'post' can't be inferred • lib/features/settings/marketplace_screen.dart:238:29 • inference_failure_on_function_invocation
   info • Sort directive sections alphabetically • lib/features/settings/models_screen.dart:7:1 • directives_ordering
   info • Use of an async 'dart:io' method • lib/features/settings/models_screen.dart:94:16 • avoid_slow_async_io
   info • Use of an async 'dart:io' method • lib/features/settings/models_screen.dart:104:17 • avoid_slow_async_io
   info • Use of an async 'dart:io' method • lib/features/settings/models_screen.dart:137:17 • avoid_slow_async_io
   info • Use of an async 'dart:io' method • lib/features/settings/models_screen.dart:160:15 • avoid_slow_async_io
   info • Use of an async 'dart:io' method • lib/features/settings/models_screen.dart:161:15 • avoid_slow_async_io
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/onboarding_tips_screen.dart:163:16 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/features/settings/onboarding_tips_screen.dart:196:17 • inference_failure_on_function_invocation
warning • Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check • lib/features/settings/referral_screen.dart:7:1600 • use_build_context_synchronously
   info • Sort directive sections alphabetically • lib/features/settings/update_screen.dart:3:1 • directives_ordering
warning • The type argument(s) of the constructor 'Future.delayed' can't be inferred • lib/features/settings/update_screen.dart:31:11 • inference_failure_on_instance_creation
warning • The type argument(s) of the function 'showDialog' can't be inferred • lib/features/settings/voice_presets_screen.dart:99:11 • inference_failure_on_function_invocation
warning • Unused import: '../../widgets/app_widgets.dart' • lib/features/settings/voice_settings_screen.dart:5:8 • unused_import
warning • The type argument(s) of the constructor 'Future.delayed' can't be inferred • lib/features/splash/splash_screen.dart:24:11 • inference_failure_on_instance_creation
warning • The type argument(s) of the function 'openBox' can't be inferred • lib/main.dart:24:43 • inference_failure_on_function_invocation
   info • Missing an 'await' for the 'Future' computed by this expression • lib/main.dart:34:3 • unawaited_futures
   info • Statements in an if should be enclosed in a block • lib/services/ai/colorize_service.dart:14:9 • curly_braces_in_flow_control_structures
warning • Unused import: '../model_manager.dart' • lib/services/ai/migan_service.dart:5:8 • unused_import
   info • Use of an async 'dart:io' method • lib/services/ai/migan_service.dart:20:20 • avoid_slow_async_io
warning • Unused import: 'dart:typed_data' • lib/services/ai/qwen_edit_service.dart:2:8 • unused_import
warning • Unused import: 'package:image/image.dart' • lib/services/ai/qwen_edit_service.dart:4:8 • unused_import
   info • Use of an async 'dart:io' method • lib/services/ai/qwen_edit_service.dart:18:16 • avoid_slow_async_io
warning • Unused import: 'dart:math' • lib/services/ai/relight_service.dart:2:8 • unused_import
   info • Statements in an if should be enclosed in a block • lib/services/ai/relight_service.dart:25:9 • curly_braces_in_flow_control_structures
   info • Unnecessary duplication of receiver • lib/services/ai_description_service.dart:161:7 • cascade_invocations
   info • Unnecessary duplication of receiver • lib/services/ai_description_service.dart:162:7 • cascade_invocations
   info • Unnecessary duplication of receiver • lib/services/ai_description_service.dart:163:7 • cascade_invocations
   info • Unnecessary duplication of receiver • lib/services/ai_description_service.dart:164:7 • cascade_invocations
   info • Unnecessary duplication of receiver • lib/services/ai_description_service.dart:165:7 • cascade_invocations
   info • Unnecessary duplication of receiver • lib/services/ai_description_service.dart:166:7 • cascade_invocations
   info • Unnecessary duplication of receiver • lib/services/ai_description_service.dart:167:7 • cascade_invocations
   info • Unnecessary duplication of receiver • lib/services/ai_description_service.dart:174:7 • cascade_invocations
   info • Unnecessary duplication of receiver • lib/services/ai_description_service.dart:175:7 • cascade_invocations
   info • Unnecessary duplication of receiver • lib/services/ai_description_service.dart:176:7 • cascade_invocations
   info • Unnecessary duplication of receiver • lib/services/ai_description_service.dart:177:7 • cascade_invocations
   info • Unnecessary duplication of receiver • lib/services/ai_description_service.dart:178:7 • cascade_invocations
   info • Unnecessary duplication of receiver • lib/services/ai_description_service.dart:179:7 • cascade_invocations
   info • Unnecessary duplication of receiver • lib/services/ai_description_service.dart:180:7 • cascade_invocations
   info • Specify exports in a separate section after all imports • lib/services/ai_service.dart:4:1 • directives_ordering
   info • Specify exports in a separate section after all imports • lib/services/ai_service.dart:5:1 • directives_ordering
   info • Specify exports in a separate section after all imports • lib/services/ai_service.dart:6:1 • directives_ordering
   info • Specify exports in a separate section after all imports • lib/services/ai_service.dart:7:1 • directives_ordering
   info • Specify exports in a separate section after all imports • lib/services/ai_service.dart:8:1 • directives_ordering
   info • The import of 'dart:typed_data' is unnecessary because all of the used elements are also provided by the import of 'package:flutter/services.dart' • lib/services/ai_service.dart:12:8 • unnecessary_import
warning • Unused import: 'package:path_provider/path_provider.dart' • lib/services/ai_service.dart:15:8 • unused_import
   info • Statements in an if should be enclosed in a block • lib/services/ai_service.dart:109:9 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block • lib/services/ai_service.dart:171:9 • curly_braces_in_flow_control_structures
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/auto_save_service.dart:14:22 • inference_failure_on_function_invocation
  error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/services/auto_save_service.dart:25:50 • argument_type_not_assignable
   info • Statements in a for should be enclosed in a block • lib/services/auto_save_service.dart:28:37 • curly_braces_in_flow_control_structures
warning • The type argument(s) of the constructor 'Map.from' can't be inferred • lib/services/auto_save_service.dart:36:22 • inference_failure_on_instance_creation
  error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/services/auto_save_service.dart:36:31 • argument_type_not_assignable
warning • The type argument(s) of the constructor 'Map.from' can't be inferred • lib/services/auto_save_service.dart:37:22 • inference_failure_on_instance_creation
  error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/services/auto_save_service.dart:37:31 • argument_type_not_assignable
   info • Statements in a for should be enclosed in a block • lib/services/auto_save_service.dart:41:35 • curly_braces_in_flow_control_structures
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/auto_save_service.dart:46:22 • inference_failure_on_function_invocation
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/auto_save_service.dart:50:13 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/auto_save_service.dart:51:20 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/services/auto_save_service.dart:53:11 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/auto_save_service.dart:55:36 • argument_type_not_assignable
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/auto_save_service.dart:63:22 • inference_failure_on_function_invocation
  error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/services/auto_save_service.dart:66:50 • argument_type_not_assignable
   info • Statements in a for should be enclosed in a block • lib/services/auto_save_service.dart:69:37 • curly_braces_in_flow_control_structures
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/auto_save_service.dart:72:35 • inference_failure_on_function_invocation
   info • Unnecessary use of parentheses • lib/services/background_blur_service.dart:35:24 • unnecessary_parenthesis
   info • The import of '../models/edit_result.dart' is unnecessary because all of the used elements are also provided by the import of '../models/edit_request.dart' • lib/services/batch_service.dart:7:8 • unnecessary_import
   info • Use of an async 'dart:io' method • lib/services/batch_service.dart:76:20 • avoid_slow_async_io
   info • Sort directive sections alphabetically • lib/services/billing_service.dart:10:1 • directives_ordering
   info • Unnecessary use of parentheses • lib/services/billing_service.dart:71:7 • unnecessary_parenthesis
warning • The generic type 'Map<dynamic, dynamic>' should have explicit type arguments but doesn't • lib/services/brand_service.dart:32:32 • strict_raw_type
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/brand_service.dart:64:22 • inference_failure_on_function_invocation
  error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/services/brand_service.dart:68:61 • argument_type_not_assignable
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/brand_service.dart:75:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/brand_service.dart:80:22 • inference_failure_on_function_invocation
   info • Unnecessary duplication of receiver • lib/services/compliance_service.dart:184:7 • cascade_invocations
   info • Unnecessary duplication of receiver • lib/services/compliance_service.dart:188:7 • cascade_invocations
   info • The import of 'dart:ui' is unnecessary because all of the used elements are also provided by the import of 'package:flutter/foundation.dart' • lib/services/crash_reporting_service.dart:5:8 • unnecessary_import
warning • The generic type 'Box<dynamic>?' should have explicit type arguments but doesn't • lib/services/crash_reporting_service.dart:14:10 • strict_raw_type
   info • Sort directive sections alphabetically • lib/services/enhancement_presets_service.dart:3:1 • directives_ordering
   info • The import of 'ai/relight_service.dart' is unnecessary because all of the used elements are also provided by the import of 'ai_service.dart' • lib/services/enhancement_presets_service.dart:3:8 • unnecessary_import
   info • The variable name 'r_auto' isn't a lowerCamelCase identifier • lib/services/enhancement_presets_service.dart:30:17 • non_constant_identifier_names
   info • The variable name 'r2_auto' isn't a lowerCamelCase identifier • lib/services/enhancement_presets_service.dart:32:17 • non_constant_identifier_names
   info • The variable name 'r_studio' isn't a lowerCamelCase identifier • lib/services/enhancement_presets_service.dart:37:17 • non_constant_identifier_names
   info • The variable name 'r2_studio' isn't a lowerCamelCase identifier • lib/services/enhancement_presets_service.dart:39:17 • non_constant_identifier_names
   info • The variable name 'r_marketplace' isn't a lowerCamelCase identifier • lib/services/enhancement_presets_service.dart:44:17 • non_constant_identifier_names
   info • The variable name 'r2_marketplace' isn't a lowerCamelCase identifier • lib/services/enhancement_presets_service.dart:46:17 • non_constant_identifier_names
   info • The variable name 'r_instagram' isn't a lowerCamelCase identifier • lib/services/enhancement_presets_service.dart:51:17 • non_constant_identifier_names
   info • The variable name 'r_soft' isn't a lowerCamelCase identifier • lib/services/enhancement_presets_service.dart:56:17 • non_constant_identifier_names
   info • The variable name 'r2_soft' isn't a lowerCamelCase identifier • lib/services/enhancement_presets_service.dart:58:17 • non_constant_identifier_names
   info • The variable name 'r_contrast' isn't a lowerCamelCase identifier • lib/services/enhancement_presets_service.dart:63:17 • non_constant_identifier_names
   info • The variable name 'r_warm' isn't a lowerCamelCase identifier • lib/services/enhancement_presets_service.dart:68:17 • non_constant_identifier_names
   info • The variable name 'r_white' isn't a lowerCamelCase identifier • lib/services/enhancement_presets_service.dart:73:17 • non_constant_identifier_names
   info • The variable name 'r2_white' isn't a lowerCamelCase identifier • lib/services/enhancement_presets_service.dart:75:17 • non_constant_identifier_names
warning • The generic type 'Map<dynamic, dynamic>' should have explicit type arguments but doesn't • lib/services/export_preset_service.dart:33:32 • strict_raw_type
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/export_preset_service.dart:34:9 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/export_preset_service.dart:35:11 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/export_preset_service.dart:36:13 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'int'.  • lib/services/export_preset_service.dart:37:11 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'int'.  • lib/services/export_preset_service.dart:38:14 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'bool'.  • lib/services/export_preset_service.dart:39:19 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String?'.  • lib/services/export_preset_service.dart:40:24 • argument_type_not_assignable
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/export_preset_service.dart:94:25 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/export_preset_service.dart:102:17 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/export_preset_service.dart:125:16 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/export_preset_service.dart:130:22 • inference_failure_on_function_invocation
  error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/services/export_preset_service.dart:132:47 • argument_type_not_assignable
   info • Statements in a for should be enclosed in a block • lib/services/export_preset_service.dart:135:27 • curly_braces_in_flow_control_structures
warning • Unused import: 'dart:math' • lib/services/filters_service.dart:2:8 • unused_import
   info • Unnecessary use of parentheses • lib/services/filters_service.dart:98:25 • unnecessary_parenthesis
warning • The '!' will have no effect because the receiver can't be null • lib/services/free_quota_service.dart:19:18 • unnecessary_non_null_assertion
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/free_quota_service.dart:20:14 • inference_failure_on_function_invocation
warning • The '!' will have no effect because the receiver can't be null • lib/services/free_quota_service.dart:22:17 • unnecessary_non_null_assertion
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/free_quota_service.dart:23:14 • inference_failure_on_function_invocation
   info • Statements in an if should be enclosed in a block • lib/services/free_quota_service.dart:54:7 • curly_braces_in_flow_control_structures
   info • Use of an async 'dart:io' method • lib/services/free_watermark_service.dart:21:18 • avoid_slow_async_io
   info • Use 'const' for final variables initialized to a constant value • lib/services/free_watermark_service.dart:44:7 • prefer_const_declarations
warning • The value of the local variable 'extensionStart' isn't used • lib/services/free_watermark_service.dart:62:11 • unused_local_variable
   info • Use a raw string to avoid using escapes • lib/services/free_watermark_service.dart:63:12 • use_raw_strings
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/haptics_service.dart:8:12 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/haptics_service.dart:31:52 • inference_failure_on_function_invocation
   info • Use of an async 'dart:io' method • lib/services/history_service.dart:91:47 • avoid_slow_async_io
   info • Use of an async 'dart:io' method • lib/services/history_service.dart:105:51 • avoid_slow_async_io
   info • The referenced name isn't visible in scope • lib/services/history_service.dart:129:8 • comment_references
   info • The referenced name isn't visible in scope • lib/services/history_service.dart:129:43 • comment_references
   info • Use of an async 'dart:io' method • lib/services/model_manager.dart:67:16 • avoid_slow_async_io
   info • Use of an async 'dart:io' method • lib/services/model_manager.dart:78:16 • avoid_slow_async_io
   info • Use of an async 'dart:io' method • lib/services/model_manager.dart:89:15 • avoid_slow_async_io
   info • Use of an async 'dart:io' method • lib/services/model_manager.dart:95:27 • avoid_slow_async_io
   info • Statements in an if should be enclosed in a block • lib/services/model_manager.dart:118:11 • curly_braces_in_flow_control_structures
   info • Use of an async 'dart:io' method • lib/services/model_manager.dart:132:15 • avoid_slow_async_io
   info • Use of an async 'dart:io' method • lib/services/model_manager.dart:156:7 • avoid_slow_async_io
   info • Use of an async 'dart:io' method • lib/services/model_manager.dart:168:15 • avoid_slow_async_io
   info • Use of an async 'dart:io' method • lib/services/model_manager.dart:169:15 • avoid_slow_async_io
   info • Use of an async 'dart:io' method • lib/services/model_manager.dart:174:15 • avoid_slow_async_io
   info • Use of an async 'dart:io' method • lib/services/model_manager.dart:180:18 • avoid_slow_async_io
warning • The generic type 'Map<dynamic, dynamic>' should have explicit type arguments but doesn't • lib/services/payment_history_service.dart:31:33 • strict_raw_type
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/payment_history_service.dart:32:9 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/payment_history_service.dart:33:16 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/payment_history_service.dart:34:18 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'double'.  • lib/services/payment_history_service.dart:35:13 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/payment_history_service.dart:36:15 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/payment_history_service.dart:37:13 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/payment_history_service.dart:38:29 • argument_type_not_assignable
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/payment_history_service.dart:47:16 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/payment_history_service.dart:51:17 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/payment_history_service.dart:61:32 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/price_ab_test_service.dart:15:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/price_ab_test_service.dart:30:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/price_ab_test_service.dart:39:22 • inference_failure_on_function_invocation
   info • Use 'const' with the constructor to improve performance • lib/services/product_fidelity_service.dart:72:14 • prefer_const_constructors
warning • The value of the field '_box' isn't used • lib/services/promo_code_service.dart:34:16 • unused_field
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/promo_code_service.dart:68:41 • inference_failure_on_function_invocation
warning • The type argument(s) of 'List' can't be inferred • lib/services/promo_code_service.dart:68:85 • inference_failure_on_collection_literal
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/promo_code_service.dart:86:30 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/promo_code_service.dart:92:31 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/promo_code_service.dart:99:20 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/promo_code_service.dart:105:16 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/promo_code_service.dart:124:13 • inference_failure_on_function_invocation
warning • The type argument(s) of 'List' can't be inferred • lib/services/promo_code_service.dart:124:57 • inference_failure_on_collection_literal
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/promo_code_service.dart:127:16 • inference_failure_on_function_invocation
warning • The value of the local variable 'chars' isn't used • lib/services/promo_code_service.dart:132:11 • unused_local_variable
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/rating_prompt_service.dart:23:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/rating_prompt_service.dart:53:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/rating_prompt_service.dart:60:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/rating_prompt_service.dart:71:18 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/rating_prompt_service.dart:79:16 • inference_failure_on_function_invocation
   info • Sort directive sections alphabetically • lib/services/recipe_runner_service.dart:3:1 • directives_ordering
   info • The import of 'ai/relight_service.dart' is unnecessary because all of the used elements are also provided by the import of 'ai_service.dart' • lib/services/recipe_runner_service.dart:3:8 • unnecessary_import
   info • Sort directive sections alphabetically • lib/services/recipe_runner_service.dart:4:1 • directives_ordering
   info • The import of 'ai/colorize_service.dart' is unnecessary because all of the used elements are also provided by the import of 'ai_service.dart' • lib/services/recipe_runner_service.dart:4:8 • unnecessary_import
warning • The value of the field '_colorize' isn't used • lib/services/recipe_runner_service.dart:14:9 • unused_field
warning • The return type of ' Function(String step, double progress)?' cannot be inferred • lib/services/recipe_runner_service.dart:21:5 • inference_failure_on_function_return_type
   info • Use 'const' with the constructor to improve performance • lib/services/recipe_runner_service.dart:34:19 • prefer_const_constructors
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/referral_service.dart:23:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/referral_service.dart:41:22 • inference_failure_on_function_invocation
warning • The type argument(s) of 'List' can't be inferred • lib/services/referral_service.dart:42:68 • inference_failure_on_collection_literal
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/referral_service.dart:50:26 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/referral_service.dart:58:13 • inference_failure_on_function_invocation
warning • The type argument(s) of 'List' can't be inferred • lib/services/referral_service.dart:58:57 • inference_failure_on_collection_literal
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/refund_service.dart:17:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/refund_service.dart:26:26 • inference_failure_on_function_invocation
warning • The type argument(s) of 'List' can't be inferred • lib/services/refund_service.dart:28:51 • inference_failure_on_collection_literal
   info • Unnecessary duplication of receiver • lib/services/refund_service.dart:31:5 • cascade_invocations
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/refund_service.dart:42:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/refund_service.dart:49:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/refund_service.dart:58:32 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/refund_service.dart:64:23 • inference_failure_on_function_invocation
warning • The type argument(s) of 'List' can't be inferred • lib/services/refund_service.dart:64:74 • inference_failure_on_collection_literal
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/refund_service.dart:70:12 • inference_failure_on_function_invocation
   info • Use 'const' with the constructor to improve performance • lib/services/seika_service.dart:97:14 • prefer_const_constructors
   info • Unnecessary duplication of receiver • lib/services/smart_analysis_service.dart:178:7 • cascade_invocations
   info • Unnecessary duplication of receiver • lib/services/smart_analysis_service.dart:182:7 • cascade_invocations
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/sound_service.dart:8:12 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/sound_service.dart:25:52 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/trial_service.dart:42:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/trial_service.dart:68:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/trial_service.dart:84:22 • inference_failure_on_function_invocation
warning • The generic type 'Map<dynamic, dynamic>' should have explicit type arguments but doesn't • lib/services/voice_presets_service.dart:29:31 • strict_raw_type
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/voice_presets_service.dart:30:9 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/voice_presets_service.dart:31:13 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/voice_presets_service.dart:32:16 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/services/voice_presets_service.dart:33:39 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/voice_presets_service.dart:34:31 • argument_type_not_assignable
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/voice_presets_service.dart:43:22 • inference_failure_on_function_invocation
  error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/services/voice_presets_service.dart:44:63 • argument_type_not_assignable
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/voice_presets_service.dart:59:16 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/voice_presets_service.dart:64:22 • inference_failure_on_function_invocation
warning • The type argument(s) of the constructor 'Map.from' can't be inferred • lib/services/voice_presets_service.dart:66:17 • inference_failure_on_instance_creation
  error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/services/voice_presets_service.dart:66:26 • argument_type_not_assignable
   info • Statements in a for should be enclosed in a block • lib/services/voice_presets_service.dart:69:27 • curly_braces_in_flow_control_structures
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/voice_presets_service.dart:72:32 • inference_failure_on_function_invocation
   info • Statements in an if should be enclosed in a block • lib/services/voice_search_service.dart:10:58 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block • lib/services/voice_search_service.dart:11:60 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block • lib/services/voice_search_service.dart:12:56 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block • lib/services/voice_search_service.dart:13:60 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block • lib/services/voice_search_service.dart:14:61 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block • lib/services/voice_search_service.dart:15:60 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block • lib/services/voice_search_service.dart:16:59 • curly_braces_in_flow_control_structures
   info • Sort directive sections alphabetically • lib/services/voice_service.dart:5:1 • directives_ordering
warning • The generic type 'Map<dynamic, dynamic>' should have explicit type arguments but doesn't • lib/services/voice_service.dart:92:33 • strict_raw_type
  error • The argument type 'dynamic' can't be assigned to the parameter type 'bool'.  • lib/services/voice_service.dart:93:20 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'bool'.  • lib/services/voice_service.dart:94:16 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'bool'.  • lib/services/voice_service.dart:95:22 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/voice_service.dart:96:15 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'double'.  • lib/services/voice_service.dart:97:17 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'double'.  • lib/services/voice_service.dart:98:12 • argument_type_not_assignable
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/voice_service.dart:118:22 • inference_failure_on_function_invocation
  error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/services/voice_service.dart:123:69 • argument_type_not_assignable
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/voice_service.dart:130:16 • inference_failure_on_function_invocation
   info • 'localeId' is deprecated and shouldn't be used. Use SpeechListenOptions.localeId instead • lib/services/voice_service.dart:162:7 • deprecated_member_use
warning • Unused import: 'dart:convert' • lib/services/watermark_preset_service.dart:1:8 • unused_import
   info • Sort directive sections alphabetically • lib/services/watermark_preset_service.dart:5:1 • directives_ordering
warning • The generic type 'Map<dynamic, dynamic>' should have explicit type arguments but doesn't • lib/services/watermark_preset_service.dart:49:35 • strict_raw_type
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/watermark_preset_service.dart:50:9 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/watermark_preset_service.dart:51:11 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/watermark_preset_service.dart:52:11 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String?'.  • lib/services/watermark_preset_service.dart:53:11 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String?'.  • lib/services/watermark_preset_service.dart:54:15 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/watermark_preset_service.dart:55:15 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'double'.  • lib/services/watermark_preset_service.dart:56:12 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'double'.  • lib/services/watermark_preset_service.dart:57:14 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/watermark_preset_service.dart:58:17 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'int'.  • lib/services/watermark_preset_service.dart:59:15 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/services/watermark_preset_service.dart:60:12 • argument_type_not_assignable
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/watermark_preset_service.dart:95:17 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/watermark_preset_service.dart:114:16 • inference_failure_on_function_invocation
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/watermark_preset_service.dart:119:22 • inference_failure_on_function_invocation
  error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/services/watermark_preset_service.dart:121:57 • argument_type_not_assignable
warning • The type argument(s) of the function 'box' can't be inferred • lib/services/watermark_preset_service.dart:130:22 • inference_failure_on_function_invocation
  error • The argument type 'dynamic' can't be assigned to the parameter type 'Map<dynamic, dynamic>'.  • lib/services/watermark_preset_service.dart:132:50 • argument_type_not_assignable
   info • Statements in a for should be enclosed in a block • lib/services/watermark_preset_service.dart:135:27 • curly_braces_in_flow_control_structures
warning • The return type of ' Function(double progress)?' cannot be inferred • lib/services/zip_export_service.dart:11:5 • inference_failure_on_function_return_type
   info • Use of an async 'dart:io' method • lib/services/zip_export_service.dart:18:18 • avoid_slow_async_io
   info • Use of an async 'dart:io' method • lib/services/zip_export_service.dart:51:18 • avoid_slow_async_io
warning • Unused import: '../services/voice_service.dart' • lib/ui/productchat_ui_overhaul.dart:4:8 • unused_import
   info • Sort directive sections alphabetically • lib/ui/productchat_ui_overhaul.dart:5:1 • directives_ordering
warning • Unused import: '../features/chat/chat_studio_screen.dart' • lib/ui/productchat_ui_overhaul.dart:5:8 • unused_import
warning • Unused import: '../features/home/home_screen.dart' • lib/ui/productchat_ui_overhaul.dart:6:8 • unused_import
warning • Unused import: '../widgets/floating_nav_bar.dart' • lib/ui/productchat_ui_overhaul.dart:7:8 • unused_import
   info • Sort directive sections alphabetically • lib/ui/productchat_ui_overhaul.dart:12:1 • directives_ordering
   info • Sort directive sections alphabetically • lib/widgets/app_widgets.dart:4:1 • directives_ordering
   info • The parameter name 'c' doesn't match the name 'context' in the overridden method • lib/widgets/app_widgets.dart:86:29 • avoid_renaming_method_parameters
   info • The parameter name 'c' doesn't match the name 'context' in the overridden method • lib/widgets/app_widgets.dart:130:29 • avoid_renaming_method_parameters
   info • Use a 'SizedBox' to add whitespace to a layout • lib/widgets/app_widgets.dart:130:35 • sized_box_for_whitespace
   info • The parameter name 'c' doesn't match the name 'context' in the overridden method • lib/widgets/app_widgets.dart:154:29 • avoid_renaming_method_parameters
   info • The parameter name 'r' doesn't match the name 'ref' in the overridden method • lib/widgets/app_widgets.dart:154:42 • avoid_renaming_method_parameters
   info • The parameter name 'c' doesn't match the name 'context' in the overridden method • lib/widgets/app_widgets.dart:187:29 • avoid_renaming_method_parameters
   info • The parameter name 'r' doesn't match the name 'ref' in the overridden method • lib/widgets/app_widgets.dart:187:42 • avoid_renaming_method_parameters
   info • The parameter name 'c' doesn't match the name 'context' in the overridden method • lib/widgets/app_widgets.dart:234:29 • avoid_renaming_method_parameters
   info • Use 'const' with the constructor to improve performance • lib/widgets/app_widgets.dart:306:31 • prefer_const_constructors
   info • Use of an async 'dart:io' method • lib/widgets/app_widgets.dart:351:16 • avoid_slow_async_io
   info • The parameter name 'c' doesn't match the name 'context' in the overridden method • lib/widgets/app_widgets.dart:359:29 • avoid_renaming_method_parameters
   info • The parameter name 'c' doesn't match the name 'context' in the overridden method • lib/widgets/app_widgets.dart:372:29 • avoid_renaming_method_parameters
   info • The parameter name 'r' doesn't match the name 'ref' in the overridden method • lib/widgets/app_widgets.dart:372:42 • avoid_renaming_method_parameters
   info • The parameter name 'c' doesn't match the name 'context' in the overridden method • lib/widgets/app_widgets.dart:409:29 • avoid_renaming_method_parameters
warning • The type argument(s) of the function 'showDialog' can't be inferred • lib/widgets/rating_prompt_dialog.dart:13:11 • inference_failure_on_function_invocation

411 issues found. (ran in 4.1s)

```

## References

[1]: https://docs.flutter.dev/testing/code-debugging "Flutter debugging and analysis documentation"
[2]: https://docs.flutter.dev/deployment/android "Flutter Android deployment documentation"
[3]: https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions "Using secrets in GitHub Actions"
