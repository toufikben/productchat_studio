# Release signing and Internal Testing

هذه الوثيقة تشرح إعداد توقيع Android فقط. لا تُرفع كلمات المرور أو ملفات keystore إلى Git أو تُرسل داخل Issues أو Pull Requests.

## الإعداد المحلي

أنشئ Upload Key خارج المستودع، ثم أنشئ الملف `android/key.properties` محليًا بهذا الشكل:

```properties
storeFile=/absolute/path/to/upload-keystore.jks
keyAlias=upload
storePassword=REPLACE_LOCALLY
keyPassword=REPLACE_LOCALLY
```

الملف محمي بواسطة `.gitignore`. عند تنفيذ `flutter build appbundle --release` سيستخدم Gradle هذا المفتاح. إذا لم يوجد الملف، يفشل بناء Release برسالة واضحة بدل استخدام Debug signing.

## GitHub Actions لاحقًا

إذا تقرر بناء AAB داخل GitHub Actions، أضف الأسرار بنفسك إلى إعدادات المستودع، ثم أنشئ workflow يكتبها مؤقتًا إلى runner فقط:

- `ANDROID_KEYSTORE_BASE64`: محتوى keystore مشفرًا بـ Base64.
- `ANDROID_KEY_ALIAS`.
- `ANDROID_KEY_PASSWORD`.
- `ANDROID_STORE_PASSWORD`.

يجب أن ينشئ workflow ملف `android/key.properties` وملف keystore داخل runner، ثم يحذف الملفين في خطوة `always`. لا تضع القيم نفسها في YAML أو في مستودع GitHub.

الريبو يحتوي الآن على workflow يدوي باسم `Build signed Android App Bundle`. بعد إضافة الأسرار، افتح تبويب **Actions** في GitHub، اختر workflow، اضغط **Run workflow**، وانتظر نجاح `Analyze and test` و`Build signed release AAB`. نزّل artifact باسم `productchat-studio-release-aab` ثم ارفع ملف `app-release.aab` إلى Google Play Console.

## بوابة التحقق

بعد إعداد المفتاح محليًا:

```bash
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

ثم افحص الملف الناتج في:

```text
build/app/outputs/bundle/release/app-release.aab
```

قبل رفعه إلى Internal Testing، تحقق من أن `versionCode` أعلى من آخر نسخة مقبولة في Google Play Console وأن `applicationId` هو `com.productchat.aiphotostudio`.

## حدود هذه المرحلة

لا تُعتبر المنتجات أو Sandbox Billing جاهزة بمجرد نجاح بناء AAB. يجب أولًا تثبيت النسخة من Internal Testing، ثم اختبار التشغيل الأساسي، وبعدها إنشاء منتجات Google Play IDs المطابقة للكود.
