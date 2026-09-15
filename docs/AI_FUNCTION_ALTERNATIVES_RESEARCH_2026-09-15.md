# دراسة بدائل Qwen حسب وظيفة الصورة

**المشروع:** ProductChat Studio  
**التاريخ:** 2026-09-15  
**القرار المختصر:** لا نبحث عن نموذج واحد صغير ليحل محل Qwen في كل شيء. نقسم تجربة المستخدم إلى وظائف مستقلة، ونستخدم لكل وظيفة أبسط حل يحقق الجودة المطلوبة على Android. يبقى Qwen ميزة متقدمة للتعديل المحادثي العام، بينما تُنفَّذ أغلب العمليات المتخصصة محلياً دون API.

## النتيجة التنفيذية

| الوظيفة | المسار المحلي المقترح | المسار الاحتياطي | القرار الأولي |
|---|---|---|---|
| إزالة الخلفية | MODNet Photographic عبر ONNX Runtime Android | MediaPipe/ML Kit أو API اختياري | اختبار MODNet على صور المنتجات؛ لا نعتمد RMBG تجارياً دون ترخيص BRIA |
| القناع | Mask Painter + MobileSAM | قناع يدوي دائماً | MobileSAM مساعد لا بديل عن inpainting |
| Inpainting | MI-GAN عبر ONNX | OpenCV للعيوب الصغيرة أو API للحالات الصعبة | تنفيذ PoC على Android قبل اعتماده |
| رفع الدقة | Real-ESRGAN-General-x4v3 | FSRCNN-small للأجهزة الضعيفة | قياس الجودة والحجم على أجهزة حقيقية |
| الظل | Compositor حتمي مبني على alpha mask | ML Kit لاستخراج القناع فقط | لا نحتاج AI في الإصدار الأول |
| تحسين الإضاءة | Exposure/curves محلية | Zero-DCE كتجربة غير تجارية فقط | نسميها تحسين إضاءة لا Relight فيزيائياً |
| التلوين | DDColor-Tiny بعد تصدير ONNX | API اختياري | لا نعتمد قبل إثبات الحجم والترخيص |
| التعديل المحادثي العام | Qwen عبر Backend وWaveSpeed | FLUX Kontext أو Gemini API للمقارنة | لا نشغّل Qwen أو FLUX داخل الهاتف |

## لماذا هذا التقسيم أفضل؟

Qwen-Image-Edit نموذج عام كبير، بينما كثير من عمليات التطبيق محددة. إزالة الخلفية تحتاج alpha matte، ورفع الدقة يحتاج super-resolution، وإضافة الظل تحتاج تركيباً هندسياً، بينما inpainting يحتاج قناعاً ونموذج إكمال. استخدام Qwen لكل هذه الوظائف يزيد التكلفة وزمن الانتظار ويجعل التطبيق معتمداً على الشبكة دون ضرورة.

> وجود نموذج على GitHub أو Hugging Face، وحتى وجود ملف ONNX، لا يثبت جاهزيته لـ Android. الاعتماد الإنتاجي يتطلب artifact محدداً، وفحص operators، وتشغيلاً فعلياً على ABI وAPI المستهدفين، وقياس الذاكرة والزمن، وتدقيق ترخيص الكود والأوزان.

## 1. إزالة الخلفية

**MODNet Photographic** هو المرشح المحلي الأول للصور الثابتة لأنه ينتج alpha matte، وليس مجرد قناع ثنائي. توجد نسخة ONNX قابلة للتنزيل بحجم تقريبي 25 MB، ويُذكر ترخيص Apache-2.0 للمشروع. يجب اختبار الشعر، الحواف الشفافة، الأجسام غير البشرية، والظلال قبل اعتماده؛ النتائج المنشورة لا تضمن جودة صور المنتجات.

**RVM MobileNetV3** مناسب أكثر للفيديو المتتابع لأنه يستخدم temporal memory، لكنه يتطلب إدارة حالات recurrent وترخيصه GPL-3.0، ولذلك لا نعتمده في تطبيق تجاري مغلق المصدر دون مراجعة قانونية. MediaPipe Selfie Segmentation أسهل تكاملاً على Android، لكنه مخصص أساساً لقناع الأشخاص ولا يساوي alpha matting عالي الدقة.

لا نعتمد RMBG-1.4 داخل التطبيق التجاري قبل الحصول على ترخيص BRIA. وسم ONNX في بطاقة Hugging Face ليس دليلاً كافياً على توافق Android.

## 2. القناع وInpainting

