# Local PatchMatch and Free Watermark

**الحالة:** منفذ مصدريًا، مربوط بمساري Editor وChat، والتحقق على جهاز Android ما زال مطلوبًا.

## المسار المحلي

يستخدم `PatchMatchRemover` في Android أربع مراحل. أولًا يقرأ ألوان زوايا الصورة ويجري نموًا متصلًا محافظًا لقناع الخلفية. ثانيًا يعيّن لكل بكسل خلفية مرجعًا أوليًا من أقرب بذرة. ثالثًا يحسن المراجع بتمريرين من propagation وrandom search على رقع 3×3. رابعًا يجعل البكسلات التي تطابق رقعة خلفية بدرجة كافية شفافة ويحفظ PNG جديدًا.

هذا تنفيذ محلي بالكامل؛ لا توجد شبكة، ولا تنزيل نموذج، ولا Firebase، ولا Supabase، ولا Backend. المسار السريع في `SeikaChannel` يحدد `quality=fast` ويستخدم PatchMatch. المسار الأعلى جودة يستخدم LaMa عند توفره، ويعود إلى PatchMatch عند عدم توفر LaMa.

## Free policy

المستخدم المجاني يملك ثلاث صور في كل شهر UTC. في Editor وChat يُسمح له بإزالة الخلفية عبر PatchMatch فقط. بعد نجاح PatchMatch يُطبق `FreeWatermarkService` النص `PRODUCTCHAT STUDIO  •  FREE` على صورة PNG الناتجة، ثم تُستهلك صورة واحدة من العداد. إذا فشل PatchMatch أو فشل إنشاء watermark، لا تُستهلك الحصة ولا تُضاف النتيجة إلى التاريخ.

## Fixtures

توجد fixtures قابلة لإعادة الإنتاج في `test/fixtures/patchmatch/`. يمكن إعادة توليدها بالأمر التالي:

```bash
python3 tooling/generate_patchmatch_fixtures.py
```

تختبر اختبارات Dart الحالية وجود الصور، حفظ الأبعاد، إنتاج PNG، وإنشاء مسار watermark. أما جودة قناع alpha وأداء Kotlin فيتطلبان Android instrumentation لأن `PatchMatchRemover` كود Kotlin native.

## حدود التحقق

لم يتم اعتماد PatchMatch كـRelease-ready بعد. يلزم تشغيل Android build على آخر commit، اختبار portrait وlandscape، قياس latency والذاكرة، فحص حدود الألوان والخلفيات متعددة الدرجات، والتحقق من أن foreground الرفيع لا يُحذف. يجب أيضًا تسجيل Android API وABI وRAM وcommit وchecksum في تقرير الجهاز.
