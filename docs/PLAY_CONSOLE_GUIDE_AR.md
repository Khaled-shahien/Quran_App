# دليل رفع سكينة على الاختبار المغلق في Google Play

كل الإجابات هنا مبنية على الكود الحالي. لو غيّرت سلوك التطبيق (أضفت خدمة، أو إحصاءات، أو إعلانات)
حدّث هذا الدليل وسياسة الخصوصية وإجابات Data Safety معاً.

---

## 0. قبل فتح Play Console (على جهازك)

1. **انقل Flutter للقناة المستقرة:**
   ```powershell
   flutter channel stable
   flutter upgrade
   ```
   ثبّتنا CI على `3.47.9` stable. لو فشل اختبار الـ golden الخاص بالإعدادات بسبب اختلاف بسيط في الرسم بين beta وstable،
   أعد توليد الصور على stable (`flutter test --update-goldens test/features/settings/...`) وراجعها بعينك.
2. **ارفع التعديلات على GitHub** (commit + push على `main`).
3. **فعّل GitHub Pages:** Settings → Pages → Source: **GitHub Actions**.
   الـ workflow `pages.yml` بينشر مجلد `site/` بس، ورابط السياسة هيبقى:
   `https://khaled-shahien.github.io/quran_app/privacy.html`
   - افتح الرابط في المتصفح واتأكد إنه شغال قبل ما تحطه في Play Console.
   - Pages المجاني محتاج الريبو يكون **Public**. لو الريبو Private، يا إما تخليه Public،
     يا إما تعمل ريبو صغير منفصل Public فيه مجلد `site/` بس.
4. **ابنِ النسخة الموقّعة:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\build_release.ps1
   ```
   الناتج: `build\app\outputs\bundle\release\app-release.aab` ونسخة أرشيف في `build\release-archive\1.0.0_build1\`.
   **احتفظ بنسخة من الأرشيف ومن ملف keystore وكلمات السر برّه الريبو** (Google Drive مثلاً). لو ضاع مفتاح الرفع،
   تقدر تطلب تغييره من Play، لكن هتتعطل لحد ما الطلب يتقبل.
5. **صور الشاشة:** صوّر من النسخة الموقّعة على موبايل حقيقي، واختار مدينة اختبار (القاهرة مثلاً) مش موقعك الحقيقي.
   القائمة موجودة في `STORE_LISTING_AR.md`. المطلوب من 2 لـ 8 صور، بنسبة 9:16، ويُفضّل 1080×1920.

---

## 1. إنشاء التطبيق
Play Console → **Create app**

| الحقل | القيمة |
|---|---|
| App name | `سكينة — القرآن والأذكار` |
| Default language | Arabic – ar |
| App or game | App |
| Free or paid | Free (لا يمكن تحويله لمدفوع لاحقاً) |
| Declarations | وافق على Developer Program Policies وUS export laws |

---

## 2. Store listing (Grow → Store presence → Main store listing)

| الحقل | القيمة |
|---|---|
| App name | `سكينة — القرآن والأذكار` |
| Short description | `القرآن والأذكار ومواقيت الصلاة والقبلة ومتابعة الختمة في تطبيق واحد.` |
| Full description | انسخ قسم Full description من `STORE_LISTING_AR.md` |
| App icon | `store/play_icon_512.png` |
| Feature graphic | `store/feature_graphic_1024x500.png` |
| Phone screenshots | من الخطوة 0.5 |
| Category | Lifestyle (أو Books & Reference) |
| Tags | Religion, Quran |
| Email | shahienk856@gmail.com |
| Website | `https://khaled-shahien.github.io/quran_app/` |

---

## 3. App content (Policy → App content)

### Privacy policy
`https://khaled-shahien.github.io/quran_app/privacy.html`

### App access
**All functionality is available without special access** (مفيش تسجيل دخول).

### Ads
**No, my app does not contain ads.**

### Content rating (استبيان IARC)
- Email: shahienk856@gmail.com
- Category: **Reference, News, or Educational**
- أجب **No** على كل الأسئلة: عنف، محتوى جنسي، لغة نابية، مخدرات، قمار، محتوى ينشئه المستخدمون، مشاركة الموقع مع مستخدمين آخرين، مشتريات رقمية.
- النتيجة المتوقعة: مناسب لكل الأعمار (Everyone / PEGI 3).

### Target audience and content
- Target age groups: **13–15، 16–17، 18+**
  (لو اخترت أقل من 13، هتنطبق عليك سياسة Families بمتطلبات إضافية على الـ SDKs والإفصاحات، والتطبيق مش مصمم للأطفال تحديداً.)
- Appeals to children: **No**.

### News app
**No**.

### Data safety

**Data collection and security**
| السؤال | الإجابة |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** |
| Which account creation methods does your app support? | **My app does not allow users to create an account** |
| Do you provide a way for users to request that their data is deleted? | **Yes** — بالإيميل shahienk856@gmail.com (اكتب ده في رابط/وصف طلب الحذف لو اتطلب) |

**Data types** — اختار بس اللي تحت:

| الفئة | النوع | Collected | Shared | Ephemeral | Required/Optional | Purpose |
|---|---|---|---|---|---|---|
| App info and performance | Crash logs | Yes | No | No | **Optional** (المستخدم يفعّلها بنفسه) | Analytics |
| App info and performance | Diagnostics | Yes | No | No | **Optional** | Analytics |
| Device or other IDs | Device or other IDs | Yes | No | No | **Optional** | Analytics |

**ما تعلّمش عليه Collected:**
- **Location:** بيتحسب على الجهاز وما بيتبعتش لأي خادم. حسب تعريف Google، المعالجة على الجهاز بس مش "جمع".
- Personal info، Financial، Messages، Photos/Videos، Audio، Files، Calendar، Contacts، App activity، Web browsing.