يبقى **Mask Painter** متاحاً دائماً لأن المستخدم يستطيع تصحيح القناع يدوياً. يمكن إضافة **MobileSAM** لتحديد الكائن بالنقطة أو المربع. MobileSAM مرشح عملي، لكن تشغيله على Android يحتاج تحققاً من graph وذاكرة النموذج ومرحلة post-processing؛ لا توجد حزمة Android رسمية جاهزة في المصادر المفحوصة.

بعد الحصول على القناع، يكون **MI-GAN** المرشح المحلي الأول للإكمال. مشروعه يوفر pipeline ONNX مناسباً للصور والقناع بصيغة uint8، وترخيص الكود والأوزان مذكور كـ MIT. لا ينشر المصدر حجماً موحداً للملف، لذلك يجب قياسه وتثبيت checksum داخل المشروع.

يبقى LaMa مرجع جودة أو خياراً محلياً إذا كان الحجم مقبولاً. نسخة ONNX الطرف الثالث المعلنة بحجم 208 MB ليست artifact رسمياً من فريق LaMa. أما OpenCV Telea/Navier–Stokes فهو fallback خفيف للعيوب الصغيرة، لكنه لا يفهم المعنى ولا يعيد بناء جسم كبير.

## 3. رفع الدقة

يوفر **Real-ESRGAN-General-x4v3** أفضل توازن مبدئي. صفحة Qualcomm AI Hub تذكر حجماً يقارب 4.65 MB بصيغة float أو 1.25 MB بصيغة w8a8، مع 1.21M parameter، وتثبت مسار التصدير إلى TFLite أو ONNX Runtime. يجب اختبار التوافق على أجهزة Qualcomm وغير Qualcomm، لأن توفر artifact لا يضمن دعماً موحداً لكل الأجهزة.

عند أولوية الحجم والسرعة، يمكن استخدام FSRCNN-small x4 أو ESPCN. أوزان FSRCNN-small صغيرة جداً، لكن الجودة أضعف في الضجيج والتفاصيل غير الموجودة. Real-ESRGAN-x4plus أقوى، لكنه أكبر بكثير؛ صفحة Qualcomm تذكر 63.9 MB float أو 16.7 MB w8a8.

## 4. إضافة الظل

لا نحتاج نموذج AI في الإصدار الأول. إذا كانت الصورة تملك alpha mask موثوقاً، ننشئ الظل محلياً عبر طبقتين: contact shadow ضيقة داكنة وambient shadow أوسع مع blur. نستخدم affine projection أو ellipse قابلة للضبط ثم نمزج النتيجة بـ SRC_OVER. هذا المسار حجمه صفراً تقريباً، سريع، قابل للاختبار، ولا يرسل الصورة إلى خادم.

يمكن استخدام ML Kit Subject Segmentation كـ fallback لاستخراج قناع المنتج، لكنه لا يصنع الظل بنفسه. لا نعتمد monocular depth أو relighting فيزيائياً في الإصدار الأول؛ صورة RGB واحدة لا تثبت مستوى الأرض أو اتجاه الضوء.

## 5. تحسين الإضاءة والتلوين

يجب الفصل بين **تحسين الإضاءة** و**Relight**. يمكن تنفيذ exposure وcurves وwhite balance محلياً. Zero-DCE مرشح صغير لتصحيح الإضاءة، لكنه غير تجاري افتراضياً حسب الترخيص المذكور، ولا يعيد توزيع مصدر الضوء فيزيائياً. لذلك لا نسميه Relight إلا بعد تحديد المقصود بدقة.

للتلوين، DDColor-Tiny مرشح واعد بعد تصديره إلى ONNX وتشغيله عبر ONNX Runtime Android. حجم النسخة Tiny غير مثبت في المصادر المفحوصة، ولا يجوز استخدام أرقام DDColor-L لتقدير حجمه. يجب تثبيت binary وchecksum وقياس الذاكرة قبل اعتماده.

## 6. التعديل المحادثي العام

يبقى **Qwen-Image-Edit عبر WaveSpeed** أفضل تطابق للطلبات العامة التي تتضمن إضافة عناصر أو حذفها أو تغيير الأسلوب أو تعديل نص داخل الصورة. لا يمكن تشغيله عملياً داخل الهاتف؛ النموذج مبني على 20B parameter، وحجمه ومتطلبات الذاكرة أكبر بكثير من نطاق Android المعتاد.

