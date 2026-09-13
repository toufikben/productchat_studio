# خطة اختبارات التكامل بين Flutter وKotlin وONNX

**المشروع:** ProductChat Studio  
**القناة:** `productchat/studio/seika`  
**تاريخ الخطة:** 2026-09-14  
**الحالة الحالية:** لا يوجد Android emulator أو جهاز فعلي متصل، ولا يوجد مجلد `integration_test/` في المستودع.

## 1. الهدف والنطاق

تهدف الخطة إلى إثبات أن الطلب ينتقل كاملًا من Flutter إلى Kotlin ثم ONNX Runtime ويعود إلى Flutter بنتيجة صحيحة أو خطأ قابل للفهم. لا يكفي نجاح `flutter analyze` أو بناء APK؛ يجب إثبات contract القناة، التنفيذ الأصلي، دورة حياة النموذج، الإلغاء، المهلة، إدارة الموارد، والنتيجة المرئية.

النطاق الأساسي هو:

- `SeikaService` في Dart.
- `MethodChannel('productchat/studio/seika')`.
- `SeikaChannel` في Kotlin.
- `ModelManager` وتنزيل/تحقق `lama_fp32.onnx`.
- `OrtSession` و`RunOptions`.
- عمليات `inpaint`, `removeBackground`, `upscale`, `addShadow`, `export`.
- `cancelInference`, `loadModel`, `unloadModel`, `isLoaded`.
- تمرير `EditResult` إلى Chat وEditor.

## 2. ما هو مثبت حاليًا وما هو غير مثبت

| المجال | الحالة الحالية |
|---|---|
| Dart precondition/contract tests | موجودة؛ 7 اختبارات ناجحة حاليًا |
| Flutter analyze/test | ناجح |
| APK debug build | ناجح |
| LaMa file SHA-256 وgraph contract | مثبتان ساكنًا |
| MethodChannel على Android | لم يُشغّل في هذه البيئة |
| ONNX session load | لم يُشغّل على Android |
| LaMa pixel inference | لم يُشغّل على Android |
| cancel أثناء `session.run` | يحتاج emulator/device |
| native hard timeout | يحتاج emulator/device |
| heap/native leak test | يحتاج profiler على Android |
| UI image picker/mask flow | يحتاج إكمال flow قبل E2E الكامل |

## 3. طبقات الاختبار

### المستوى A — Dart MethodChannel contract tests

هذه اختبارات Flutter قابلة للتشغيل على Linux/CI باستخدام `TestDefaultBinaryMessengerBinding` أو mock channel. لا تشغل Kotlin أو ONNX؛ هدفها إثبات payloads ومعالجة الردود والأخطاء.

#### حالات `SeikaService`

| ID | الحالة | التحقق |
|---|---|---|
| A-01 | `inpaint` مع image/mask صالحين | method=`inpaint`، payload يحتوي المسارين و`modelPath`، output path ينتج `EditResult.ok` |
| A-02 | image path فارغ | لا يتم استدعاء القناة؛ failure واضح |
| A-03 | mask path فارغ | لا يتم استدعاء القناة؛ failure واضح |
| A-04 | model غير موجود أو SHA mismatch | failure قبل MethodChannel |
| A-05 | native يرجع null/empty | failure `Seika returned no output path` |
| A-06 | `PlatformException` | يتم تحويلها إلى `EditResult.failure` مع method/code |
| A-07 | `MissingPluginException` | failure platform واضح |
| A-08 | `cancelInference` يرجع true | Dart يعيد true |
| A-09 | cancel يرمي PlatformException | Dart يعيد false ولا ينهار |
| A-10 | removeBackground/upscale/shadow/export | method وarguments وcredits صحيحة |

#### حالات controller/editor

| ID | الحالة | التحقق |
|---|---|---|
| A-11 | output ناجح | يدخل output إلى editor history |
| A-12 | native failure | لا يدخل مسار فاشل إلى history؛ يظهر state error |
| A-13 | cancel أثناء busy | busy ينتهي ولا تُسجل نتيجة ناجحة وهمية |

### المستوى B — Android instrumentation tests للقناة

تُنفذ عبر `androidTest` أو Flutter integration test على emulator. يجب إنشاء `SeikaChannel` حقيقي، وربط MethodChannel حقيقي، واستخدام fixtures صغيرة.

#### Channel routing

