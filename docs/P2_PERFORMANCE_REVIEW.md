# P2 performance review: core AI and ONNX path

**Date:** 2026-09-13  
**Scope:** `P2_CORE_AI_VALIDATION.md`, `SeikaChannel.kt`, `SeikaService`, `ModelManager`, and `PerformanceConfig`  
**Important limitation:** لا يوجد Android device/emulator في البيئة، لذلك ما يلي تحليل ساكن وتقديرات مبنية على الكود، وليس benchmark runtime.

## Executive assessment

العقد ONNX لنموذج LaMa صحيح ومثبت، لكن الأداء المتوقع على Android قد يكون ضعيفًا أو غير مستقر بسبب أربعة عوامل رئيسية:

1. **الاستدلال يحدث بصورة متزامنة داخل MethodChannel**؛ لا يظهر في الكود executor أو coroutine لخلفية العمل، لذلك قد تتجمد واجهة Flutter أثناء decode، tensor preparation، `session.run`، وتحويل الخرج.
2. **الذاكرة تُضاعف في عدة مراحل**؛ يتم فك الصورة الأصلية بكامل أبعادها قبل التصغير، ثم إنشاء Bitmaps وarrays وoutput buffers إضافية.
3. **النموذج 198.40 MiB تقريبًا قبل overhead runtime**؛ ONNX Runtime والـ arena وNNAPI قد يرفعون الاستهلاك الفعلي فوق حجم الملف بكثير.
4. **التحقق من جاهزية LaMa يعيد حساب SHA-256 للملف الكامل**؛ `readyPath` يستدعي `isReady`، وهذا قد يقرأ حوالي 208 MB من التخزين عند كل عملية inpaint.

لا يمكن تحويل هذه التقديرات إلى SLA قبل قياسها على جهاز منخفض ومتوسط وحديث.

## تقديرات الذاكرة المباشرة

حسابات الكود الحالية عند LaMa input 512×512:

| العنصر | الحساب | الحجم التقريبي |
|---|---:|---:|
| `imageArray` | `512×512×3×4` | 3.00 MiB |
| `maskArray` | `512×512×4` | 1.00 MiB |
| `imagePixels` | `512×512×4` | 1.00 MiB |
| `maskPixels` | `512×512×4` | 1.00 MiB |
| `values` للخرج | 3 channels على الأقل | 3.00 MiB |
| `resultPixels` | `width×height×4` عند 512 | 1.00 MiB |
| Bitmap واحد ARGB 512 | `512×512×4` | 1.00 MiB |
| نموذج LaMa على القرص | 208,044,816 bytes | 198.40 MiB |

هذه ليست peak memory كاملة. أثناء inference قد توجد في الوقت نفسه:

- Bitmap المصدر بكامل أبعاده.
- Bitmap resized للصورة.
- Bitmap resized للقناع.
- source/output/result Bitmap.
- native ONNX tensors وruntime arena.
- model weights/session allocations.
- buffers مؤقتة داخل `session.run`.

لذلك لا يجوز جمع الأرقام السابقة واعتبارها peak دقيقة، لكنها تثبت أن الجهاز منخفض الذاكرة قد يواجه OOM، خصوصًا إذا كانت الصورة الأصلية 12MP أو 48MP.

## نقاط الضعف حسب الأولوية

### P0 — inference متزامن وقد يحجب واجهة المستخدم

`onMethodCall` يستدعي العمليات مباشرة، و`runLaMa` ينفذ `session.run` داخل نفس مسار الاستدعاء. وجود `synchronized(lock)` يمنع التوازي، لكنه لا ينقل العمل إلى background executor.

**الأثر المتوقع:**

- dropped frames أثناء التحضير والاستدلال.
- Flutter UI تبدو معلقة.
- timeout أو ANR إذا طال inference.
- لا يوجد cancellation فعلي رغم وجود `PerformanceConfig.inferenceTimeout`.

**الإصلاح المقترح:**

- نقل decode/resize/tensor/inference إلى `ExecutorService` أو coroutine dispatcher مخصص.
- إعادة النتيجة إلى MethodChannel على thread مناسب.
- فرض `maxConcurrentInferences = 1` عبر queue لا عبر lock فقط.
- إضافة request id وإلغاء الطلب القديم عند بدء عملية جديدة.

### P0 — قراءة SHA-256 للنموذج عند كل عملية

`SeikaService.inpaint` يستدعي `ModelManager.readyPath(ModelManager.lama)`. هذا يستدعي `isReady`، الذي يحسب SHA-256 من كامل الملف عبر `file.openRead()` كل مرة.

**الأثر المتوقع:**

- I/O بحجم ~208 MB لكل عملية inpaint قبل inference.
- تأخير متكرر حتى عندما يكون النموذج loaded بالفعل.
- استنزاف البطارية والـ flash storage.
- تنافس بين hashing وقراءة النموذج من الذاكرة.