يجب أن يمر Qwen عبر Backend يحمي المفتاح ويفرض Credits وحدوداً يومية. يمكن اختبار FLUX.1 Kontext أو Gemini API للمقارنة، لكن FLUX Kontext dev ليس خياراً تجارياً محلياً تلقائياً، ووجود ONNX لا يعني توافق Android. SDXL Inpainting مناسب عندما يملك التطبيق قناعاً واضحاً، لكنه ليس بديلاً عاماً للتعديل المحادثي.

## خطة التحقق قبل اعتماد أي نموذج

أولاً، نثبت نسخة artifact وchecksum وpreprocessing وpostprocessing وترخيص الكود والأوزان. ثانياً، نختبر جهازاً منخفضاً ومتوسطاً وعالياً مع API levels وABI المستهدفة. ثالثاً، نسجل p50 وp95 للزمن، peak RAM، حجم AAB، الحرارة، واستهلاك البطارية. رابعاً، نستخدم مجموعة صور حقيقية تتضمن شعرًا وحوافاً شفافة وأجساماً لامعة وخلفيات معقدة ونصوصاً عربية.

كل مسار يجب أن يملك fallback. فشل MODNet لا يمنع إزالة الخلفية يدوياً، وفشل MobileSAM لا يمنع Mask Painter، وفشل MI-GAN لا يمنع OpenCV للعيوب الصغيرة، وفشل الشبكة لا يمنع حفظ الصور المحلية. لا نعلن ميزة “AI محلية” قبل نجاحها على جهاز Android فعلي.

## القرار التجاري والتقني

الإصدار المتوازن هو: **MODNet + Mask Painter/MI-GAN بعد PoC + Real-ESRGAN-General-x4v3 + shadow compositor حتمي + DDColor-Tiny بعد benchmark + Qwen عبر Backend**. بهذا الشكل يدفع التطبيق تكلفة Qwen فقط عند استخدام التعديل العام، بينما تبقى العمليات المتخصصة الأساسية مجانية ومحلية.

لا نضيف نموذجاً صغيراً بجودة أقل ونقدمه على أنه بديل Qwen. إذا لم تتوفر ميزانية Backend أو WaveSpeed، نخفي ميزة التعديل المحادثي ونطلق الوظائف المحلية المتخصصة بدلاً من تعريض التطبيق لتكلفة API أو مفتاح مكشوف.

## المراجع

[1]: https://github.com/ZHKKKe/MODNet "MODNet official repository"
[2]: https://github.com/PeterL1n/RobustVideoMatting "Robust Video Matting official repository"
[3]: https://developers.google.com/edge/mediapipe/solutions/vision/image_segmenter/android "Google MediaPipe Image Segmenter for Android"
[4]: https://github.com/chaoningzhang/mobilesam "MobileSAM official repository"
[5]: https://github.com/Picsart-AI-Research/MI-GAN "MI-GAN official repository"
[6]: https://github.com/advimman/lama "LaMa official repository"
[7]: https://docs.opencv.org/4.x/df/d3d/tutorial_py_inpainting.html "OpenCV inpainting documentation"
[8]: https://aihub.qualcomm.com/iot/models/real_esrgan_general_x4v3 "Qualcomm AI Hub Real-ESRGAN General x4v3"
[9]: https://github.com/Saafke/FSRCNN_Tensorflow "FSRCNN TensorFlow repository"
[10]: https://github.com/piddnad/DDColor "DDColor official repository"
[11]: https://github.com/QwenLM/Qwen-Image "Qwen Image official repository"
[12]: https://huggingface.co/Qwen/Qwen-Image-Edit "Qwen Image Edit model card"
[13]: https://wavespeed.ai/models/wavespeed-ai/qwen-image/edit "WaveSpeed Qwen Image Edit API"
[14]: https://bfl.ai/blog/flux-1-kontext-dev "Black Forest Labs FLUX Kontext announcement"
[15]: https://platform.stability.ai/docs/api-reference "Stability AI API reference"
[16]: https://docs.photoroom.com/image-editing-api-plus-plan/ai-relight "Photoroom AI Relight API"
[17]: https://developers.google.com/ml-kit/vision/subject-segmentation/android "Google ML Kit Subject Segmentation for Android"
[18]: https://developer.android.com/reference/android/graphics/Paint#setShadowLayer(float,%20float,%20float,%20int) "Android Paint shadow documentation"
[19]: https://onnxruntime.ai/docs/tutorials/mobile/ "ONNX Runtime mobile documentation"

*ملاحظة: الأسعار والأحجام وتوفر الخدمات قابلة للتغير. يجب إعادة التحقق منها عند تنفيذ كل مرحلة، وعدم hard-code أي سعر أو SLA دون مصدر حالي أو عقد مزود.*

**المؤلف:** Manus AI