| ID | الطلب | النتيجة المتوقعة |
|---|---|---|
| B-01 | method غير معروف | `notImplemented` |
| B-02 | `inpaint` بدون imagePath | `SEIKA_ERROR` ورسالة Missing imagePath |
| B-03 | `inpaint` بدون maskPath | `SEIKA_ERROR` ورسالة Missing maskPath |
| B-04 | image غير قابل للقراءة | `SEIKA_ERROR`، لا crash |
| B-05 | image/mask بأبعاد مختلفة | `SEIKA_ERROR`، cleanup للصورتين |
| B-06 | factor خارج 2/4 | `SEIKA_ERROR` قبل allocation كبير |
| B-07 | upscale يتجاوز 4096 | رفض صريح قبل إنشاء output |

#### Model lifecycle

| ID | الخطوات | النتيجة |
|---|---|---|
| B-08 | `isLoaded` قبل load | false |
| B-09 | `loadModel(lama)` ثم `isLoaded` | true |
| B-10 | `loadModel` path غير صالح | error واضح ولا session نصف محملة |
| B-11 | load جديد فوق session قديمة | القديمة تُغلق والجديدة تعمل |
| B-12 | `unloadModel` | true ثم `isLoaded=false` |
| B-13 | Activity destroy أثناء idle | executor/scheduler/sessions تُغلق بلا crash |

### المستوى C — ONNX fixture integration

يجب تضمين fixture image وmask صغيرين، مع عدم تخزين نموذج 208 MB داخل Git. يُثبت النموذج في test setup عبر تنزيل محلي cache أو artifact موثق SHA-256.

#### LaMa contract

| ID | التحقق |
|---|---|
| C-01 | session يحمّل `lama_fp32.onnx` بنجاح |
| C-02 | input names تشمل `image` و`mask` |
| C-03 | image tensor shape `[1,3,512,512]` |
| C-04 | mask tensor shape `[1,1,512,512]` |
| C-05 | output rank >= 4، channels >= 3، dimensions موجبة |
| C-06 | output لا يتجاوز pixel limit |
| C-07 | output path موجود، non-empty، ويفتح كصورة |
| C-08 | image/mask نفس الأبعاد قبل preprocessing |
| C-09 | portrait/landscape لا ينتجان crash؛ توثيق aspect-ratio behavior |

### المستوى D — End-to-end Flutter → Kotlin → ONNX

هذه هي طبقة الإثبات الأساسية، وتنفذ على Android emulator/device:

1. Flutter يجهز fixture image وmask.
2. `SeikaService.inpaint()` يتحقق من model path.
3. Dart يرسل MethodChannel payload.
4. Kotlin يفك الصور ويحمّل/يستخدم session.
5. ONNX ينفذ inference.
6. Kotlin يحفظ output في cache.
7. MethodChannel يعيد output path.
8. Flutter يقرأ output ويتحقق من `EditResult`.
9. يتم التأكد أن output مختلف عن source، قابل للفتح، وله dimensions متوقعة.

#### E2E scenarios

| ID | السيناريو | معايير النجاح |
|---|---|---|
| D-01 | first cold LaMa inference | load + inference + output بلا crash |
| D-02 | warm second inference | session يعاد استخدامها والنتيجة صحيحة |
| D-03 | remove background fast | output PNG موجود وalpha behavior موثق |
| D-04 | remove background quality/LaMa | لا fallback صامت إذا كان model مطلوبًا؛ النتيجة أو error واضح |
| D-05 | upscale fallback | factor 2/4 يعمل ضمن الحدود |
| D-06 | shadow | output image موجود ولا source leak ظاهر |
| D-07 | export jpg | file format صحيح وoutput path يرجع |
| D-08 | invalid model | failure مفهوم ولا crash |
| D-09 | missing file | failure مفهوم ولا session corruption |

## 4. اختبارات الإلغاء والمهلة

### Cancellation

| ID | التوقيت | المتوقع |
|---|---|---|
| X-01 | cancel قبل بدء native work | الطلب يُلغى أو لا ينتج output ناجح |
| X-02 | cancel أثناء preprocessing | `InferenceCancelledException`/`SEIKA_ERROR`، cleanup كامل |
| X-03 | cancel أثناء `session.run` | `RunOptions.setTerminate(true)` ينهي native run |
| X-04 | cancel بعد اكتمال العملية | لا يفسد output ناجحًا ولا يسبب double result |
| X-05 | cancel متكرر | idempotent ولا crash |