**Shared = No:** Firebase بيعالج البيانات كمقدّم خدمة نيابةً عنك، وده مش "مشاركة" في تعريف Google.

### Government apps / Financial features / Health
كلها **No / لا ينطبق**.

### Foreground service permissions
Play هيطلب ده بعد رفع الـ AAB، لأن التطبيق فيه `FOREGROUND_SERVICE_MEDIA_PLAYBACK`.
- Type: **Media playback**
- الوصف:
  > Sakina plays Quran recitation chosen by the user. Playback continues when the app is in the background or the screen is locked, with play/pause controls in the media notification and on the lock screen. The service runs only while the user is listening and stops when playback stops.
- فيديو: سجّل فيديو قصير (30–60 ثانية) على الموبايل: افتح سورة ← شغّل التلاوة ← اقفل الشاشة ← التلاوة مستمرة ← استخدم أزرار التحكم من شاشة القفل. ارفعه على YouTube كـ **Unlisted** وحط الرابط.

### Exact alarms
التطبيق بيستخدم `SCHEDULE_EXACT_ALARM` لتنبيهات الصلاة، وبيشتغل حتى لو المستخدم ما منحوش (وبيشرح للمستخدم من الإعدادات).
لو Play Console طلب تصريح، الاستخدام الأساسي هو: **Alarm/timer — prayer time alarms scheduled by the user**.

### Advertising ID
**No** — التطبيق ما بيستخدمش معرّف الإعلانات. لو Play نبّهك إن الـ manifest فيه `AD_ID`، ابعتلي التنبيه.

---

## 4. الاختبار المغلق (Test and release → Testing → Closed testing)

1. **Create track** (أو استخدم Alpha الافتراضي).
2. **Countries/regions:** اختار الدول اللي فيها المختبرين (مصر على الأقل).
3. **Testers:** اعمل Google Group أو قائمة إيميلات، وأضف **12 مختبِر على الأقل** (يُفضّل 15–20 احتياطي).
   لازم كل واحد يفتح رابط الـ opt-in ويوافق، وبعدين ينزّل التطبيق من Play.
4. **Create new release:**
   - Play App Signing: وافق (Google بتحتفظ بمفتاح التوقيع، وانت بتوقّع بمفتاح الرفع).
   - ارفع `app-release.aab`.
   - ملاحظات الإصدار (ar):
     > النسخة التجريبية الأولى من سكينة: القرآن دون اتصال، مواقيت الصلاة والتنبيهات، القبلة، الأذكار والأدعية، والختمة. نرجو تجربة التنبيهات والتطبيق مقفول وإرسال ملاحظاتكم.
5. **App bundle explorer → Downloads:** ارفع `mapping.txt` من الأرشيف كـ ReTrace mapping file (deobfuscation).
6. **Send for review.** المراجعة الأولى ممكن تاخد من ساعات لحد كام يوم.

### قاعدة الـ 12 مختبِر / 14 يوم
لو حسابك **شخصي واتعمل بعد 13 نوفمبر 2023**: ما تقدرش تطلب الإنتاج إلا بعد ما 12 مختبِر على الأقل
يفضلوا مشتركين **14 يوم متواصل**، ويكونوا بيستخدموا التطبيق فعلاً. وبعدها **Apply for production**.
لو حسابك **منظمة** أو حساب شخصي أقدم، القاعدة دي ما تنطبقش عليك.

استغل الـ 14 يوم في تنفيذ `MANUAL_QA_CHECKLIST_AR.md` و`DEVICE_QA_AND_OPERATIONS.md` على أجهزة المختبرين،
واطلب منهم يجربوا: وصول التنبيهات والتطبيق مقفول، وبعد إعادة التشغيل، وعلى Xiaomi وSamsung.

---

## 5. بعد أول رفع مباشرة

1. **تقييد مفتاح YouTube API:**
   Play Console → Test and release → **App integrity** → App signing → انسخ **SHA-1 لمفتاح توقيع التطبيق (App signing key)**.
   بعدين Google Cloud Console → APIs & Services → Credentials → مفتاح YouTube:
   - Application restrictions: **Android apps** → أضف `app.sakina.quran` + SHA-1 بتاع App signing key
     (وكمان SHA-1 بتاع مفتاح الرفع لو بتجرّب نسخ موقّعة محلياً).
   - API restrictions: **YouTube Data API v3** بس.
2. **Firebase Crashlytics:** من الإعدادات على موبايل اختبار فعّل تقارير الأعطال، واتأكد إن التقرير بيوصل للكونسول.
   ارفع رموز Dart لو عايز تقارير مقروءة:
   `firebase crashlytics:symbols:upload --app=1:139097045866:android:cf6b051ae49d536b268313 build/symbols/android`
3. **Pre-launch report:** راجع التقرير التلقائي من Play (أعطال، مشاكل وصول) وصلّح أي حاجة حرجة.

---

## 6. قبل طلب الإنتاج (Production)
- [ ] اعتماد مصادر المحتوى (`CONTENT_SOURCES_REVIEW_AR.md`) ونجاح `verify_content.py --require-approved`.
- [ ] موافقة Quran.com على API التلاوات.
- [ ] تنفيذ قائمة الاختبار اليدوي على أجهزة حقيقية.
- [ ] رفع `versionCode` لأي نسخة جديدة (`version: 1.0.1+2` في `pubspec.yaml`)، لأن Play يرفض تكرار نفس الرقم.
- [ ] لو اتعمل إيميل دعم منفصل: حدّث `site/privacy.html` و`site/index.html` وبيانات Store listing.
