# إعداد Android — الإضافات المطلوبة

هذا الملف يشرح **بالضبط** ما يجب إضافته إلى مجلد `android/` الذي ينشئه أمر
`flutter create` تلقائيًا. لم يتم توليد مجلد `android/` بالكامل يدويًا هنا؛
لأن محتواه (إصدارات Gradle/Kotlin/AGP) يعتمد على نسخة Flutter المثبّتة لديك
تحديدًا، وتوليده يدويًا بدون تجربته فعليًا قد يعطيك نسخًا قديمة أو غير
متوافقة. لذلك الأصح دائمًا: دع `flutter create` يولّد أساسًا صحيحًا 100%،
ثم أضف عليه ما يلي.

---

## 1) الأذونات — `android/app/src/main/AndroidManifest.xml`

افتح الملف وأضف هذه الأسطر **داخل وسم `<manifest>`، قبل وسم `<application>`**:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
```

ثم **داخل وسم `<application>`** (بجانب وسم `<activity>` الموجود أصلًا)
أضف هذا الاستقبال — وهو ما يجعل التطبيق **مجرّد كونه مثبّتًا** يكفي كي
تعمل خاصية "إعادة الجدولة عند إعادة التشغيل" التي بناها `flutter_local_notifications`
تلقائيًا (لا حاجة لكتابة أي كود Kotlin/Java يدويًا):

```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

> إذا لاحظت أن هذا الاستقبال أُضيف تلقائيًا بالفعل (بعض إصدارات الحزمة
> تدمجه عبر Manifest Merger)، فلا ضرر من تكراره — Gradle سيدمجهما بأمان.

---

## 2) `android/app/build.gradle` (أو `build.gradle.kts`)

تأكد من:

```gradle
android {
    defaultConfig {
        minSdkVersion 23        // أو flutter.minSdkVersion إن كانت أعلى من 23
        // ...
    }
    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
}

dependencies {
    coreLibraryDesugaringEnabled true
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
```

`coreLibraryDesugaring` مطلوبة لأن `flutter_local_notifications` يستخدم
واجهات `java.time` الحديثة داخليًا.

---

## 3) نغمات المنبه المدمجة — نسخ الملفات الصوتية

هذا المشروع يأتي مع 4 نغمات منبّه **حقيقية وجاهزة** (مولّدة رقميًا، بدون
أي حقوق ملكية) في `android_setup/raw_sounds/`. انسخها إلى:

```
android/app/src/main/res/raw/tone_classic_beep.wav
android/app/src/main/res/raw/tone_gentle_chime.wav
android/app/src/main/res/raw/tone_digital_alarm.wav
android/app/src/main/res/raw/tone_soft_bell.wav
```

(أنشئ مجلد `res/raw/` إذا لم يكن موجودًا). هذه الملفات موجودة **أيضًا**
في `assets/sounds/` — تلك النسخة يستخدمها التطبيق فقط لتشغيل "معاينة"
الصوت داخل شاشة اختيار النغمة؛ أما نسخة `res/raw/` فهي التي يستخدمها
نظام Android فعليًا عند رنين المنبه (لأن قناة الإشعار على أندرويد يجب أن
تُنشأ بصوت "raw resource" حقيقي، ولا يمكنها قراءة أصول Flutter مباشرة).

### كيف تضيف نغمة مدمجة جديدة؟

1. ضع ملف `.wav` أو `.mp3` (اسمه بأحرف صغيرة وأرقام و`_` فقط، بدون امتداد
   عند الإشارة إليه) في `android/app/src/main/res/raw/`.
2. أضف نفس الملف في `assets/sounds/` (للمعاينة داخل التطبيق) وأضف مساره
   في `pubspec.yaml` تحت `flutter: assets:`.
3. أضف سطرًا واحدًا في `lib/core/constants/builtin_tones.dart`:
   ```dart
   BuiltInTone('my_new_tone', 'اسم النغمة بالعربي', 'my_new_tone_raw_filename'),
   ```
   هذا كل ما يلزم — لا حاجة لتعديل أي مكان آخر في الكود.

---

## 4) اختبار المنبهات فعليًا على جهاز حقيقي

الموثوقية الكاملة للمنبهات في الخلفية هي **أحد أشهر التحديات في نظام
أندرويد نفسه** — حتى تطبيقات المنبه الكبرى تتأثر بهذا على أجهزة معيّنة
(شاومي / هواوي / أوبو بشكل خاص) بسبب "تحسين البطارية" العدواني من الشركة
المصنّعة. للحصول على أفضل موثوقية:

- من إعدادات التطبيق داخل Life OS، اضغط "استثناء تحسين البطارية" لفتح
  إعدادات النظام واستثناء التطبيق.
- امنح إذن "الإشعارات" و"المنبهات والتذكيرات الدقيقة" عند أول طلب لهما.
- على أجهزة شاومي/هواوي تحديدًا، فعّل "التشغيل التلقائي" (Autostart) لهذا
  التطبيق من إعدادات النظام الخاصة بالشركة المصنّعة.

---

## 5) أيقونة التطبيق (اختياري)

لم يُضمَّن تصميم أيقونة مخصصة في هذا التسليم (خارج النطاق الحالي). لإضافة
أيقونة لاحقًا، أسهل طريقة هي حزمة `flutter_launcher_icons`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.0

flutter_launcher_icons:
  android: true
  image_path: "assets/icon/icon.png"
```

ثم: `dart run flutter_launcher_icons`.
