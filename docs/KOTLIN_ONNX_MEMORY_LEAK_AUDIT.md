# Kotlin ONNX memory-leak and resource audit

**Date:** 2026-09-14  
**Scope:** `SeikaChannel.kt`, `MainActivity.kt`, ONNX Runtime sessions/tensors, Bitmaps, executors, and output files

## Static audit result

تمت مراجعة كل موارد Kotlin الظاهرة في مسار ONNX:

- `OrtEnvironment`
- `OrtSession`
- `SessionOptions`
- `RunOptions`
- `OrtSession.Result`
- `OnnxTensor`
- source/resized/output `Bitmap`
- `FileOutputStream`
- work executor وtimeout scheduler

تم العثور على تسريبات قابلة للإثبات في Bitmaps ودورة حياة SessionOptions، وتم إصلاحها. لا يمكن اعتبار غياب التسريب runtime مثبتًا دون Android heap/native profiler.

## Fixes applied

### Bitmap ownership

تمت إضافة cleanup في `finally` للعمليات التالية:

- `removeBackground`: تحرير source Bitmap.
- `inpaint`: تحرير image وmask حتى عند فشل اختلاف الأبعاد أو native inference.
- `upscale`: تحرير source Bitmap.
- `addShadow`: تحرير source Bitmap.
- `export`: تحرير source Bitmap.
- `runLaMa`: تحرير resized image وmask، tensors، output result، وintermediate output Bitmap.

`save()` يضمن الآن recycle للـ Bitmap حتى عند فشل compression أو FileOutputStream.

`floodRemove()` يحرر output إذا حدث استثناء داخل pixel loop.

### ONNX Runtime resources

- `OrtSession.Result` يُغلق في `finally`.
- `OnnxTensor` للصورة والقناع يُغلقان في `finally`.
- `RunOptions` يُغلق في `finally`.
- `SessionOptions` يُغلق بعد إنشاء session.
- عند استبدال session، يتم إنشاء session الجديدة أولًا ثم إغلاق القديمة.
- `OrtEnvironment` لا يتم إغلاقه عمدًا لأنه process-wide/shared حسب ONNX Runtime lifecycle.

### Executor and Activity lifecycle

- `SeikaChannel.close()` يلغي inference النشط.
- ينتظر worker حتى 5 ثوانٍ قبل إغلاق sessions.
- يوقف work executor وtimeout scheduler.
- `MainActivity.onDestroy()` يستدعي `SeikaChannel.close()`.

### Allocation guards

- sampled decode يمنع فك الصور فوق dimension 4096 حيث يمكن.
- LaMa output محدود إلى 4096×4096 pixels.
- upscale يرفض output يتجاوز الحد configured بدل محاولة إنشاء Bitmap ضخمة.
- output rank/channels/dimensions يتم التحقق منها قبل إنشاء arrays.

## Issues not classified as confirmed leaks

هذه نقاط تحتاج runtime measurement أو تحسينًا لاحقًا، لكنها ليست تسريبات مؤكدة من القراءة الساكنة:

- Android native heap وONNX arena قد يحتفظان بالذاكرة بعد session close حتى يعيد runtime استخدامها.
- `Bitmap.createScaledBitmap` قد يرفع peak memory مؤقتًا قبل cleanup.
- NNAPI provider قد يحتفظ بموارد native غير ظاهرة في Java heap.
- `OrtEnvironment` process-wide؛ إغلاقه داخل Activity قد يضر plugins أخرى، لذلك لم يتم إغلاقه.
- cache files الناتجة في `context.cacheDir` قد تتراكم؛ هذا disk-resource leak وليس heap leak، ويحتاج retention/cleanup policy منفصلة.
- إذا أغلق Activity أثناء عملية native طويلة، `shutdownNow` لا يقتل native thread بالقوة؛ cancellation عبر `RunOptions.setTerminate(true)` هو الآلية المستخدمة، ويجب قياس زمن الإنهاء على جهاز.

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | Passed — no issues |
| `flutter test` | Passed — 7 tests |
| `flutter build apk --debug` | Passed |
| APK size | 243,629,147 bytes |
| APK SHA-256 | `be7c20be3fe946e4bc1c9c1efbb83fb277055180357fb2eb729f001dc4afa0c9` |
| Static resource audit | Completed |
| Android heap profiler | Pending device/emulator |
| Native allocation stress test | Pending device/emulator |
| Repeated load/inference/unload test | Pending device/emulator |

## Required runtime leak test

عند توفر Android device/emulator، يجب تنفيذ:

1. تحميل LaMa وتشغيل warm-up.
2. تكرار inpaint 30–100 مرة على fixture ثابت.
3. تكرار cancel أثناء preprocessing وداخل `session.run`.
4. تكرار `loadModel` و`unloadModel`.
5. انتقال Activity إلى background/foreground.
6. أخذ heap/native allocation snapshots بعد كل 10 عمليات.
7. التحقق من ثبات Java heap وnative heap وعدم تراكم cache files.
8. تشغيل LeakCanary للطبقة Java/Kotlin، وAndroid Studio Native Memory Profiler أو Perfetto للـ native allocations.

## Conclusion

تم إغلاق التسريبات المؤكدة في ownership وcleanup لمسار Kotlin/ONNX، وتمت حماية مسارات الاستثناء وlifecycle. النتيجة الحالية **resource-safe by static inspection and build verification**، لكنها ليست شهادة خلو من التسريب runtime؛ يلزم profiler على Android، خصوصًا لأن معظم ذاكرة ONNX وNNAPI native لا تظهر بالكامل في Java heap.
