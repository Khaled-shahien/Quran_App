# سياسة خصوصية سكينة — النسخة المعتمدة للنشر

النسخة العامة المنشورة هي `site/privacy.html` (عربي + إنجليزي) عبر GitHub Pages:
`https://khaled-shahien.github.io/Quran_App/privacy.html`

هذا الملف يبقى مرجعاً داخلياً. أي تعديل على البيانات التي يعالجها التطبيق
يستلزم تحديث `site/privacy.html` وتاريخ السريان وإجابات Data Safety معاً
(انظر `PLAY_CONSOLE_GUIDE_AR.md`).

- تاريخ السريان: 18 نوفمبر 2026
- الناشر: Khaled Shahien
- التواصل: shahienk856@gmail.com (سيُستبدل لاحقاً بإيميل دعم مخصص؛ عند تغييره حدّث
  الصفحة وبيانات المطوّر في Play Console)

## ملخص ما تقوله السياسة (يجب أن يظل مطابقاً للتنفيذ)

| الموضوع | ما تقوله السياسة | مصدر التحقق في الكود |
|---|---|---|
| الحساب | لا يوجد حساب ولا تسجيل دخول | `APP_SCOPE_AND_AUTH.md` |
| البيانات المحلية | العلامات والمفضلة والختمة والإعدادات والموقع المختار، والآيات المحفوظة والملاحظات، والحفظ، والختمات الجماعية، وأوقات الإقامة، على الجهاز فقط | SharedPreferences، `sakina.db` |
| سجلّ الصلاة والصيام | ملف منفصل خارج النسخ الاحتياطي السحابي (PV-3) | `sakina_private.db`، `data_extraction_rules.xml`، `backup_rules.xml` |
| التصدير | ملف يحفظه المستخدم، ويمكن تشفيره بكلمة مرور (Argon2id + AES-256-GCM) | `user_data_backup.dart`، `backup_encryption.dart` |
| المشاركة | عبر قائمة المشاركة في النظام فقط وبضغطة المستخدم (آية، جدول، رمز ختمة) | `verse_share.dart`، `month_timetable_screen.dart`، `group_khatma_screen.dart` |
| أذونات اختيارية | «عدم الإزعاج» لصمت ما بعد الأذان، والشاشة الكاملة لمنبّه الفجر | `packages/sakina_alarms` |
| الموقع | اختياري؛ المواقيت والقبلة تُحسب على الجهاز ولا تُرسل الإحداثيات | `prayer_times_repository_impl.dart` (adhan_dart) |
| الإشعارات | محلية، بلا إشعارات عن بُعد | `notification_service.dart` |
| تقارير الأعطال | Crashlytics اختياري ومتوقف افتراضياً، احتفاظ 90 يوماً | `monitoring_service.dart`، `AndroidManifest.xml` |
| الإحصاءات والإعلانات | لا توجد | `DEPENDENCIES_AND_LICENSES.md` |
| الخدمات الخارجية | تلاوات Quran.com، YouTube، المقالات، الروابط الخارجية بعد التأكيد | `.env`، `recitation_reciters.json` |