**الإصلاح المقترح:**

- تخزين verified state مع حجم الملف وmtime أو fingerprint موثوق.
- التحقق الكامل مرة واحدة بعد التنزيل، ثم إعادة التحقق فقط عند تغير الحجم/mtime.
- حفظ model metadata versioned.
- عدم استدعاء `readyPath` إذا كانت session loaded بالفعل.

### P0 — تحميل الصورة الأصلية بأبعادها قبل فرض حد الحجم

`decodeBitmap(path)` ينفذ `BitmapFactory.decodeFile(path)` دون `inJustDecodeBounds` أو sample size. بعد ذلك فقط يتم التصغير إلى 512 داخل `safeResize`.

**الأثر المتوقع:**

- صورة 48MP قد تستهلك مئات MB قبل بدء inference.
- OOM قبل الوصول إلى limit.
- زمن decode طويل.
- ضغط إضافي على GC.

`PerformanceConfig.maxImageDimension = 4096` موجود، لكنه غير مستخدم في الجسر.

**الإصلاح المقترح:**

- قراءة bounds أولًا.
- اختيار `inSampleSize` بحيث لا يتجاوز dimension الحد المسموح.
- رفض أو downsample الصور الأكبر قبل إنشاء Bitmap كامل.
- الحفاظ على orientation وalpha بعد sampling.
- تسجيل الأبعاد الأصلية والنهائية.

### P1 — إنشاء نسخ متعددة من Bitmap والـ output

المسار الحالي قد يمر عبر:

1. source Bitmap كامل.
2. resized Bitmap للصورة.
3. resized Bitmap للقناع.
4. output `FloatArray`.
5. resultPixels.
6. Bitmap output بحجم graph.
7. Bitmap scaled إلى أبعاد الصورة الأصلية.
8. Bitmap محفوظ ثم recycled جزئيًا.

**الأثر المتوقع:** peak أعلى من المتوقع، وGC pauses، وبطء في الأجهزة الضعيفة.

**الإصلاح المقترح:**

- استخدام buffers قابلة لإعادة الاستخدام داخل session worker.
- تحرير resized Bitmaps صراحة عندما لا تعود مطلوبة.
- عدم إعادة النتيجة إلى أبعاد 48MP تلقائيًا؛ استخدام حد output dimension.
- الكتابة التدريجية أو تقليل نسخ `FloatArray` عند دعم API ذلك.
- قياس native heap، لا Java heap فقط.

### P1 — تحويل الخرج قد يستهلك ذاكرة ضخمة

`shape` يسمح بأبعاد dynamic، ثم يتم إنشاء `FloatArray(channels * width * height)` و`IntArray(width * height)` دون حد أعلى.

**الأثر المتوقع:** نموذج أو export غير متوقع قد يطلب buffer كبيرًا جدًا.

**الحماية المطلوبة:**

- التحقق من rank، channels، width، height قبل حساب `count`.
- وضع حد أقصى للخرج.
- التحقق من overflow قبل ضرب الأبعاد.
- رفض output غير متوافق مع حجم input المتوقع.
- عدم إنشاء Bitmap أكبر من policy.

الجسر أضاف الآن rank/channel/dimension guards، لكن حدود الذاكرة القصوى ما زالت غير مطبقة.

### P1 — `floodRemove` بطيء على الصور الكبيرة

الـ fallback يمر على كل pixel ويستدعي `getPixel` و`setPixel` داخل nested loops.

**الأثر المتوقع:** زمن CPU مرتفع جدًا على صور كبيرة، حتى دون ONNX.

**الإصلاح المقترح:**

- تشغيله بعد downsample أو على buffer bulk.
- استخدام `getPixels`/`setPixels` بدل استدعاء pixel API لكل نقطة.
- تحديد حد أبعاد واضح للـ fallback.
- قياسه منفصلًا عن inference.

### P1 — `safeResize` يحافظ على aspect ratio بشكل غير صحيح

يتم تصغير الصورة مباشرة إلى 512×512، ما قد يشوه الصور غير المربعة ويزيد جودة inference سوءًا.

**الأثر المتوقع:** ليس فقط جودة؛ resizing غير الضروري يستهلك CPU ونسخ buffers.

**الإصلاح المقترح:**

- letterbox/pad إلى 512 بدل stretch.
- حفظ transform لاستعادة الخرج إلى geometry الأصلية.
- تطبيق نفس transform على القناع.
- اختبار portrait/landscape.

### P1 — session lifecycle وresource lifecycle غير مكتملين

`lamaSession` و`esrganSession` يحتفظ بهما الجسر، لكن لا توجد سياسة واضحة لـ:

- متى يتم load تلقائيًا.
- متى يتم unload عند background أو memory pressure.
- timeout فعلي للتحميل أو inference.
- إغلاق `SessionOptions` بعد إنشاء session.
- منع race بين `ensureModel` و`unloadModels`.