يجب قياس الزمن بين استدعاء `cancelInference` ووصول failure إلى Flutter، وتسجيله مع provider CPU/NNAPI.

### Hard timeout

لا يُنتظر 180 ثانية في كل CI run. يلزم test-only timeout configuration أو model/fixture يسبب run طويل. التحقق المطلوب:

1. بدء inference.
2. انتظار timeout controlled.
3. التأكد من `setTerminate(true)`.
4. وصول PlatformException/failure إلى Dart.
5. عدم بقاء `activeInference` أو `RunOptions` أو session result.
6. إمكانية تشغيل inference جديد بعد timeout.

**ملاحظة تنفيذية:** يفضل جعل timeout injectable/configurable في build أو constructor للاختبار، مع إبقاء production default = 180s.

## 5. اختبارات تسريب الموارد

على emulator منخفض الذاكرة وجهاز فعلي:

- 30–100 inferences متتابعة.
- 30 عمليات cancel أثناء مراحل مختلفة.
- 10 دورات `loadModel → inference → unloadModel`.
- 10 دورات Activity background/foreground.
- تشغيل `adb shell dumpsys meminfo` وAndroid Studio Native Memory Profiler/Perfetto.
- أخذ snapshot بعد warm-up ثم بعد كل 10 عمليات.
- مقارنة Java heap وnative heap وGPU/NNAPI allocations.
- فحص عدد ملفات `cacheDir` وحجمها قبل وبعد.
- التأكد من عدم وجود نمو monotonic بعد GC.

معايير القبول المقترحة:

- لا crash أو ANR.
- لا output ناقص أو session unusable بعد cancel/timeout.
- نمو الذاكرة بعد استقرار warm-up محدود ومفسر.
- تعود الذاكرة إلى baseline مقبول بعد `unloadModel` وGC.
- لا تتراكم ملفات cache بلا retention policy.

## 6. الأداء الذي يجب تسجيله

لكل fixture/device/provider سجل:

- model verification time.
- model load time.
- decode time.
- preprocessing time.
- `session.run` time.
- output conversion time.
- save time.
- total wall time.
- peak Java heap.
- peak native heap.
- CPU/NNAPI provider.
- cancel latency.
- timeout recovery time.

استخدم median وp95، ولا تعتمد على run واحد أو Debug APK فقط.

## 7. Fixtures المطلوبة

- `product_512.png` مع mask 512×512.
- `product_portrait.png`.
- `product_landscape.png`.
- mask فارغ.
- mask كامل.
- image/mask بأبعاد مختلفة.
- صورة كبيرة 12MP لاختبار sampled decode.
- ملف تالف وملف model SHA mismatch.

يجب أن تكون fixtures صغيرة ومملوكة للمشروع أو مرخصة بوضوح، بينما يُنزل LaMa من artifact موثق SHA-256:

```text
1faef5301d78db7dda502fe59966957ec4b79dd64e16f03ed96913c7a4eb68d6
```

## 8. ترتيب التنفيذ المقترح

1. إضافة Dart channel contract tests باستخدام mock messenger.
2. إضافة `integration_test/` وAndroid test runner.
3. إضافة fixture image/mask وtest-only model path/config.
4. تشغيل B-level routing tests على emulator.
5. تشغيل C-level ONNX fixture tests.
6. تشغيل D-level E2E Flutter flow.
7. تشغيل cancellation/timeout tests.
8. تشغيل memory/performance stress profile.
9. ربط الاختبارات السريعة في CI، وإبقاء stress suite لجدول nightly أو جهاز مخصص.

## 9. قرار القبول النهائي

لا تُرفع ميزات `edit.inpaint` أو `android.onnx` إلى **Android verified** إلا بعد نجاح:

- D-01 وD-02.
- X-03 أو X-04.
- دورة unload/load.
- memory stress أساسي.
- output fixture validation.
- تسجيل latency وpeak memory على جهاز واحد على الأقل.

حاليًا، المشروع يملك contract/source/build evidence فقط. خطة التكامل ستنقل الحالة إلى runtime-verified بعد توفير Android emulator أو جهاز فعلي وتنفيذ طبقات B–D، ثم اختبارات الذاكرة والأداء.
