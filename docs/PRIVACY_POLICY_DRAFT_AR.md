# سياسة خصوصية سكينة — النسخة المعتمدة للنشر

النسخة العامة المنشورة هي `site/privacy.html` (عربي + إنجليزي) عبر GitHub Pages:
`https://khaled-shahien.github.io/Quran_App/privacy.html`

هذا الملف يبقى مرجعاً داخلياً. أي تعديل على البيانات التي يعالجها التطبيق
يستلزم تحديث `site/privacy.html` وتاريخ السريان وإجابات Data Safety معاً
(انظر `PLAY_CONSOLE_GUIDE_AR.md`).

- تاريخ السريان: 9 نوفمبر 2026
- الناشر: Khaled Shahien
- التواصل: shahienk856@gmail.com (سيُستبدل لاحقاً بإيميل دعم مخصص؛ عند تغييره حدّث
  الصفحة وبيانات المطوّر في Play Console)

## ملخص ما تقوله السياسة (يجب أن يظل مطابقاً للتنفيذ)

| الموضوع | ما تقوله السياسة | مصدر التحقق في الكود |
|---|---|---|
| الحساب | لا يوجد حساب ولا تسجيل دخول | `APP_SCOPE_AND_AUTH.md` |
| البيانات المحلية | العلامات والمفضلة والختمة والإعدادات والموقع المختار على الجهاز فقط | SharedPreferences |
| الموقع | اختياري؛ المواقيت والقبلة تُحسب على الجهاز ولا تُرسل الإحداثيات | `prayer_times_repository_impl.dart` (adhan_dart) |
| الإشعارات | محلية، بلا إشعارات عن بُعد | `notification_service.dart` |
| تقارير الأعطال | Crashlytics اختياري ومتوقف افتراضياً، احتفاظ 90 يوماً | `monitoring_service.dart`، `AndroidManifest.xml` |
| الإحصاءات والإعلانات | لا توجد | `DEPENDENCIES_AND_LICENSES.md` |
| الخدمات الخارجية | تلاوات Quran.com، YouTube، المقالات، الروابط الخارجية بعد التأكيد | `.env`، `recitation_reciters.json` |