**الأثر المتوقع:** memory retention، إعادة تحميل مكلفة، أو race/crash عند lifecycle changes.

**الإصلاح المقترح:**

- ModelState واضح: unloaded/loading/loaded/failed.
- state machine وmutex/queue واحد.
- `close()` لـ session options والموارد القابلة للإغلاق.
- unload عند memory pressure أو بعد idle policy.
- instrumentation لزمن load وinference.

### P2 — NNAPI fallback غير مقاس

الكود يحاول `addNnapi()` ثم يستخدم CPU عند الفشل، لكن لا يوجد إثبات أن NNAPI provider يعمل على أجهزة مختلفة.

**الأثر المتوقع:** اختلاف كبير بين الأجهزة؛ أحيانًا NNAPI أبطأ أو غير مستقر من CPU.

**الإصلاح المقترح:**

- benchmark CPU مقابل NNAPI على نفس fixture.
- اختيار provider بناءً على capability ونتيجة سابقة، لا بمجرد نجاح `addNnapi()`.
- تسجيل provider الفعلي والزمن.
- fallback مع حد زمني واضح.

### P2 — حجم APK ووقت التثبيت

آخر Debug APK حجمه `243,626,716` bytes. هذا ليس حجم Release النهائي، لكنه مؤشر على أثر Flutter وONNX/native dependencies.

**الأثر المتوقع:**

- تنزيل أولي كبير.
- وقت تثبيت أطول.
- ضغط تخزين مرتفع قبل تنزيل model إضافي.
- احتمال تكرار ONNX runtime داخل أكثر من plugin إذا لم يضبط Gradle packaging.

**الإصلاح المقترح:**

- قياس Release APK/AAB مع R8/shrinkResources.
- ABI splits أو app bundle.
- فحص duplicate native libraries.
- فصل model download عن APK كما هو مخطط، مع progress فعلي.
- تسجيل APK size وdownload size منفصلين.

### P2 — progress model download غير فعلي

`ModelManager.download` يمرر callback إلى Dio لكنه لا يدفع progress stream أثناء النقل؛ yield الحالي يحدث بعد اكتمال `dio.download` تقريبًا.

**الأثر المتوقع:** UI لا تعكس progress الحقيقي، وقد تبدو عملية 208 MB متوقفة.

**الإصلاح المقترح:**

- بث progress عبر `StreamController` من `onReceiveProgress`.
- معالجة total غير المعروف.
- throttle للتحديثات حتى لا يرهق isolate/UI.
- pause/cancel واستئناف حقيقي.

## تقييم PerformanceConfig

`lib/core/performance_config.dart` يعرف سياسات جيدة نظريًا:

- max image dimension 4096؛
- LaMa dimension 512؛
- inference threads 4؛
- max concurrent inferences 1؛
- model load timeout؛
- inference timeout؛
- hardware acceleration preference؛
- CPU fallback.

لكن هذه القيم لا تظهر موصولة فعليًا إلى `SeikaChannel.kt`. هذا يجعلها **وثيقة نية** وليست runtime policy. يجب إما تمريرها إلى native bridge أو حذف القيم غير المطبقة حتى لا تعطي إحساسًا زائفًا بالحماية.

## خطة benchmark المطلوبة

استخدم fixture ثابتًا، ونفذ كل سيناريو 3 مرات على الأقل بعد warm-up، وسجل median وp95:

| السيناريو | القياسات |
|---|---|
| model download | throughput، resume time، disk use |
| first model load | wall time، peak native memory |
| warm LaMa inference | latency، p95، peak memory |
| cold LaMa inference | load + inference latency |
| 1MP image | decode، resize، inference، save |
| 12MP image | same + OOM/GC |
| portrait/landscape | latency + output dimensions |
| CPU vs NNAPI | latency، errors، output parity |
| repeated 10 operations | memory growth، leaks، stability |
| background/foreground | session survival، reload time |

**الأجهزة الدنيا المقترحة:** Android منخفض الذاكرة، جهاز متوسط، وجهاز حديث. لا تُسجل “performance passed” من debug APK أو Linux desktop.

## الأولويات العملية

1. **P0:** background executor، sampled decode، منع إعادة SHA-256، memory/output limits.
2. **P1:** lifecycle state machine، release resources، progress الحقيقي، bulk pixel operations.
3. **P2:** aspect-ratio-preserving preprocessing، CPU/NNAPI benchmark، APK/model size optimization.

## الخلاصة

الضعف الأكبر المتوقع ليس في حجم graph LaMa فقط، بل في تداخل decode الكامل، hashing الكامل، buffers متعددة، inference المتزامن، وعدم تطبيق `PerformanceConfig`. قبل أي claim عن الأداء، يجب تنفيذ P0 الأربعة وقياسها على Android فعليًا. وجود APK ناجح وONNX graph صحيح يثبت القابلية البنيوية فقط، ولا يثبت latency أو memory safety.
