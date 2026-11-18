import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar')];

  /// No description provided for @prayerTitle.
  ///
  /// In ar, this message translates to:
  /// **'أوقات الصلاة'**
  String get prayerTitle;

  /// No description provided for @prayerLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر عرض مواقيت الصلاة'**
  String get prayerLoadError;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @choosePrayerLocation.
  ///
  /// In ar, this message translates to:
  /// **'حدد موقعك لعرض المواقيت'**
  String get choosePrayerLocation;

  /// No description provided for @todayPrayerTimes.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت اليوم'**
  String get todayPrayerTimes;

  /// No description provided for @searchQuran.
  ///
  /// In ar, this message translates to:
  /// **'البحث في القرآن'**
  String get searchQuran;

  /// No description provided for @searchAyah.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن آية'**
  String get searchAyah;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'يمكن البحث دون تشكيل'**
  String get searchHint;

  /// No description provided for @searchEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج. جرّب تعديل كلمات البحث'**
  String get searchEmpty;

  /// Display text used in lib/core/constants/app_constants.dart.
  ///
  /// In ar, this message translates to:
  /// **'سكينة'**
  String get appConstantsMessage1;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق الشامل للقرآن الكريم'**
  String get appStringsMessage1;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق سكينة'**
  String get appStringsMessage2;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعلم الدين الاسلامي عن طريق تصنيفات وملفات وشروحات ومحاضرات..الخ , يوفر أوقات الصلاة وخطب والقرآن الكريم كامل مع توفير تفسير وقراءة بالصوت ,, اكتشف المزيد بنفسك'**
  String get appStringsMessage3;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الآن'**
  String get appStringsMessage4;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ'**
  String get appStringsMessage5;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة الرئيسية'**
  String get appStringsMessage6;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك في سكينة!'**
  String get appStringsMessage7;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'حسناً'**
  String get appStringsMessage8;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get appStringsMessage9;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get appStringsMessage10;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get appStringsMessage11;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get appStringsMessage12;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get appStringsMessage13;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get appStringsMessage14;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get appStringsMessage15;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get appStringsMessage16;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get appStringsMessage17;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get appStringsMessage18;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get appStringsMessage19;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ ما، يرجى المحاولة لاحقاً'**
  String get appStringsMessage20;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت'**
  String get appStringsMessage21;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'حاول مجدداً'**
  String get appStringsMessage22;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'جار التحميل...'**
  String get appStringsMessage23;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'يرجى الانتظار...'**
  String get appStringsMessage24;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات'**
  String get appStringsMessage25;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get appStringsMessage26;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get appStringsMessage27;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'القرآن'**
  String get appStringsMessage28;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'الصلوات'**
  String get appStringsMessage29;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'الأدعية'**
  String get appStringsMessage30;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'التفسير'**
  String get appStringsMessage31;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'تلاوة القرآن'**
  String get appStringsMessage32;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'التقويم الهجري'**
  String get appStringsMessage33;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'آيات قرآنية'**
  String get appStringsMessage34;

  /// Display text used in lib/core/constants/app_strings.dart.
  ///
  /// In ar, this message translates to:
  /// **'تذكير يومي'**
  String get appStringsMessage35;

  /// Display text used in lib/core/navigation/app_router.dart.
  ///
  /// In ar, this message translates to:
  /// **'الختمة الحالية'**
  String get appRouterMessage1;

  /// Display text used in lib/core/navigation/app_router.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح السورة:\nرقم السورة غير صالح.'**
  String get appRouterMessage2;

  /// Display text used in lib/core/navigation/app_router.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح الحديث:\nمعرف الحديث غير صالح.'**
  String get appRouterMessage3;

  /// Display text used in lib/core/navigation/app_router.dart.
  ///
  /// In ar, this message translates to:
  /// **'بداية المصحف'**
  String get appRouterMessage4;

  /// Display text used in lib/core/navigation/app_router.dart.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه'**
  String get appRouterMessage5;

  /// Display text used in lib/core/navigation/app_router.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح السورة\nمن الرابط المباشر.'**
  String get appRouterMessage6;

  /// Display text used in lib/core/navigation/app_router.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح الحديث\nمن الرابط المباشر.'**
  String get appRouterMessage7;

  /// Display text used in lib/core/navigation/main_navigation_shell.dart.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة'**
  String get mainNavigationShellMessage1;

  /// Display text used in lib/core/navigation/main_navigation_shell.dart.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get mainNavigationShellMessage2;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات سكينة'**
  String get notificationServiceMessage1;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات عامة من سكينة'**
  String get notificationServiceMessage2;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات القرآن والأذكار'**
  String get notificationServiceMessage3;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات يومية للأذكار والسور'**
  String get notificationServiceMessage4;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة'**
  String get notificationServiceMessage5;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات أوقات الصلاة الخمس'**
  String get notificationServiceMessage6;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'تجربة التنبيهات'**
  String get notificationServiceMessage7;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه تجريبي تطلبه من الإعدادات للتأكد أن التنبيهات تعمل'**
  String get notificationServiceMessage8;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'تذكير أذكار الصباح'**
  String get notificationServiceMessage9;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت أذكار الصباح. افتح التطبيق للقراءة والمتابعة.'**
  String get notificationServiceMessage10;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'تذكير أذكار المساء'**
  String get notificationServiceMessage11;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت أذكار المساء. افتح التطبيق للقراءة والمتابعة.'**
  String get notificationServiceMessage12;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'تذكير سورة الملك'**
  String get notificationServiceMessage13;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت قراءة سورة الملك. افتح التطبيق للقراءة والمتابعة.'**
  String get notificationServiceMessage14;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'تذكير سورة البقرة'**
  String get notificationServiceMessage15;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت قراءة سورة البقرة. افتح التطبيق للقراءة والمتابعة.'**
  String get notificationServiceMessage16;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت صلاة {value1}'**
  String notificationServiceMessage17(String value1);

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لفتح التطبيق ومتابعة وردك'**
  String get notificationServiceMessage18;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'⏰ تذكير أذكار الصباح'**
  String get notificationServiceMessage19;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت أذكار الصباح. اللهم ما أصبح بك من نعمة أو بأحد من خلقك فمنك وحدك لا شريك لك، فلك الحمد ولك الشكر'**
  String get notificationServiceMessage20;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'⏰ تذكير أذكار المساء'**
  String get notificationServiceMessage21;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت أذكار المساء. أمسينا وأمسى الملك لله، والحمد لله، لا إله إلا الله وحده لا شريك له'**
  String get notificationServiceMessage22;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'⏰ تذكير سورة الملك'**
  String get notificationServiceMessage23;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت قراءة سورة الملك. قال صلى الله عليه وسلم: \"إن سورة من القرآن ثلاثون آية شفعت لرجل حتى غفر له: تبارك الذي بيده الملك\"'**
  String get notificationServiceMessage24;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'⏰ تذكير سورة البقرة'**
  String get notificationServiceMessage25;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت قراءة سورة البقرة. قال صلى الله عليه وسلم: \"اقرأوا سورة البقرة، فإن أخذها بركة وتركها حسرة ولا تستطيعها البطلة\"'**
  String get notificationServiceMessage26;

  /// Display text used in lib/core/widgets/placeholder_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'هذه الميزة تحت التطوير'**
  String get placeholderScreenMessage1;

  /// Display text used in lib/core/widgets/placeholder_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'ستتوفر قريباً إن شاء الله'**
  String get placeholderScreenMessage2;

  /// Display text used in lib/features/duas/presentation/screens/azkar_details_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الرجوع للشاشة السابقة'**
  String get azkarDetailsScreenMessage1;

  /// Display text used in lib/features/duas/presentation/screens/azkar_details_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الرجوع'**
  String get azkarDetailsScreenMessage2;

  /// Display text used in lib/features/duas/presentation/screens/azkar_details_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في تحميل الأذكار'**
  String get azkarDetailsScreenMessage3;

  /// Display text used in lib/features/duas/presentation/screens/azkar_details_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات لهذا القسم حالياً'**
  String get azkarDetailsScreenMessage4;

  /// Display text used in lib/features/duas/presentation/screens/azkar_details_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'ذكر {value1}'**
  String azkarDetailsScreenMessage5(String value1);

  /// Display text used in lib/features/duas/presentation/screens/azkar_details_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'التكرار: {value1}'**
  String azkarDetailsScreenMessage6(String value1);

  /// Display text used in lib/features/duas/presentation/screens/azkar_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الصباح'**
  String get azkarScreenMessage1;

  /// Display text used in lib/features/duas/presentation/screens/azkar_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'أذكار المساء'**
  String get azkarScreenMessage2;

  /// Display text used in lib/features/duas/presentation/screens/azkar_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'أذكار النوم'**
  String get azkarScreenMessage3;

  /// Display text used in lib/features/duas/presentation/screens/azkar_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'بعد الصلاة'**
  String get azkarScreenMessage4;

  /// Display text used in lib/features/duas/presentation/screens/azkar_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الاستيقاظ'**
  String get azkarScreenMessage5;

  /// Display text used in lib/features/duas/presentation/screens/azkar_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'أذكار المسجد'**
  String get azkarScreenMessage6;

  /// Display text used in lib/features/duas/presentation/screens/azkar_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'أدعية مأثورة'**
  String get azkarScreenMessage7;

  /// Display text used in lib/features/duas/presentation/screens/azkar_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'أدعية قرآنية'**
  String get azkarScreenMessage8;

  /// Display text used in lib/features/duas/presentation/screens/azkar_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'دعاء السفر'**
  String get azkarScreenMessage9;

  /// Display text used in lib/features/duas/presentation/screens/azkar_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الرقية الشرعية'**
  String get azkarScreenMessage10;

  /// Display text used in lib/features/duas/presentation/screens/azkar_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'فتح قسم {value1}'**
  String azkarScreenMessage11(String value1);

  /// Display text used in lib/features/duas/presentation/screens/duas_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في تحميل الأدعية'**
  String get duasScreenMessage1;

  /// Display text used in lib/features/duas/presentation/screens/duas_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أدعية حالياً'**
  String get duasScreenMessage2;

  /// Display text used in lib/features/duas/presentation/screens/duas_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'دعاء {value1}'**
  String duasScreenMessage3(String value1);

  /// Display text used in lib/features/hadeath/presentation/providers/hadeath_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تحميل الأحاديث: {value1}'**
  String hadeathProviderMessage1(String value1);

  /// Display text used in lib/features/hadeath/presentation/screens/hadeath_details_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'بِسْمِ اللَّهِ الرَّحْمَِٰ الرَّحِيمِ'**
  String get hadeathDetailsScreenMessage1;

  /// Display text used in lib/features/hadeath/presentation/screens/hadeath_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الأحاديث النبوية'**
  String get hadeathScreenMessage1;

  /// Display text used in lib/features/hadeath/presentation/screens/hadeath_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أحاديث لعرضها'**
  String get hadeathScreenMessage2;

  /// Display text used in lib/features/hadeath/presentation/screens/hadeath_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الحديث {value1}'**
  String hadeathScreenMessage3(String value1);

  /// Display text used in lib/features/khatma/domain/models/khatma_model.dart.
  ///
  /// In ar, this message translates to:
  /// **'صفحة'**
  String get khatmaModelMessage1;

  /// Display text used in lib/features/khatma/domain/models/khatma_model.dart.
  ///
  /// In ar, this message translates to:
  /// **'حزب'**
  String get khatmaModelMessage2;

  /// Display text used in lib/features/khatma/domain/models/khatma_model.dart.
  ///
  /// In ar, this message translates to:
  /// **'جزء'**
  String get khatmaModelMessage3;

  /// Display text used in lib/features/khatma/presentation/providers/khatma_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'ورد الختمة اليومي'**
  String get khatmaProviderMessage1;

  /// Display text used in lib/features/khatma/presentation/providers/khatma_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا تنس وردك اليوم: {value1} (من {value2} إلى {value3})'**
  String khatmaProviderMessage2(String value1, String value2, String value3);

  /// Display text used in lib/features/khatma/presentation/screens/khatma_duration_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'ختمة جديدة'**
  String get khatmaDurationScreenMessage1;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_duration_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'حدد نوع الخطة ووحدة المتابعة ووقت التذكير اليومي'**
  String get khatmaDurationScreenMessage2;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_duration_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'حسب المدة'**
  String get khatmaDurationScreenMessage3;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_duration_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'توزيع تلقائي حتى تاريخ الإتمام'**
  String get khatmaDurationScreenMessage4;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_duration_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'حسب الورد اليومي'**
  String get khatmaDurationScreenMessage5;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_duration_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تحدد مقدار القراءة كل يوم'**
  String get khatmaDurationScreenMessage6;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_duration_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'وحدة التتبع:'**
  String get khatmaDurationScreenMessage7;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_duration_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'صفحة (604)'**
  String get khatmaDurationScreenMessage8;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_duration_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'حزب (60)'**
  String get khatmaDurationScreenMessage9;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_duration_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'جزء (30)'**
  String get khatmaDurationScreenMessage10;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_duration_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'وردك المقترح: {value1} {value2} يومياً'**
  String khatmaDurationScreenMessage11(String value1, String value2);

  /// Display text used in lib/features/khatma/presentation/screens/khatma_duration_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'المدة المتوقعة للإتمام: {value1} يوماً'**
  String khatmaDurationScreenMessage12(String value1);

  /// Display text used in lib/features/khatma/presentation/screens/khatma_duration_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الختمة بنجاح!'**
  String get khatmaDurationScreenMessage13;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_duration_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الاستمرار'**
  String get khatmaDurationScreenMessage14;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_duration_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'مدة الختمة:'**
  String get khatmaDurationScreenMessage15;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_duration_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'{value1} يوماً'**
  String khatmaDurationScreenMessage16(String value1);

  /// Display text used in lib/features/khatma/presentation/screens/khatma_duration_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الورد اليومي:'**
  String get khatmaDurationScreenMessage17;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_duration_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'وقت التذكير:'**
  String get khatmaDurationScreenMessage18;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_location_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'جزء مخصص'**
  String get khatmaLocationScreenMessage1;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_location_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء تحديد المكان أو الجزء الذي تريد\nأن تبدء منه الختمة'**
  String get khatmaLocationScreenMessage2;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_location_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'البدء من:'**
  String get khatmaLocationScreenMessage3;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_location_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'رقم الجزء:'**
  String get khatmaLocationScreenMessage4;

  /// Display text used in lib/features/khatma/presentation/screens/khatma_location_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الجزء {value1}'**
  String khatmaLocationScreenMessage5(String value1);

  /// Display text used in lib/features/media/data/datasources/articles_remote_datasource.dart.
  ///
  /// In ar, this message translates to:
  /// **'إسلام ويب'**
  String get articlesRemoteDatasourceMessage1;

  /// Display text used in lib/features/media/data/datasources/articles_remote_datasource.dart.
  ///
  /// In ar, this message translates to:
  /// **'مقالات إسلامية'**
  String get articlesRemoteDatasourceMessage2;

  /// Display text used in lib/features/media/data/datasources/articles_remote_datasource.dart.
  ///
  /// In ar, this message translates to:
  /// **'طريق الإسلام'**
  String get articlesRemoteDatasourceMessage3;

  /// Display text used in lib/features/media/data/datasources/articles_remote_datasource.dart.
  ///
  /// In ar, this message translates to:
  /// **'مقالات ودروس'**
  String get articlesRemoteDatasourceMessage4;

  /// Display text used in lib/features/media/data/datasources/articles_remote_datasource.dart.
  ///
  /// In ar, this message translates to:
  /// **'الألوكة الشرعية'**
  String get articlesRemoteDatasourceMessage5;

  /// Display text used in lib/features/media/data/datasources/articles_remote_datasource.dart.
  ///
  /// In ar, this message translates to:
  /// **'فقه وعلوم شرعية'**
  String get articlesRemoteDatasourceMessage6;

  /// Display text used in lib/features/media/data/datasources/articles_remote_datasource.dart.
  ///
  /// In ar, this message translates to:
  /// **'صيد الفوائد'**
  String get articlesRemoteDatasourceMessage7;

  /// Display text used in lib/features/media/data/datasources/articles_remote_datasource.dart.
  ///
  /// In ar, this message translates to:
  /// **'فوائد ومقالات'**
  String get articlesRemoteDatasourceMessage8;

  /// Display text used in lib/features/media/data/datasources/articles_remote_datasource.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل المقالات، تحقق من اتصالك بالإنترنت'**
  String get articlesRemoteDatasourceMessage9;

  /// Display text used in lib/features/media/data/datasources/articles_remote_datasource.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل {value1} ({value2})'**
  String articlesRemoteDatasourceMessage10(String value1, String value2);

  /// Display text used in lib/features/media/data/datasources/audio_remote_datasource.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل قائمة القراء ({value1})'**
  String audioRemoteDatasourceMessage1(String value1);

  /// Display text used in lib/features/media/data/datasources/video_remote_datasource.dart.
  ///
  /// In ar, this message translates to:
  /// **'أضف مفتاح YouTube API لعرض الفيديوهات مباشرة'**
  String get videoRemoteDatasourceMessage1;

  /// Display text used in lib/features/media/data/datasources/video_remote_datasource.dart.
  ///
  /// In ar, this message translates to:
  /// **'تم تجاوز الحد اليومي للفيديوهات، جرب لاحقاً'**
  String get videoRemoteDatasourceMessage2;

  /// Display text used in lib/features/media/data/datasources/video_remote_datasource.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الفيديوهات ({value1})'**
  String videoRemoteDatasourceMessage3(String value1);

  /// Display text used in lib/features/media/data/models/surah_audio_model.dart.
  ///
  /// In ar, this message translates to:
  /// **'سورة {value1}'**
  String surahAudioModelMessage1(String value1);

  /// Display text used in lib/features/media/data/repositories/media_repository_impl.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل المقالات'**
  String get mediaRepositoryImplMessage1;

  /// Display text used in lib/features/media/data/repositories/media_repository_impl.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الصوتيات'**
  String get mediaRepositoryImplMessage2;

  /// Display text used in lib/features/media/data/repositories/media_repository_impl.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الفيديوهات'**
  String get mediaRepositoryImplMessage3;

  /// Display text used in lib/features/media/data/repositories/media_repository_impl.dart.
  ///
  /// In ar, this message translates to:
  /// **'انتهت مهلة الاتصال، حاول مرة أخرى'**
  String get mediaRepositoryImplMessage4;

  /// Display text used in lib/features/media/data/repositories/media_repository_impl.dart.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من اتصالك بالإنترنت'**
  String get mediaRepositoryImplMessage5;

  /// Display text used in lib/features/media/data/repositories/media_repository_impl.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة البيانات المستلمة'**
  String get mediaRepositoryImplMessage6;

  /// Display text used in lib/features/media/data/repositories/media_repository_impl.dart.
  ///
  /// In ar, this message translates to:
  /// **'{value1}، حاول مرة أخرى'**
  String mediaRepositoryImplMessage7(String value1);

  /// Display text used in lib/features/media/presentation/providers/articles_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع، حاول مرة أخرى'**
  String get articlesProviderMessage1;

  /// Display text used in lib/features/media/presentation/providers/video_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'خطبة الجمعة'**
  String get videoProviderMessage1;

  /// Display text used in lib/features/media/presentation/providers/video_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'درس ديني'**
  String get videoProviderMessage2;

  /// Display text used in lib/features/media/presentation/providers/video_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'تفسير القرآن'**
  String get videoProviderMessage3;

  /// Display text used in lib/features/media/presentation/providers/video_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'قصص الأنبياء'**
  String get videoProviderMessage4;

  /// Display text used in lib/features/media/presentation/providers/video_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'فقه إسلامي'**
  String get videoProviderMessage5;

  /// Display text used in lib/features/media/presentation/providers/video_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'قناة الرسالة'**
  String get videoProviderMessage6;

  /// Display text used in lib/features/media/presentation/providers/video_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'برامج ودروس إسلامية'**
  String get videoProviderMessage7;

  /// Display text used in lib/features/media/presentation/providers/video_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'دار الإفتاء المصرية'**
  String get videoProviderMessage8;

  /// Display text used in lib/features/media/presentation/providers/video_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'فتاوى ودروس شرعية'**
  String get videoProviderMessage9;

  /// Display text used in lib/features/media/presentation/providers/video_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'الشيخ محمد متولي الشعراوي'**
  String get videoProviderMessage10;

  /// Display text used in lib/features/media/presentation/providers/video_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'تفسير القرآن الكريم'**
  String get videoProviderMessage11;

  /// Display text used in lib/features/media/presentation/screens/articles_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'المقالات'**
  String get articlesScreenMessage1;

  /// Display text used in lib/features/media/presentation/screens/articles_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مقالات متاحة حالياً'**
  String get articlesScreenMessage2;

  /// Display text used in lib/features/media/presentation/screens/articles_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'كل المصادر'**
  String get articlesScreenMessage3;

  /// Display text used in lib/features/media/presentation/screens/audio_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الصوتيات'**
  String get audioScreenMessage1;

  /// Display text used in lib/features/media/presentation/screens/audio_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'كل القراء'**
  String get audioScreenMessage2;

  /// Display text used in lib/features/media/presentation/screens/audio_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'نتائج البحث'**
  String get audioScreenMessage3;

  /// Display text used in lib/features/media/presentation/screens/audio_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة'**
  String get audioScreenMessage4;

  /// Display text used in lib/features/media/presentation/screens/audio_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'ابحث باسم القارئ'**
  String get audioScreenMessage5;

  /// Display text used in lib/features/media/presentation/screens/audio_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'مسح البحث'**
  String get audioScreenMessage6;

  /// Display text used in lib/features/media/presentation/screens/video_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الفيديوهات'**
  String get videoScreenMessage1;

  /// Display text used in lib/features/media/presentation/screens/video_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فيديوهات متاحة حالياً'**
  String get videoScreenMessage2;

  /// Display text used in lib/features/media/presentation/widgets/article_card.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح الرابط'**
  String get articleCardMessage1;

  /// Display text used in lib/features/media/presentation/widgets/audio_player_sheet.dart.
  ///
  /// In ar, this message translates to:
  /// **'فتح التلاوة في مشغل الصوت'**
  String get audioPlayerSheetMessage1;

  /// Display text used in lib/features/media/presentation/widgets/audio_player_sheet.dart.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get audioPlayerSheetMessage2;

  /// Display text used in lib/features/media/presentation/widgets/audio_player_sheet.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح ملف الصوت'**
  String get audioPlayerSheetMessage3;

  /// Display text used in lib/features/media/presentation/widgets/reciter_card.dart.
  ///
  /// In ar, this message translates to:
  /// **'{value1} سورة'**
  String reciterCardMessage1(String value1);

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'فتح القائمة الجانبية'**
  String get homeScreenMessage1;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق القائمة الجانبية'**
  String get homeScreenMessage2;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get homeScreenMessage3;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'المفضلة'**
  String get homeScreenMessage4;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تبويب {value1}'**
  String homeScreenMessage5(String value1);

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'مفعل'**
  String get homeScreenMessage6;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'معطل'**
  String get homeScreenMessage7;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ختمة نشطة حالياً'**
  String get homeScreenMessage8;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الأوراد السابقة'**
  String get homeScreenMessage9;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الأوراد القادمة'**
  String get homeScreenMessage10;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'عدد الأوراد المكتملة: {value1}'**
  String homeScreenMessage11(String value1);

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'عدد الأوراد المتبقية: {value1}'**
  String homeScreenMessage12(String value1);

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم إكمال أي ورد بعد.'**
  String get homeScreenMessage13;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أوراد قادمة. تم إنجاز الختمة بالكامل.'**
  String get homeScreenMessage14;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'من {value1} إلى {value2} ({value3})'**
  String homeScreenMessage15(String value1, String value2, String value3);

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل في {value1}'**
  String homeScreenMessage16(String value1);

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم {value1}'**
  String homeScreenMessage17(String value1);

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'قادم'**
  String get homeScreenMessage18;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل بيانات السور'**
  String get homeScreenMessage19;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد فاصل محفوظ حالياً'**
  String get homeScreenMessage20;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح الفاصل المحفوظ'**
  String get homeScreenMessage21;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إيجاد السورة المرتبطة بالفاصل'**
  String get homeScreenMessage22;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء فتح الفاصل'**
  String get homeScreenMessage23;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'هذه الميزة ستتوفر قريباً إن شاء الله'**
  String get homeScreenMessage24;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الخصوصية ومصادر المحتوى'**
  String get homeScreenMessage25;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الفاصل'**
  String get homeScreenMessage26;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'المكتبة'**
  String get homeScreenMessage27;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'كل الوسائط'**
  String get homeScreenMessage28;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'سنن قرآنية'**
  String get homeScreenMessage29;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'سورة الكهف'**
  String get homeScreenMessage30;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'سورة الملك'**
  String get homeScreenMessage31;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'سورة البقرة'**
  String get homeScreenMessage32;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الوضع الليلي'**
  String get homeScreenMessage33;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تغيير مظهر التطبيق'**
  String get homeScreenMessage34;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'بدء ختمة جديدة'**
  String get homeScreenMessage35;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات مواقيت الصلاة'**
  String get homeScreenMessage36;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'اتجاه القبلة'**
  String get homeScreenMessage37;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'منبهات الأذكار'**
  String get homeScreenMessage38;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'منبه أذكار الصباح'**
  String get homeScreenMessage39;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'وقت منبه أذكار الصباح'**
  String get homeScreenMessage40;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'منبه أذكار المساء'**
  String get homeScreenMessage41;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'وقت منبه أذكار المساء'**
  String get homeScreenMessage42;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'منبهات السنن'**
  String get homeScreenMessage43;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'منبه سورة الملك'**
  String get homeScreenMessage44;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'وقت منبه سورة الملك'**
  String get homeScreenMessage45;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'منبه سورة البقرة'**
  String get homeScreenMessage46;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'وقت منبه سورة البقرة'**
  String get homeScreenMessage47;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق سكينة'**
  String get homeScreenMessage48;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get homeScreenMessage49;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات اللغة'**
  String get homeScreenMessage50;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'اللغة الحالية للتطبيق هي العربية. سيتم دعم لغات إضافية لاحقاً بإذن الله.'**
  String get homeScreenMessage51;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الإتصال بنا'**
  String get homeScreenMessage52;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'mailto:contact@quranapp.com?subject=تطبيق سكينة - تواصل'**
  String get homeScreenMessage53;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تابعنا على تويتر'**
  String get homeScreenMessage54;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تابعنا على انستقرام'**
  String get homeScreenMessage55;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'انشر التطبيق'**
  String get homeScreenMessage56;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق سكينة - تطبيق إسلامي شامل. حمل الآن! \n(رابط التطبيق قريباً)'**
  String get homeScreenMessage57;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'قيم تطبيق سكينة'**
  String get homeScreenMessage58;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد آيات مفضلة'**
  String get homeScreenMessage59;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الآية من المفضلة'**
  String get homeScreenMessage60;

  /// Display text used in lib/features/onboarding/presentation/screens/home_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة التالية: {value1}'**
  String homeScreenMessage61(String value1);

  /// Display text used in lib/features/onboarding/presentation/screens/onboarding_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر بدء التطبيق، حاول مرة أخرى.'**
  String get onboardingScreenMessage1;

  /// Display text used in lib/features/onboarding/presentation/screens/onboarding_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get onboardingScreenMessage2;

  /// Display text used in lib/features/onboarding/presentation/screens/onboarding_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة {value1} من {value2}'**
  String onboardingScreenMessage3(String value1, String value2);

  /// Display text used in lib/features/onboarding/presentation/screens/onboarding_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get onboardingScreenMessage4;

  /// Display text used in lib/features/onboarding/presentation/widgets/alarms/alarm_menu_item.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعديل وقت {value1}'**
  String alarmMenuItemMessage1(String value1);

  /// Display text used in lib/features/onboarding/presentation/widgets/alarms/alarm_menu_item.dart.
  ///
  /// In ar, this message translates to:
  /// **'م'**
  String get alarmMenuItemMessage2;

  /// Display text used in lib/features/onboarding/presentation/widgets/alarms/alarm_menu_item.dart.
  ///
  /// In ar, this message translates to:
  /// **'ص'**
  String get alarmMenuItemMessage3;

  /// Display text used in lib/features/onboarding/presentation/widgets/alarms/alarm_time_picker_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل وقت التذكير'**
  String get alarmTimePickerDialogMessage1;

  /// Display text used in lib/features/onboarding/presentation/widgets/alarms/alarm_time_picker_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ وقت {value1}'**
  String alarmTimePickerDialogMessage2(String value1);

  /// Display text used in lib/features/onboarding/presentation/widgets/alarms/alarm_time_picker_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ الوقت. أعد المحاولة.'**
  String get alarmTimePickerDialogMessage3;

  /// Display text used in lib/features/onboarding/presentation/widgets/category_grid_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'التسبيح'**
  String get categoryGridWidgetMessage1;

  /// Display text used in lib/features/onboarding/presentation/widgets/category_grid_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'الأسماء'**
  String get categoryGridWidgetMessage2;

  /// Display text used in lib/features/onboarding/presentation/widgets/category_grid_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'الأحاديث'**
  String get categoryGridWidgetMessage3;

  /// Display text used in lib/features/onboarding/presentation/widgets/continue_reading_card.dart.
  ///
  /// In ar, this message translates to:
  /// **'متابعة القراءة'**
  String get continueReadingCardMessage1;

  /// Display text used in lib/features/onboarding/presentation/widgets/continue_reading_card.dart.
  ///
  /// In ar, this message translates to:
  /// **'القرآن الكريم'**
  String get continueReadingCardMessage2;

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'تم إتمام ورد اليوم، انتقل إلى الورد التالي'**
  String get currentWirdWidgetMessage1;

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'تم إتمام الختمة بنجاح، بارك الله فيك'**
  String get currentWirdWidgetMessage2;

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'الورد الحالي'**
  String get currentWirdWidgetMessage3;

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'من قوله تعالى'**
  String get currentWirdWidgetMessage4;

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'بدء الختمة: {value1}'**
  String currentWirdWidgetMessage5(String value1);

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'{value1} / يوم'**
  String currentWirdWidgetMessage6(String value1);

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم: من {value1} إلى {value2} ({value3})'**
  String currentWirdWidgetMessage7(String value1, String value2, String value3);

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'يوجد موضع محفوظ لاستكمال الورد'**
  String get currentWirdWidgetMessage8;

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'أتممت القراءة'**
  String get currentWirdWidgetMessage9;

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ الورد'**
  String get currentWirdWidgetMessage10;

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الختمة'**
  String get currentWirdWidgetMessage11;

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من إلغاء الختمة الحالية؟'**
  String get currentWirdWidgetMessage12;

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get currentWirdWidgetMessage13;

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'نعم، إلغاء'**
  String get currentWirdWidgetMessage14;

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'المتبقي: {value1} {value2}'**
  String currentWirdWidgetMessage15(String value1, String value2);

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'الإنجاز: {value1}%'**
  String currentWirdWidgetMessage16(String value1);

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ ختمة جديدة وتابع وردك اليومي بسهولة'**
  String get currentWirdWidgetMessage17;

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ ختمة جديدة'**
  String get currentWirdWidgetMessage18;

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل آية الورد'**
  String get currentWirdWidgetMessage19;

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'{value1} - الآية {value2} - صفحة {value3}'**
  String currentWirdWidgetMessage20(
    String value1,
    String value2,
    String value3,
  );

  /// Display text used in lib/features/onboarding/presentation/widgets/current_wird_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل آية الورد...'**
  String get currentWirdWidgetMessage21;

  /// Display text used in lib/features/onboarding/presentation/widgets/daily_verse_section_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'الآيات اليومية'**
  String get dailyVerseSectionWidgetMessage1;

  /// Display text used in lib/features/onboarding/presentation/widgets/home_drawer.dart.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق القائمة'**
  String get homeDrawerMessage1;

  /// Display text used in lib/features/onboarding/presentation/widgets/notification_permission_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الإشعارات'**
  String get notificationPermissionDialogMessage1;

  /// Display text used in lib/features/onboarding/presentation/widgets/notification_permission_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'لتجربة أفضل، اسمح للتطبيق بإرسال إشعارات لتذكيرك بأوقات الصلاة، الأذكار، والورد اليومي.'**
  String get notificationPermissionDialogMessage2;

  /// Display text used in lib/features/onboarding/presentation/widgets/notification_permission_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'السماح بالإشعارات'**
  String get notificationPermissionDialogMessage3;

  /// Display text used in lib/features/onboarding/presentation/widgets/notification_permission_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'ليس الآن'**
  String get notificationPermissionDialogMessage4;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بك في سكينة'**
  String get onboardingPageMessage1;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'مساحة يطمئن فيها قلبك؛ تجمع لك القرآن والذكر ومواقيت الصلاة، لترافقك في يومك.'**
  String get onboardingPageMessage2;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'رفيقك في كل يوم'**
  String get onboardingPageMessage3;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'قرآن'**
  String get onboardingPageMessage4;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get onboardingPageMessage5;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'صلاة'**
  String get onboardingPageMessage6;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'مع القرآن، آيةً بآية'**
  String get onboardingPageMessage7;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ القرآن واحفظ موضع قراءتك، وحدّد هدف ختمتك وتابع وردك اليومي بالوتيرة التي تناسبك.'**
  String get onboardingPageMessage8;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'وردٌ تقرؤه، وقربٌ تجده'**
  String get onboardingPageMessage9;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'قراءة القرآن'**
  String get onboardingPageMessage10;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الموضع'**
  String get onboardingPageMessage11;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'متابعة الختمة'**
  String get onboardingPageMessage12;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'ليكن يومك عامرًا بالذكر'**
  String get onboardingPageMessage13;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الصباح والمساء، وأدعية ترافق يومك، ومسبحة إلكترونية تعينك على متابعة تسبيحك.'**
  String get onboardingPageMessage14;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'لحظات ذكر، وأثرٌ يبقى'**
  String get onboardingPageMessage15;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'أذكار يومية'**
  String get onboardingPageMessage16;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'أدعية'**
  String get onboardingPageMessage17;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'تسبيح'**
  String get onboardingPageMessage18;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'صلاتك ووردك في موعدهما'**
  String get onboardingPageMessage19;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'تابع مواقيت الصلاة، واضبط تذكيرات الأذكار والورد اليومي لتجد وقتًا لما يطمئن به قلبك.'**
  String get onboardingPageMessage20;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرٌ يعينك على المداومة'**
  String get onboardingPageMessage21;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات الأذكار'**
  String get onboardingPageMessage22;

  /// Display text used in lib/features/onboarding/presentation/widgets/onboarding_page.dart.
  ///
  /// In ar, this message translates to:
  /// **'الورد اليومي'**
  String get onboardingPageMessage23;

  /// Display text used in lib/features/onboarding/presentation/widgets/prayer_times_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في تحميل أوقات الصلاة'**
  String get prayerTimesWidgetMessage1;

  /// Display text used in lib/features/onboarding/presentation/widgets/prayer_times_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'تحديد موقع الصلاة'**
  String get prayerTimesWidgetMessage2;

  /// Display text used in lib/features/onboarding/presentation/widgets/prayer_times_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'خطأ غير معروف'**
  String get prayerTimesWidgetMessage3;

  /// Display text used in lib/features/onboarding/presentation/widgets/prayer_times_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات متاحة'**
  String get prayerTimesWidgetMessage4;

  /// Display text used in lib/features/onboarding/presentation/widgets/prayer_times_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'جميع مواقيت الصلاة'**
  String get prayerTimesWidgetMessage5;

  /// Display text used in lib/features/onboarding/presentation/widgets/prayer_times_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة القادمة'**
  String get prayerTimesWidgetMessage6;

  /// Display text used in lib/features/onboarding/presentation/widgets/prayer_times_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'في'**
  String get prayerTimesWidgetMessage7;

  /// Display text used in lib/features/onboarding/presentation/widgets/prayer_times_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'الفجر'**
  String get prayerTimesWidgetMessage8;

  /// Display text used in lib/features/onboarding/presentation/widgets/prayer_times_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'الظهر'**
  String get prayerTimesWidgetMessage9;

  /// Display text used in lib/features/onboarding/presentation/widgets/prayer_times_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'العصر'**
  String get prayerTimesWidgetMessage10;

  /// Display text used in lib/features/onboarding/presentation/widgets/prayer_times_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'المغرب'**
  String get prayerTimesWidgetMessage11;

  /// Display text used in lib/features/onboarding/presentation/widgets/prayer_times_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'العشاء'**
  String get prayerTimesWidgetMessage12;

  /// Display text used in lib/features/onboarding/presentation/widgets/prayer_times_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'الفجر غداً'**
  String get prayerTimesWidgetMessage13;

  /// Display text used in lib/features/onboarding/presentation/widgets/prayer_times_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار مواقيت الغد'**
  String get prayerTimesWidgetMessage14;

  /// Display text used in lib/features/onboarding/presentation/widgets/prayer_times_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'{value1} ساعة و{value2} دقيقة'**
  String prayerTimesWidgetMessage15(String value1, String value2);

  /// Display text used in lib/features/onboarding/presentation/widgets/prayer_times_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'{value1} دقيقة'**
  String prayerTimesWidgetMessage16(String value1);

  /// Display text used in lib/features/onboarding/presentation/widgets/tab_switcher_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'جميع التصنيفات'**
  String get tabSwitcherWidgetMessage1;

  /// Display text used in lib/features/prayers/domain/prayer_calculation_policy.dart.
  ///
  /// In ar, this message translates to:
  /// **'رابطة العالم الإسلامي'**
  String get prayerCalculationPolicyMessage1;

  /// Display text used in lib/features/prayers/domain/prayer_calculation_policy.dart.
  ///
  /// In ar, this message translates to:
  /// **'أم القرى'**
  String get prayerCalculationPolicyMessage2;

  /// Display text used in lib/features/prayers/domain/prayer_calculation_policy.dart.
  ///
  /// In ar, this message translates to:
  /// **'الهيئة المصرية العامة للمساحة'**
  String get prayerCalculationPolicyMessage3;

  /// Display text used in lib/features/prayers/presentation/providers/prayer_times_performance_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'الشروق'**
  String get prayerTimesPerformanceProviderMessage1;

  /// Display text used in lib/features/prayers/presentation/providers/prayer_times_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الموقع متوقفة. فعّلها أو اختر مدينة يدوياً.'**
  String get prayerTimesProviderMessage1;

  /// Display text used in lib/features/prayers/presentation/providers/prayer_times_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'إذن الموقع مرفوض. يمكنك تفعيله من إعدادات الجهاز أو اختيار مدينة يدوياً.'**
  String get prayerTimesProviderMessage2;

  /// Display text used in lib/features/prayers/presentation/providers/prayer_times_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'لم يُسمح بالوصول للموقع. اختر مدينة أو أدخل الإحداثيات يدوياً.'**
  String get prayerTimesProviderMessage3;

  /// Display text used in lib/features/prayers/presentation/providers/prayer_times_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم تحديد الموقع'**
  String get prayerTimesProviderMessage4;

  /// Display text used in lib/features/prayers/presentation/providers/prayer_times_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'موقع محفوظ'**
  String get prayerTimesProviderMessage5;

  /// Display text used in lib/features/prayers/presentation/providers/prayer_times_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'موقع يدوي'**
  String get prayerTimesProviderMessage6;

  /// Display text used in lib/features/prayers/presentation/providers/prayer_times_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ موقع الصلاة. أعد اختيار الموقع وحاول مرة أخرى.'**
  String get prayerTimesProviderMessage7;

  /// Display text used in lib/features/prayers/presentation/providers/prayer_times_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'موقع الجهاز'**
  String get prayerTimesProviderMessage8;

  /// Display text used in lib/features/prayers/presentation/providers/prayer_times_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديد الموقع. اختر مدينة يدوياً أو أعد المحاولة.'**
  String get prayerTimesProviderMessage9;

  /// Display text used in lib/features/prayers/presentation/providers/prayer_times_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل المواقيت. حدد موقعك أو تحقق من الاتصال وأعد المحاولة.'**
  String get prayerTimesProviderMessage10;

  /// Display text used in lib/features/prayers/presentation/providers/prayer_times_provider.dart.
  ///
  /// In ar, this message translates to:
  /// **'حدد الموقع'**
  String get prayerTimesProviderMessage11;

  /// Display text used in lib/features/prayers/presentation/screens/prayer_location_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'موقع الصلاة وطريقة الحساب'**
  String get prayerLocationDialogMessage1;

  /// Display text used in lib/features/prayers/presentation/screens/prayer_location_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'{value1}، {value2}'**
  String prayerLocationDialogMessage2(String value1, String value2);

  /// Display text used in lib/features/prayers/presentation/screens/prayer_location_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'بحث في المدن المتاحة دون اتصال'**
  String get prayerLocationDialogMessage3;

  /// Display text used in lib/features/prayers/presentation/screens/prayer_location_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'المدن تستخدم إحداثيات وسط المدينة. إذا لم تجد مدينتك، أدخل الإحداثيات أو استخدم موقع الجهاز.'**
  String get prayerLocationDialogMessage4;

  /// Display text used in lib/features/prayers/presentation/screens/prayer_location_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'تُحسب المواقيت على جهازك، ولا تُرسل الإحداثيات إلى أي خادم.'**
  String get prayerLocationDialogMessage5;

  /// Display text used in lib/features/prayers/presentation/screens/prayer_location_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'اسم المكان'**
  String get prayerLocationDialogMessage6;

  /// Display text used in lib/features/prayers/presentation/screens/prayer_location_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'خط العرض (من ‎-90 إلى 90)'**
  String get prayerLocationDialogMessage7;

  /// Display text used in lib/features/prayers/presentation/screens/prayer_location_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'خط الطول (من ‎-180 إلى 180)'**
  String get prayerLocationDialogMessage8;

  /// Display text used in lib/features/prayers/presentation/screens/prayer_location_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الحساب'**
  String get prayerLocationDialogMessage9;

  /// Display text used in lib/features/prayers/presentation/screens/prayer_location_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'أدخل إحداثيات صحيحة'**
  String get prayerLocationDialogMessage10;

  /// Display text used in lib/features/prayers/presentation/screens/prayer_times_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الموقع وطريقة الحساب'**
  String get prayerTimesScreenMessage1;

  /// Display text used in lib/features/prayers/presentation/screens/prayer_times_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'استخدام موقع الجهاز وإرساله لحساب المواقيت'**
  String get prayerTimesScreenMessage2;

  /// Display text used in lib/features/prayers/presentation/screens/prayer_times_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تحميل مواقيت الصلاة'**
  String get prayerTimesScreenMessage3;

  /// Display text used in lib/features/prayers/presentation/screens/prayer_times_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت محفوظة'**
  String get prayerTimesScreenMessage4;

  /// Display text used in lib/features/prayers/presentation/screens/prayer_times_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت محفوظة قديمة؛ تعذر تحديثها'**
  String get prayerTimesScreenMessage5;

  /// Display text used in lib/features/prayers/presentation/screens/prayer_times_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'{value1} • {value2}'**
  String prayerTimesScreenMessage6(String value1, String value2);

  /// Display text used in lib/features/prayers/presentation/screens/prayer_times_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تحديث المواقيت'**
  String get prayerTimesScreenMessage7;

  /// Display text used in lib/features/prayers/presentation/screens/prayer_times_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'صلاة {value1}'**
  String prayerTimesScreenMessage8(String value1);

  /// Display text used in lib/features/prayers/presentation/screens/prayer_times_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تتوفر المواقيت عند تحديث يوم الغد'**
  String get prayerTimesScreenMessage9;

  /// Display text used in lib/features/prayers/presentation/widgets/prayer_times_performance_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل أوقات الصلاة...'**
  String get prayerTimesPerformanceWidgetMessage1;

  /// Display text used in lib/features/prayers/presentation/widgets/prayer_times_performance_widget.dart.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في تحميل أوقات الصلاة'**
  String get prayerTimesPerformanceWidgetMessage2;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'افتح إعدادات الهاتف وفعّل الموقع وصلاحيته لتطبيق سكينة.'**
  String get qiblaScreenMessage1;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الموقع والبوصلة'**
  String get qiblaScreenMessage2;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحديد موقعك'**
  String get qiblaScreenMessage3;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'نحتاج موقعك لحساب اتجاه الكعبة. قد يستغرق تحديد الموقع بضع ثوانٍ.'**
  String get qiblaScreenMessage4;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الموقع متوقفة'**
  String get qiblaScreenMessage5;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'فعّل الموقع من إعدادات الهاتف، ثم عد إلى هذه الشاشة.'**
  String get qiblaScreenMessage6;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'السماح بالوصول إلى الموقع'**
  String get qiblaScreenMessage7;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'اسمح باستخدام الموقع أثناء فتح الشاشة لتحديد اتجاه القبلة من مكانك.'**
  String get qiblaScreenMessage8;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'صلاحية الموقع غير مفعّلة'**
  String get qiblaScreenMessage9;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'افتح إعدادات التطبيق واسمح بالوصول إلى الموقع أثناء الاستخدام.'**
  String get qiblaScreenMessage10;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'البوصلة متاحة على الهاتف'**
  String get qiblaScreenMessage11;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'افتح التطبيق على هاتف Android أو iPhone مزود بحساس بوصلة.'**
  String get qiblaScreenMessage12;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديد موقعك'**
  String get qiblaScreenMessage13;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'انتقل إلى مكان تصل إليه إشارة الموقع، ثم حاول مرة أخرى.'**
  String get qiblaScreenMessage14;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'فتح الإعدادات'**
  String get qiblaScreenMessage15;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'السماح بالموقع'**
  String get qiblaScreenMessage16;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'أنت قريب جدًا من الكعبة. اتجه إلى الكعبة مباشرة؛ لا تكفي دقة موقع الهاتف لتوجيهك هنا.'**
  String get qiblaScreenMessage17;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت قراءة البوصلة'**
  String get qiblaScreenMessage18;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ قراءة البوصلة'**
  String get qiblaScreenMessage19;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'البوصلة تحتاج إلى معايرة'**
  String get qiblaScreenMessage20;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'أنت باتجاه القبلة'**
  String get qiblaScreenMessage21;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'يسارًا'**
  String get qiblaScreenMessage22;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'يمينًا'**
  String get qiblaScreenMessage23;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'استدر {value1} {value2}°'**
  String qiblaScreenMessage24(String value1, String value2);

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'وَحَيْثُ مَا كُنتُمْ فَوَلُّوا وُجُوهَكُمْ شَطْرَهُ'**
  String get qiblaScreenMessage25;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'ضع الهاتف أفقيًا ووجّه حافته العلوية نحو الكعبة'**
  String get qiblaScreenMessage26;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'{value1}° من الشمال الجغرافي'**
  String qiblaScreenMessage27(String value1);

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'قد لا يحتوي جهازك على حساس بوصلة. يمكنك استخدام الزاوية المعروضة مع بوصلة موثوقة، أو التجربة على هاتف آخر.'**
  String get qiblaScreenMessage28;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'لدقة أفضل، ابتعد عن المعادن والمغناطيس وحرّك الهاتف على شكل 8 لمعايرة البوصلة. الاتجاه تقريبي ويتأثر بدقة الحساس.'**
  String get qiblaScreenMessage29;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'سهم اتجاه الكعبة'**
  String get qiblaScreenMessage30;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'ش'**
  String get qiblaScreenMessage31;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'شرق'**
  String get qiblaScreenMessage32;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'ج'**
  String get qiblaScreenMessage33;

  /// Display text used in lib/features/qibla/presentation/screens/qibla_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'غرب'**
  String get qiblaScreenMessage34;

  /// Display text used in lib/features/quran/data/models/surah_model.dart.
  ///
  /// In ar, this message translates to:
  /// **'مكة'**
  String get surahModelMessage1;

  /// Display text used in lib/features/quran/data/models/surah_model.dart.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get surahModelMessage2;

  /// Display text used in lib/features/quran/presentation/screens/asma_al_husna_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'أسماء الله الحسنى'**
  String get asmaAlHusnaScreenMessage1;

  /// Display text used in lib/features/quran/presentation/screens/quran_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تحميل السور'**
  String get quranScreenMessage1;

  /// Display text used in lib/features/quran/presentation/screens/quran_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'مكية'**
  String get quranScreenMessage2;

  /// Display text used in lib/features/quran/presentation/screens/quran_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'مدنية'**
  String get quranScreenMessage3;

  /// Display text used in lib/features/quran/presentation/screens/quran_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'سورة {value1}، عدد الآيات {value2}، {value3}'**
  String quranScreenMessage4(String value1, String value2, String value3);

  /// Display text used in lib/features/quran/presentation/screens/quran_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'{value1} آية'**
  String quranScreenMessage5(String value1);

  /// Display text used in lib/features/quran/presentation/screens/quran_search_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'اسم السورة أو رقمها أو جزء من آية'**
  String get quranSearchScreenMessage1;

  /// Display text used in lib/features/quran/presentation/screens/quran_search_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل القرآن. إعادة المحاولة'**
  String get quranSearchScreenMessage2;

  /// Display text used in lib/features/quran/presentation/screens/quran_search_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كلمة أو جزءاً من آية'**
  String get quranSearchScreenMessage3;

  /// Display text used in lib/features/quran/presentation/screens/quran_search_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'سورة {value1} • آية {value2}'**
  String quranSearchScreenMessage4(String value1, String value2);

  /// Display text used in lib/features/quran/presentation/screens/reader_buttons.dart.
  ///
  /// In ar, this message translates to:
  /// **'حفظ العلامة'**
  String get readerButtonsMessage1;

  /// Display text used in lib/features/quran/presentation/screens/reader_content.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد آيات في هذه السورة'**
  String get readerContentMessage1;

  /// Display text used in lib/features/quran/presentation/screens/reader_content.dart.
  ///
  /// In ar, this message translates to:
  /// **'{value1} • {value2} آية'**
  String readerContentMessage2(String value1, String value2);

  /// Display text used in lib/features/quran/presentation/screens/reader_content.dart.
  ///
  /// In ar, this message translates to:
  /// **'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'**
  String get readerContentMessage3;

  /// Display text used in lib/features/quran/presentation/screens/reader_controls.dart.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة السابقة'**
  String get readerControlsMessage1;

  /// Display text used in lib/features/quran/presentation/screens/reader_controls.dart.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة التالية'**
  String get readerControlsMessage2;

  /// Display text used in lib/features/quran/presentation/screens/reader_controls.dart.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ موضع الورد الحالي'**
  String get readerControlsMessage3;

  /// Display text used in lib/features/quran/presentation/screens/reader_controls.dart.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ علامة القراءة بنجاح'**
  String get readerControlsMessage4;

  /// Display text used in lib/features/quran/presentation/screens/reader_controls.dart.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص القراءة'**
  String get readerControlsMessage5;

  /// Display text used in lib/features/quran/presentation/screens/reader_controls.dart.
  ///
  /// In ar, this message translates to:
  /// **'حجم الخط'**
  String get readerControlsMessage6;

  /// Display text used in lib/features/quran/presentation/screens/reader_controls.dart.
  ///
  /// In ar, this message translates to:
  /// **'تباعد الأسطر'**
  String get readerControlsMessage7;

  /// Display text used in lib/features/quran/presentation/screens/reader_controls.dart.
  ///
  /// In ar, this message translates to:
  /// **'إظهار أرقام الآيات'**
  String get readerControlsMessage8;

  /// Display text used in lib/features/quran/presentation/screens/reader_controls.dart.
  ///
  /// In ar, this message translates to:
  /// **'وضع القراءة الكاملة'**
  String get readerControlsMessage9;

  /// Display text used in lib/features/quran/presentation/screens/reader_data.dart.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تحميل آيات السورة'**
  String get readerDataMessage1;

  /// Display text used in lib/features/quran/presentation/screens/surah_details_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'خيارات القراءة'**
  String get surahDetailsScreenMessage1;

  /// Display text used in lib/features/quran/presentation/screens/tasbeeh_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'سبحان الله'**
  String get tasbeehScreenMessage1;

  /// Display text used in lib/features/quran/presentation/screens/tasbeeh_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الحمد لله'**
  String get tasbeehScreenMessage2;

  /// Display text used in lib/features/quran/presentation/screens/tasbeeh_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا إله إلا الله'**
  String get tasbeehScreenMessage3;

  /// Display text used in lib/features/quran/presentation/screens/tasbeeh_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الله أكبر'**
  String get tasbeehScreenMessage4;

  /// Display text used in lib/features/quran/presentation/screens/tasbeeh_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'التسبيح الإلكتروني'**
  String get tasbeehScreenMessage5;

  /// Display text used in lib/features/quran/presentation/screens/tasbeeh_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تسبيحة'**
  String get tasbeehScreenMessage6;

  /// Display text used in lib/features/quran/presentation/screens/tasbeeh_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'إضافة جديد'**
  String get tasbeehScreenMessage7;

  /// Display text used in lib/features/quran/presentation/screens/tasbeeh_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين'**
  String get tasbeehScreenMessage8;

  /// Display text used in lib/features/quran/presentation/screens/tasbeeh_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'إضافة تسبيحة جديدة'**
  String get tasbeehScreenMessage9;

  /// Display text used in lib/features/quran/presentation/screens/tasbeeh_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'أدخل نص التسبيحة'**
  String get tasbeehScreenMessage10;

  /// Display text used in lib/features/quran/presentation/screens/tasbeeh_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get tasbeehScreenMessage11;

  /// Display text used in lib/features/quran/presentation/screens/tasbeeh_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف \"{value1}\"'**
  String tasbeehScreenMessage12(String value1);

  /// Display text used in lib/features/quran/presentation/widgets/quran_settings_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات القراءة'**
  String get quranSettingsDialogMessage1;

  /// Display text used in lib/features/quran/presentation/widgets/quran_settings_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق إعدادات القراءة'**
  String get quranSettingsDialogMessage2;

  /// Display text used in lib/features/quran/presentation/widgets/quran_settings_dialog.dart.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الليلي'**
  String get quranSettingsDialogMessage3;

  /// Display text used in lib/features/settings/presentation/screens/data_sources_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الموقع والمواقيت'**
  String get dataSourcesScreenMessage1;

  /// Display text used in lib/features/settings/presentation/screens/data_sources_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تُحفظ إحداثيات موقع الصلاة وطريقة الحساب على الجهاز، وتُحسب المواقيت على الجهاز نفسه دون إرسال الإحداثيات إلى أي خادم. يمكنك تعديلها من شاشة الصلاة. تستخدم القبلة إذن الموقع لحساب الاتجاه. يمكن إلغاء الإذن من إعدادات الجهاز.'**
  String get dataSourcesScreenMessage2;

  /// Display text used in lib/features/settings/presentation/screens/data_sources_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'البيانات والتذكيرات'**
  String get dataSourcesScreenMessage3;

  /// Display text used in lib/features/settings/presentation/screens/data_sources_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تُحفظ المفضلة والعلامات والختمة والإعدادات محلياً. مسح بيانات التطبيق من إعدادات النظام يزيل البيانات المحلية. التذكيرات محلية ولا تحتاج خدمة رسائل عن بُعد. عند إتاحة تقارير الأعطال يمكنك اختيار تفعيلها أو إيقافها من الإعدادات؛ لا نضيف الموقع أو البحث أو سجل القراءة إلى هذه التقارير. قد تتلقى الخدمات الخارجية بيانات الاتصال. حذف البيانات المحلية لا يعني حذف سجلات الخدمات الخارجية أو النسخ الاحتياطية.'**
  String get dataSourcesScreenMessage4;

  /// Display text used in lib/features/settings/presentation/screens/data_sources_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'مصادر المحتوى'**
  String get dataSourcesScreenMessage5;

  /// Display text used in lib/features/settings/presentation/screens/data_sources_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'القرآن والأحاديث والأدعية متاحة ضمن ملفات التطبيق للعمل دون اتصال. نص المصحف بالرسم العثماني من مشروع تنزيل (tanzil.net) ويُعرض دون تعديل. توثيق الطبعة والمصدر والترخيص واعتماد المراجعة لكل مجموعة لم يكتمل بعد. بصمات سلامة الملفات تكشف التغييرات ولا تُعد توثيقاً شرعياً للمحتوى.'**
  String get dataSourcesScreenMessage6;

  /// Display text used in lib/features/settings/presentation/screens/data_sources_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'صوت تنبيه الصلاة الحالي هو صوت النظام الافتراضي.'**
  String get dataSourcesScreenMessage7;

  /// Display text used in lib/features/settings/presentation/screens/data_sources_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'إحداثيات المدن: GeoNames عبر Open-Meteo، بترخيص CC BY 4.0. الإحداثيات لمراكز المدن ويمكن تعديلها يدوياً.'**
  String get dataSourcesScreenMessage8;

  /// Display text used in lib/features/settings/presentation/screens/data_sources_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل سجل مصادر المحتوى.'**
  String get dataSourcesScreenMessage9;

  /// Display text used in lib/features/settings/presentation/screens/data_sources_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'سجل توثيق المحتوى'**
  String get dataSourcesScreenMessage10;

  /// Display text used in lib/features/settings/presentation/screens/data_sources_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'المصدر والطبعة والترخيص: بانتظار المراجعة'**
  String get dataSourcesScreenMessage11;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'اختبار الإشعارات'**
  String get notificationTestScreenMessage1;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'حالة الصلاحيات'**
  String get notificationTestScreenMessage2;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'جاهزية الخدمة'**
  String get notificationTestScreenMessage5;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'جاهزة'**
  String get notificationTestScreenMessage6;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'قيد التشغيل'**
  String get notificationTestScreenMessage7;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات المحلية'**
  String get notificationTestScreenMessage8;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'إشعار فوري'**
  String get notificationTestScreenMessage9;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'إشعار بعد دقيقة'**
  String get notificationTestScreenMessage10;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الكل'**
  String get notificationTestScreenMessage11;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'طلب الصلاحيات'**
  String get notificationTestScreenMessage13;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get notificationTestScreenMessage15;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات المجدولة'**
  String get notificationTestScreenMessage17;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات مجدولة'**
  String get notificationTestScreenMessage18;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'التحكم في المنبهات'**
  String get notificationTestScreenMessage19;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'إعادة جدولة جميع المنبهات'**
  String get notificationTestScreenMessage20;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'سجلات التصحيح'**
  String get notificationTestScreenMessage21;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get notificationTestScreenMessage22;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد سجلات'**
  String get notificationTestScreenMessage23;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'اختبار فوري'**
  String get notificationTestScreenMessage24;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'هذا إشعار اختبار فوري ناجح'**
  String get notificationTestScreenMessage25;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تم إظهار الإشعار بنجاح'**
  String get notificationTestScreenMessage26;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'فشل الاختبار: {value1}'**
  String notificationTestScreenMessage27(String value1);

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'سيظهر هذا الإشعار بعد دقيقة من الآن'**
  String get notificationTestScreenMessage28;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تمت جدولة الإشعار بعد دقيقة'**
  String get notificationTestScreenMessage29;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'فشل الجدولة: {value1}'**
  String notificationTestScreenMessage30(String value1);

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء جميع الإشعارات'**
  String get notificationTestScreenMessage31;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تم طلب الصلاحيات'**
  String get notificationTestScreenMessage32;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تم إعادة جدولة جميع المنبهات'**
  String get notificationTestScreenMessage35;

  /// Display text used in lib/features/settings/presentation/screens/settings_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'المظهر والقراءة'**
  String get settingsScreenMessage1;

  /// Display text used in lib/features/settings/presentation/screens/settings_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'مظهر التطبيق'**
  String get settingsScreenMessage2;

  /// Display text used in lib/features/settings/presentation/screens/settings_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'حسب الجهاز'**
  String get settingsScreenMessage3;

  /// Display text used in lib/features/settings/presentation/screens/settings_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get settingsScreenMessage4;

  /// Display text used in lib/features/settings/presentation/screens/settings_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get settingsScreenMessage5;

  /// Display text used in lib/features/settings/presentation/screens/settings_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'الموقع وطريقة الحساب'**
  String get settingsScreenMessage6;

  /// Display text used in lib/features/settings/presentation/screens/settings_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الصلاة'**
  String get settingsScreenMessage7;

  /// Display text used in lib/features/settings/presentation/screens/settings_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تذكير بالمواقيت حسب الموقع المحدد'**
  String get settingsScreenMessage8;

  /// Display text used in lib/features/settings/presentation/screens/settings_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'التذكيرات اليومية'**
  String get settingsScreenMessage9;

  /// Display text used in lib/features/settings/presentation/screens/settings_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تذكير {value1}'**
  String settingsScreenMessage10(String value1);

  /// Display text used in lib/features/settings/presentation/screens/settings_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'وقت التذكير'**
  String get settingsScreenMessage11;

  /// Display text used in lib/features/settings/presentation/screens/settings_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'عن سكينة'**
  String get settingsScreenMessage12;

  /// Display text used in lib/features/settings/presentation/screens/settings_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'إرسال تقارير الأعطال'**
  String get settingsScreenMessage13;

  /// Display text used in lib/features/settings/presentation/screens/settings_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'اختياري. لا يشمل الموقع أو عمليات البحث أو سجل القراءة.'**
  String get settingsScreenMessage14;

  /// Display text used in lib/features/settings/presentation/screens/settings_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تغيير إعداد مشاركة البيانات. أعد المحاولة.'**
  String get settingsScreenMessage15;

  /// Display text used in lib/features/settings/presentation/screens/settings_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get settingsScreenMessage16;

  /// Display text used in lib/features/settings/presentation/screens/settings_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'رفيقك اليومي للقرآن والأذكار ومواقيت الصلاة.'**
  String get settingsScreenMessage17;

  /// Display text used in lib/features/settings/presentation/widgets/reading_preferences.dart.
  ///
  /// In ar, this message translates to:
  /// **'حجم خط القرآن'**
  String get readingPreferencesMessage1;

  /// Display text used in lib/features/settings/presentation/widgets/reading_preferences.dart.
  ///
  /// In ar, this message translates to:
  /// **'حجم الخط {value1}'**
  String readingPreferencesMessage2(String value1);

  /// Display text used in lib/features/settings/presentation/widgets/reading_preferences.dart.
  ///
  /// In ar, this message translates to:
  /// **'تباعد الأسطر {value1}'**
  String readingPreferencesMessage3(String value1);

  /// Display text used in lib/features/splash/presentation/screens/splash_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تطبيقك للطمأنينة والهدوء'**
  String get splashScreenMessage1;

  /// Video category chip label.
  ///
  /// In ar, this message translates to:
  /// **'خطب الجمعة'**
  String get videoCategoryLabel1;

  /// Video category chip label.
  ///
  /// In ar, this message translates to:
  /// **'دروس'**
  String get videoCategoryLabel2;

  /// Video category chip label.
  ///
  /// In ar, this message translates to:
  /// **'تفسير'**
  String get videoCategoryLabel3;

  /// Video category chip label.
  ///
  /// In ar, this message translates to:
  /// **'قصص الأنبياء'**
  String get videoCategoryLabel4;

  /// Video category chip label.
  ///
  /// In ar, this message translates to:
  /// **'فقه'**
  String get videoCategoryLabel5;

  /// Existing reminder preview time.
  ///
  /// In ar, this message translates to:
  /// **'AM 07:00'**
  String get homeReminderTime1;

  /// Existing reminder preview time.
  ///
  /// In ar, this message translates to:
  /// **'PM 05:30'**
  String get homeReminderTime2;

  /// Existing reminder preview time.
  ///
  /// In ar, this message translates to:
  /// **'PM 09:00'**
  String get homeReminderTime3;

  /// Existing reminder preview time.
  ///
  /// In ar, this message translates to:
  /// **'PM 08:30'**
  String get homeReminderTime4;

  /// Title of the screen shown when required startup fails.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تشغيل التطبيق'**
  String get startupFailureTitle;

  /// Explanation on the startup failure screen.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء التحضير. حاول مرة أخرى، وإذا استمرت المشكلة فأعد تشغيل الجهاز.'**
  String get startupFailureMessage;

  /// Retry button on the startup failure screen.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get startupFailureRetry;

  /// Shown when a reminder is enabled but notification permission was refused.
  ///
  /// In ar, this message translates to:
  /// **'لم يُمنح إذن الإشعارات، لذلك لن تصلك التذكيرات. يمكنك تفعيله من إعدادات الجهاز.'**
  String get notificationPermissionDeniedMessage;

  /// Application title.
  ///
  /// In ar, this message translates to:
  /// **'Sakina'**
  String get applicationTitle;

  /// Title of the Islamic guide screen.
  ///
  /// In ar, this message translates to:
  /// **'دليل المسلم'**
  String get guideTitle;

  /// Home grid tile opening the prophets tab.
  ///
  /// In ar, this message translates to:
  /// **'الأنبياء'**
  String get guideTileProphets;

  /// Home grid tile opening the prayer description tab.
  ///
  /// In ar, this message translates to:
  /// **'صفة الصلاة'**
  String get guideTilePrayer;

  /// Home grid tile opening the pillars of Islam and Iman tab.
  ///
  /// In ar, this message translates to:
  /// **'أركان الدين'**
  String get guideTilePillars;

  /// Shown when the guide asset fails to load.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل المحتوى.'**
  String get guideLoadError;

  /// Shown when Quran verses of a guide block fail to load.
  ///
  /// In ar, this message translates to:
  /// **'تعذر عرض الآيات.'**
  String get guideQuranLoadError;

  /// Disclaimer shown at the top of each guide tab.
  ///
  /// In ar, this message translates to:
  /// **'هذا المحتوى تعليمي مبسط، ويُعرض بانتظار مراجعة المختصين. راجع أهل العلم في المسائل التفصيلية.'**
  String get guideReviewNotice;

  /// Citation line under a guide block.
  ///
  /// In ar, this message translates to:
  /// **'المصدر: {source}'**
  String guideSource(String source);

  /// Number of entries in a guide section.
  ///
  /// In ar, this message translates to:
  /// **'{count} موضوعات'**
  String guideItemCount(String count);

  /// Label of the Hijri date on the home date card.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ الهجري'**
  String get dateCardHijriLabel;

  /// Label of the Gregorian date on the home date card.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ الميلادي'**
  String get dateCardGregorianLabel;

  /// Screen reader summary of the home date card.
  ///
  /// In ar, this message translates to:
  /// **'اليوم {weekday}، {hijri}، الموافق {gregorian}'**
  String dateCardSemantics(String weekday, String hijri, String gregorian);

  /// No description provided for @externalLinkTitle.
  ///
  /// In ar, this message translates to:
  /// **'رابط خارجي'**
  String get externalLinkTitle;

  /// No description provided for @externalLinkMessage.
  ///
  /// In ar, this message translates to:
  /// **'سيتم فتح رابط خارج التطبيق، هل تريد المتابعة؟'**
  String get externalLinkMessage;

  /// No description provided for @externalLinkContinue.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get externalLinkContinue;

  /// No description provided for @hijriAdjustmentTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل التاريخ الهجري'**
  String get hijriAdjustmentTitle;

  /// No description provided for @hijriAdjustmentSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إذا اختلف التاريخ عن رؤية الهلال في بلدك'**
  String get hijriAdjustmentSubtitle;

  /// No description provided for @hijriAdjustmentMinusOne.
  ///
  /// In ar, this message translates to:
  /// **'يوم قبل'**
  String get hijriAdjustmentMinusOne;

  /// No description provided for @hijriAdjustmentNone.
  ///
  /// In ar, this message translates to:
  /// **'بدون تعديل'**
  String get hijriAdjustmentNone;

  /// No description provided for @hijriAdjustmentPlusOne.
  ///
  /// In ar, this message translates to:
  /// **'يوم بعد'**
  String get hijriAdjustmentPlusOne;

  /// No description provided for @tasbihResetDone.
  ///
  /// In ar, this message translates to:
  /// **'تمت إعادة تعيين العدّاد'**
  String get tasbihResetDone;

  /// No description provided for @asrMadhabTitle.
  ///
  /// In ar, this message translates to:
  /// **'حساب وقت العصر'**
  String get asrMadhabTitle;

  /// No description provided for @asrMadhabStandard.
  ///
  /// In ar, this message translates to:
  /// **'الجمهور (الشافعي والمالكي والحنبلي)'**
  String get asrMadhabStandard;

  /// No description provided for @asrMadhabHanafi.
  ///
  /// In ar, this message translates to:
  /// **'الحنفي'**
  String get asrMadhabHanafi;

  /// No description provided for @recitationChannelName.
  ///
  /// In ar, this message translates to:
  /// **'تلاوة القرآن الكريم'**
  String get recitationChannelName;

  /// No description provided for @recitationTitle.
  ///
  /// In ar, this message translates to:
  /// **'تلاوة القرآن'**
  String get recitationTitle;

  /// No description provided for @recitationPlay.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل التلاوة'**
  String get recitationPlay;

  /// No description provided for @recitationPause.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get recitationPause;

  /// No description provided for @recitationStop.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف التلاوة وإغلاق المشغّل'**
  String get recitationStop;

  /// No description provided for @recitationNextAyah.
  ///
  /// In ar, this message translates to:
  /// **'الآية التالية'**
  String get recitationNextAyah;

  /// No description provided for @recitationPreviousAyah.
  ///
  /// In ar, this message translates to:
  /// **'الآية السابقة'**
  String get recitationPreviousAyah;

  /// No description provided for @recitationNowPlaying.
  ///
  /// In ar, this message translates to:
  /// **'{surah} • الآية {ayah}'**
  String recitationNowPlaying(String surah, String ayah);

  /// No description provided for @recitationLoading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل…'**
  String get recitationLoading;

  /// No description provided for @recitationOffline.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت. حمّل السورة لتستمع إليها بدون إنترنت.'**
  String get recitationOffline;

  /// No description provided for @recitationError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تشغيل التلاوة'**
  String get recitationError;

  /// No description provided for @recitationReciter.
  ///
  /// In ar, this message translates to:
  /// **'القارئ'**
  String get recitationReciter;

  /// No description provided for @recitationSpeed.
  ///
  /// In ar, this message translates to:
  /// **'سرعة التلاوة'**
  String get recitationSpeed;

  /// No description provided for @recitationSpeedValue.
  ///
  /// In ar, this message translates to:
  /// **'{value}×'**
  String recitationSpeedValue(String value);

  /// No description provided for @recitationRepeat.
  ///
  /// In ar, this message translates to:
  /// **'التكرار'**
  String get recitationRepeat;

  /// No description provided for @recitationRepeatOff.
  ///
  /// In ar, this message translates to:
  /// **'بدون تكرار'**
  String get recitationRepeatOff;

  /// No description provided for @recitationRepeatTimes.
  ///
  /// In ar, this message translates to:
  /// **'{count} مرات'**
  String recitationRepeatTimes(String count);

  /// No description provided for @recitationRepeatFrom.
  ///
  /// In ar, this message translates to:
  /// **'من الآية'**
  String get recitationRepeatFrom;

  /// No description provided for @recitationRepeatTo.
  ///
  /// In ar, this message translates to:
  /// **'إلى الآية'**
  String get recitationRepeatTo;

  /// No description provided for @recitationRepeatStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التكرار'**
  String get recitationRepeatStart;

  /// No description provided for @recitationRepeating.
  ///
  /// In ar, this message translates to:
  /// **'تكرار الآيات {from} إلى {to}: {count} مرات'**
  String recitationRepeating(String from, String to, String count);

  /// No description provided for @recitationDownload.
  ///
  /// In ar, this message translates to:
  /// **'تحميل للاستماع بدون إنترنت'**
  String get recitationDownload;

  /// No description provided for @recitationDownloadConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حجم الملف {size}. هل تريد تحميله؟'**
  String recitationDownloadConfirm(String size);

  /// No description provided for @recitationDownloadAction.
  ///
  /// In ar, this message translates to:
  /// **'تحميل'**
  String get recitationDownloadAction;

  /// No description provided for @recitationDownloading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل {percent}٪'**
  String recitationDownloading(String percent);

  /// No description provided for @recitationDownloaded.
  ///
  /// In ar, this message translates to:
  /// **'محمّلة للاستماع بدون إنترنت'**
  String get recitationDownloaded;

  /// No description provided for @recitationDownloadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل السورة. تحقق من الاتصال وحاول مرة أخرى.'**
  String get recitationDownloadFailed;

  /// No description provided for @recitationDownloadsTitle.
  ///
  /// In ar, this message translates to:
  /// **'التلاوات المحمّلة'**
  String get recitationDownloadsTitle;

  /// No description provided for @recitationDownloadsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد سور محمّلة بعد. يمكنك تحميل أي سورة من صفحة التلاوة.'**
  String get recitationDownloadsEmpty;

  /// No description provided for @recitationDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف {surah}'**
  String recitationDeleted(String surah);

  /// No description provided for @recitationDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف التحميل'**
  String get recitationDelete;

  /// No description provided for @recitationSizeMb.
  ///
  /// In ar, this message translates to:
  /// **'{value} ميجابايت'**
  String recitationSizeMb(String value);

  /// No description provided for @recitationStyleMurattal.
  ///
  /// In ar, this message translates to:
  /// **'مرتّل'**
  String get recitationStyleMurattal;

  /// No description provided for @recitationStyleMujawwad.
  ///
  /// In ar, this message translates to:
  /// **'مجوّد'**
  String get recitationStyleMujawwad;

  /// No description provided for @recitationStyleMuallim.
  ///
  /// In ar, this message translates to:
  /// **'معلّم'**
  String get recitationStyleMuallim;

  /// No description provided for @recitationListenFromHere.
  ///
  /// In ar, this message translates to:
  /// **'استمع من هذه الصفحة'**
  String get recitationListenFromHere;

  /// No description provided for @recitationSource.
  ///
  /// In ar, this message translates to:
  /// **'التلاوات من Quran.com — Quran data provided by Quran.Foundation'**
  String get recitationSource;

  /// No description provided for @recitationSettings.
  ///
  /// In ar, this message translates to:
  /// **'التلاوة'**
  String get recitationSettings;

  /// No description provided for @recitationManageDownloads.
  ///
  /// In ar, this message translates to:
  /// **'إدارة التلاوات المحمّلة'**
  String get recitationManageDownloads;

  /// No description provided for @prayerAlertsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه كل صلاة'**
  String get prayerAlertsTitle;

  /// No description provided for @prayerAlertModeAdhan.
  ///
  /// In ar, this message translates to:
  /// **'الأذان'**
  String get prayerAlertModeAdhan;

  /// No description provided for @prayerAlertModeSound.
  ///
  /// In ar, this message translates to:
  /// **'صوت تنبيه'**
  String get prayerAlertModeSound;

  /// No description provided for @prayerAlertModeNotification.
  ///
  /// In ar, this message translates to:
  /// **'إشعار بدون صوت'**
  String get prayerAlertModeNotification;

  /// No description provided for @prayerAlertModeSilent.
  ///
  /// In ar, this message translates to:
  /// **'بدون تنبيه'**
  String get prayerAlertModeSilent;

  /// No description provided for @adhanVoiceTitle.
  ///
  /// In ar, this message translates to:
  /// **'صوت الأذان'**
  String get adhanVoiceTitle;

  /// No description provided for @adhanVoiceAliMulla.
  ///
  /// In ar, this message translates to:
  /// **'علي أحمد ملا'**
  String get adhanVoiceAliMulla;

  /// No description provided for @adhanVoiceNasserAlqatami.
  ///
  /// In ar, this message translates to:
  /// **'ناصر القطامي'**
  String get adhanVoiceNasserAlqatami;

  /// No description provided for @adhanVoiceNaqshbandi.
  ///
  /// In ar, this message translates to:
  /// **'النقشبندي'**
  String get adhanVoiceNaqshbandi;

  /// No description provided for @adhanVoiceIslamSobhi.
  ///
  /// In ar, this message translates to:
  /// **'إسلام صبحي'**
  String get adhanVoiceIslamSobhi;

  /// No description provided for @adhanPreviewPlay.
  ///
  /// In ar, this message translates to:
  /// **'استمع'**
  String get adhanPreviewPlay;

  /// No description provided for @adhanPreviewStop.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف الاستماع'**
  String get adhanPreviewStop;

  /// No description provided for @adhanPreviewFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تشغيل التسجيل.'**
  String get adhanPreviewFailed;

  /// No description provided for @adhanStopHint.
  ///
  /// In ar, this message translates to:
  /// **'لإيقاف الأذان اضغط «إيقاف الأذان» في الإشعار، أو اسحب الإشعار.'**
  String get adhanStopHint;

  /// No description provided for @adhanNotSupported.
  ///
  /// In ar, this message translates to:
  /// **'الأذان الكامل غير متاح في إشعارات هذا الجهاز، وسيُستخدم صوت التنبيه.'**
  String get adhanNotSupported;

  /// No description provided for @adhanChannelName.
  ///
  /// In ar, this message translates to:
  /// **'الأذان: {voice}'**
  String adhanChannelName(String voice);

  /// No description provided for @prayerReminderTitle.
  ///
  /// In ar, this message translates to:
  /// **'تذكير قبل الصلاة'**
  String get prayerReminderTitle;

  /// No description provided for @prayerReminderOff.
  ///
  /// In ar, this message translates to:
  /// **'بدون تذكير'**
  String get prayerReminderOff;

  /// No description provided for @prayerReminderMinutes.
  ///
  /// In ar, this message translates to:
  /// **'قبل {minutes} دقيقة'**
  String prayerReminderMinutes(String minutes);

  /// No description provided for @prayerReminderBody.
  ///
  /// In ar, this message translates to:
  /// **'بقي {minutes} دقيقة على صلاة {prayer}'**
  String prayerReminderBody(String minutes, String prayer);

  /// No description provided for @prayerReminderChannel.
  ///
  /// In ar, this message translates to:
  /// **'تذكير قبل الصلاة'**
  String get prayerReminderChannel;

  /// No description provided for @prayerSilentChannel.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة بدون صوت'**
  String get prayerSilentChannel;

  /// No description provided for @prayerNotificationBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لقراءة دعاء ما بعد الأذان'**
  String get prayerNotificationBody;

  /// No description provided for @testAdhanButton.
  ///
  /// In ar, this message translates to:
  /// **'جرّب تنبيه الصلاة الآن'**
  String get testAdhanButton;

  /// No description provided for @testAdhanScheduled.
  ///
  /// In ar, this message translates to:
  /// **'سيظهر تنبيه تجريبي بعد 10 ثوانٍ'**
  String get testAdhanScheduled;

  /// No description provided for @exactAlarmTitle.
  ///
  /// In ar, this message translates to:
  /// **'التنبيه في الوقت بالضبط'**
  String get exactAlarmTitle;

  /// No description provided for @exactAlarmExplain.
  ///
  /// In ar, this message translates to:
  /// **'حتى يصلك تنبيه الصلاة في وقتها تماماً، يحتاج التطبيق إذن «المنبهات والتذكيرات». سنفتح لك صفحة الإعدادات لتفعيله.'**
  String get exactAlarmExplain;

  /// No description provided for @exactAlarmAllowed.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل'**
  String get exactAlarmAllowed;

  /// No description provided for @exactAlarmNotAllowed.
  ///
  /// In ar, this message translates to:
  /// **'غير مفعّل: قد يتأخر التنبيه حتى تفتح الهاتف'**
  String get exactAlarmNotAllowed;

  /// No description provided for @exactAlarmAllow.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get exactAlarmAllow;

  /// No description provided for @batteryTitle.
  ///
  /// In ar, this message translates to:
  /// **'توفير البطارية'**
  String get batteryTitle;

  /// No description provided for @batteryExplain.
  ///
  /// In ar, this message translates to:
  /// **'بعض الأجهزة توقف تنبيهات التطبيقات لتوفير البطارية. إن تأخرت التنبيهات، افتح إعدادات التطبيق واختر «بدون قيود» في إعدادات البطارية.'**
  String get batteryExplain;

  /// No description provided for @batteryOpenSettings.
  ///
  /// In ar, this message translates to:
  /// **'فتح إعدادات التطبيق'**
  String get batteryOpenSettings;

  /// No description provided for @afterAdhanTitle.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الأذان'**
  String get afterAdhanTitle;

  /// No description provided for @prayerTimeArrived.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت صلاة {prayer}'**
  String prayerTimeArrived(String prayer);

  /// No description provided for @recitationResume.
  ///
  /// In ar, this message translates to:
  /// **'استكمال التلاوة'**
  String get recitationResume;

  /// No description provided for @afterAdhanOpen.
  ///
  /// In ar, this message translates to:
  /// **'دعاء ما بعد الأذان'**
  String get afterAdhanOpen;

  /// No description provided for @adhkarProgress.
  ///
  /// In ar, this message translates to:
  /// **'{done} من {total}'**
  String adhkarProgress(String done, String total);

  /// No description provided for @adhkarTapToCount.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على الذكر بعد قراءته لتعدّه'**
  String get adhkarTapToCount;

  /// No description provided for @adhkarDone.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get adhkarDone;

  /// No description provided for @adhkarCompleted.
  ///
  /// In ar, this message translates to:
  /// **'ما شاء الله، أتممت {category}. تقبّل الله منك.'**
  String adhkarCompleted(String category);

  /// No description provided for @adhkarReset.
  ///
  /// In ar, this message translates to:
  /// **'البدء من جديد'**
  String get adhkarReset;

  /// No description provided for @adhkarResetDone.
  ///
  /// In ar, this message translates to:
  /// **'تم تصفير العدّ'**
  String get adhkarResetDone;

  /// No description provided for @adhkarItemSemantics.
  ///
  /// In ar, this message translates to:
  /// **'{title}، تم {done} من {total}. اضغط مرتين للعدّ'**
  String adhkarItemSemantics(String title, String done, String total);

  /// No description provided for @readingNightMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع القراءة الليلية'**
  String get readingNightMode;

  /// No description provided for @readingNightModeHint.
  ///
  /// In ar, this message translates to:
  /// **'صفحة دافئة بإضاءة أهدأ للقراءة ليلاً'**
  String get readingNightModeHint;

  /// No description provided for @homeNextPrayer.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة القادمة'**
  String get homeNextPrayer;

  /// No description provided for @homeTimeLeft.
  ///
  /// In ar, this message translates to:
  /// **'بعد {duration}'**
  String homeTimeLeft(String duration);

  /// No description provided for @homeAtTime.
  ///
  /// In ar, this message translates to:
  /// **'الساعة {time}'**
  String homeAtTime(String time);

  /// No description provided for @homeNextPrayerSemantics.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة القادمة {prayer} بعد {duration}، الساعة {time}'**
  String homeNextPrayerSemantics(String prayer, String duration, String time);

  /// No description provided for @tasbihTapHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط في أي مكان هنا للعدّ'**
  String get tasbihTapHint;

  /// No description provided for @appTextSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم خط التطبيق'**
  String get appTextSize;

  /// No description provided for @appTextSizeHint.
  ///
  /// In ar, this message translates to:
  /// **'يُضاف إلى حجم الخط في إعدادات الهاتف، ولا يغيّر حجم خط المصحف'**
  String get appTextSizeHint;

  /// No description provided for @appTextSizeNormal.
  ///
  /// In ar, this message translates to:
  /// **'عادي'**
  String get appTextSizeNormal;

  /// No description provided for @appTextSizeLarge.
  ///
  /// In ar, this message translates to:
  /// **'كبير'**
  String get appTextSizeLarge;

  /// No description provided for @appTextSizeLarger.
  ///
  /// In ar, this message translates to:
  /// **'أكبر'**
  String get appTextSizeLarger;

  /// No description provided for @appTextSizeLargest.
  ///
  /// In ar, this message translates to:
  /// **'الأكبر'**
  String get appTextSizeLargest;

  /// No description provided for @addVerseToFavorites.
  ///
  /// In ar, this message translates to:
  /// **'إضافة الآية إلى المفضلة'**
  String get addVerseToFavorites;

  /// No description provided for @khatmaIncreaseDays.
  ///
  /// In ar, this message translates to:
  /// **'زيادة عدد الأيام'**
  String get khatmaIncreaseDays;

  /// No description provided for @khatmaDecreaseDays.
  ///
  /// In ar, this message translates to:
  /// **'تقليل عدد الأيام'**
  String get khatmaDecreaseDays;

  /// No description provided for @khatmaIncreaseDaily.
  ///
  /// In ar, this message translates to:
  /// **'زيادة الورد اليومي'**
  String get khatmaIncreaseDaily;

  /// No description provided for @khatmaDecreaseDaily.
  ///
  /// In ar, this message translates to:
  /// **'تقليل الورد اليومي'**
  String get khatmaDecreaseDaily;

  /// No description provided for @onboardingNoPermissionsNow.
  ///
  /// In ar, this message translates to:
  /// **'بعد هذه الصفحة نعرض عليك إذنين اختياريين، ولا نطلب أيًّا منهما قبل أن نشرح فائدته.'**
  String get onboardingNoPermissionsNow;

  /// No description provided for @onboardingLocationNote.
  ///
  /// In ar, this message translates to:
  /// **'الموقع: لحساب مواقيت الصلاة واتجاه القبلة لمكانك، ويمكنك بدلًا منه اختيار مدينتك يدويًا.'**
  String get onboardingLocationNote;

  /// No description provided for @onboardingNotificationsNote.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات: لتنبيهك بأوقات الصلاة والتذكيرات التي تختارها، ويمكنك إيقافها من الإعدادات في أي وقت.'**
  String get onboardingNotificationsNote;

  /// No description provided for @digitStyle.
  ///
  /// In ar, this message translates to:
  /// **'شكل الأرقام'**
  String get digitStyle;

  /// No description provided for @digitStyleWestern.
  ///
  /// In ar, this message translates to:
  /// **'أرقام غربية (123)'**
  String get digitStyleWestern;

  /// No description provided for @digitStyleArabic.
  ///
  /// In ar, this message translates to:
  /// **'أرقام عربية (١٢٣)'**
  String get digitStyleArabic;

  /// No description provided for @feedbackSection.
  ///
  /// In ar, this message translates to:
  /// **'الصوت والتفاعل'**
  String get feedbackSection;

  /// No description provided for @feedbackHaptics.
  ///
  /// In ar, this message translates to:
  /// **'الاهتزاز عند اللمس'**
  String get feedbackHaptics;

  /// No description provided for @feedbackHapticsHint.
  ///
  /// In ar, this message translates to:
  /// **'اهتزاز خفيف مع كل تسبيحة، وأقوى عند إتمام العدد، وعند الاتجاه للقبلة'**
  String get feedbackHapticsHint;

  /// No description provided for @feedbackSounds.
  ///
  /// In ar, this message translates to:
  /// **'أصوات الواجهة'**
  String get feedbackSounds;

  /// No description provided for @feedbackSoundsHint.
  ///
  /// In ar, this message translates to:
  /// **'نقرة خفيفة مع العدّ في المسبحة والأذكار. لا تؤثر على صوت الأذان أو التلاوة'**
  String get feedbackSoundsHint;

  /// No description provided for @designTitle.
  ///
  /// In ar, this message translates to:
  /// **'تصميم التطبيق'**
  String get designTitle;

  /// No description provided for @designWarm.
  ///
  /// In ar, this message translates to:
  /// **'دافئ ورقي'**
  String get designWarm;

  /// No description provided for @designWarmHint.
  ///
  /// In ar, this message translates to:
  /// **'البني والكريمي، الشكل الأصلي للتطبيق'**
  String get designWarmHint;

  /// No description provided for @designSage.
  ///
  /// In ar, this message translates to:
  /// **'أخضر هادئ'**
  String get designSage;

  /// No description provided for @designSageHint.
  ///
  /// In ar, this message translates to:
  /// **'أخضر زيتوني مع لمسات رملية'**
  String get designSageHint;

  /// No description provided for @designNight.
  ///
  /// In ar, this message translates to:
  /// **'ليلي ذهبي'**
  String get designNight;

  /// No description provided for @designNightHint.
  ///
  /// In ar, this message translates to:
  /// **'كحلي وذهبي، داكن دائمًا ومريح ليلًا'**
  String get designNightHint;

  /// No description provided for @designNightAlwaysDark.
  ///
  /// In ar, this message translates to:
  /// **'التصميم الليلي الذهبي داكن دائمًا. اختر تصميمًا آخر لتغيير المظهر.'**
  String get designNightAlwaysDark;

  /// No description provided for @drawerPrayerSection.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة'**
  String get drawerPrayerSection;

  /// No description provided for @readerLayoutTitle.
  ///
  /// In ar, this message translates to:
  /// **'طريقة العرض'**
  String get readerLayoutTitle;

  /// No description provided for @readerLayoutContinuous.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get readerLayoutContinuous;

  /// No description provided for @readerLayoutPages.
  ///
  /// In ar, this message translates to:
  /// **'صفحات'**
  String get readerLayoutPages;

  /// No description provided for @readerLayoutVerses.
  ///
  /// In ar, this message translates to:
  /// **'آية بآية'**
  String get readerLayoutVerses;

  /// No description provided for @readerLayoutPagesHint.
  ///
  /// In ar, this message translates to:
  /// **'حدود الصفحات مطابقة للمصحف، أما توزيع الأسطر فبحسب حجم الشاشة والخط.'**
  String get readerLayoutPagesHint;

  /// No description provided for @readerMushafPage.
  ///
  /// In ar, this message translates to:
  /// **'صفحة {page}'**
  String readerMushafPage(String page);

  /// No description provided for @readerVerseActions.
  ///
  /// In ar, this message translates to:
  /// **'خيارات الآية {number}'**
  String readerVerseActions(String number);

  /// No description provided for @readerVersePlay.
  ///
  /// In ar, this message translates to:
  /// **'استمع من هذه الآية'**
  String get readerVersePlay;

  /// No description provided for @readerVerseBookmark.
  ///
  /// In ar, this message translates to:
  /// **'ضع العلامة هنا'**
  String get readerVerseBookmark;

  /// No description provided for @readerVerseCopy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الآية'**
  String get readerVerseCopy;

  /// No description provided for @readerVerseCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الآية'**
  String get readerVerseCopied;

  /// No description provided for @readerVerseHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطولاً على الآية لعرض خياراتها'**
  String get readerVerseHint;

  /// No description provided for @readerPageCompressed.
  ///
  /// In ar, this message translates to:
  /// **'صُغّر الخط لتتسع الصفحة للشاشة؛ وضع «متصل» يعرض خطاً أكبر'**
  String get readerPageCompressed;

  /// No description provided for @notificationCategoryAdhkar.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get notificationCategoryAdhkar;

  /// No description provided for @notificationCategoryQuran.
  ///
  /// In ar, this message translates to:
  /// **'القرآن الكريم'**
  String get notificationCategoryQuran;

  /// No description provided for @notificationCategoryPrayer.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة'**
  String get notificationCategoryPrayer;

  /// No description provided for @notificationCategoryVerse.
  ///
  /// In ar, this message translates to:
  /// **'آية اليوم'**
  String get notificationCategoryVerse;

  /// No description provided for @notificationActionStartAdhkar.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الأذكار'**
  String get notificationActionStartAdhkar;

  /// No description provided for @notificationActionReadNow.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ الآن'**
  String get notificationActionReadNow;

  /// No description provided for @notificationActionAfterAdhan.
  ///
  /// In ar, this message translates to:
  /// **'دعاء ما بعد الأذان'**
  String get notificationActionAfterAdhan;

  /// No description provided for @notificationActionPrayerTimes.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة'**
  String get notificationActionPrayerTimes;

  /// No description provided for @notificationActionOpenVerse.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ في المصحف'**
  String get notificationActionOpenVerse;

  /// No description provided for @prayerNotificationTimeLine.
  ///
  /// In ar, this message translates to:
  /// **'وقت الأذان {time}'**
  String prayerNotificationTimeLine(String time);

  /// No description provided for @prayerReminderTimeLine.
  ///
  /// In ar, this message translates to:
  /// **'موعد الصلاة {time}'**
  String prayerReminderTimeLine(String time);

  /// No description provided for @dailyVerseNotificationReference.
  ///
  /// In ar, this message translates to:
  /// **'{surah} · الآية {ayah}'**
  String dailyVerseNotificationReference(String surah, String ayah);

  /// No description provided for @dailyVerseReminderSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'آية كل يوم في الوقت الذي تختاره'**
  String get dailyVerseReminderSubtitle;

  /// Shown when a link or notification points to a page that does not exist.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح هذه الصفحة.'**
  String get routeNotFoundMessage;

  /// Button on the missing-page screen that returns to the home screen.
  ///
  /// In ar, this message translates to:
  /// **'العودة إلى الرئيسية'**
  String get routeBackHome;

  /// Settings row that opens the on-device diagnostics log.
  ///
  /// In ar, this message translates to:
  /// **'سجل التشخيص'**
  String get diagnosticsTitle;

  /// Subtitle of the diagnostics row.
  ///
  /// In ar, this message translates to:
  /// **'أخطاء محفوظة على جهازك فقط، تساعد على إصلاح التنبيهات'**
  String get diagnosticsSubtitle;

  /// When background rescheduling last succeeded.
  ///
  /// In ar, this message translates to:
  /// **'آخر تحديث ناجح للتنبيهات في الخلفية: {time}'**
  String diagnosticsLastBackgroundOk(String time);

  /// When background rescheduling last failed, and the error type.
  ///
  /// In ar, this message translates to:
  /// **'آخر خطأ في تحديث التنبيهات: {time} ({type})'**
  String diagnosticsLastBackgroundError(String time, String type);

  /// Shown instead of a time when something has not happened yet.
  ///
  /// In ar, this message translates to:
  /// **'لم يحدث بعد'**
  String get diagnosticsNever;

  /// Diagnostics log has no entries.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أخطاء مسجلة.'**
  String get diagnosticsEmpty;

  /// Copies the diagnostics log to the clipboard.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get diagnosticsCopy;

  /// Confirmation after copying the diagnostics log.
  ///
  /// In ar, this message translates to:
  /// **'نُسخ السجل'**
  String get diagnosticsCopied;

  /// Deletes the diagnostics log.
  ///
  /// In ar, this message translates to:
  /// **'مسح السجل'**
  String get diagnosticsClear;

  /// iOS notice on the last day of scheduled prayer alerts.
  ///
  /// In ar, this message translates to:
  /// **'افتح سكينة لتستمر تنبيهات الصلاة'**
  String get prayerWindowEndingTitle;

  /// Body of the iOS notice that scheduled prayer alerts are about to run out.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الصلاة مجهّزة حتى نهاية اليوم. افتح التطبيق لتجهيز الأيام التالية.'**
  String get prayerWindowEndingBody;

  /// Title of the dialog asking for the exact alarms permission.
  ///
  /// In ar, this message translates to:
  /// **'لتصل تنبيهات الصلاة في وقتها'**
  String get exactAlarmPromptTitle;

  /// Why the exact alarms permission is needed: without it Android holds alerts until the screen is turned on.
  ///
  /// In ar, this message translates to:
  /// **'عندما يكون الهاتف مقفلاً، يؤخر أندرويد التنبيهات العادية حتى تفتح الشاشة. اسمح لسكينة بإذن «المنبهات والتذكيرات» ليصلك تنبيه الصلاة والأذان في وقتهما. سنفتح لك صفحة الإعدادات.'**
  String get exactAlarmPromptBody;

  /// Dismisses the exact alarms dialog for now.
  ///
  /// In ar, this message translates to:
  /// **'لاحقاً'**
  String get exactAlarmLater;

  /// Warning card shown while the exact alarms permission is denied and prayer alerts are on.
  ///
  /// In ar, this message translates to:
  /// **'قد لا تصل تنبيهات الصلاة في وقتها والهاتف مقفل، فأندرويد يؤخرها حتى تفتح الشاشة. اسمح بإذن «المنبهات والتذكيرات» لتصل في وقتها.'**
  String get exactAlarmLateWarning;

  /// Progress label of the first-run permission steps.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة {current} من {total}'**
  String permissionIntroStepLabel(String current, String total);

  /// Declines a first-run permission step without asking the system.
  ///
  /// In ar, this message translates to:
  /// **'ليس الآن'**
  String get permissionIntroNotNow;

  /// Moves on after a first-run permission step has an answer.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get permissionIntroContinue;

  /// Opens this app's page in system settings.
  ///
  /// In ar, this message translates to:
  /// **'فتح الإعدادات'**
  String get permissionIntroOpenSettings;

  /// Opens the device location services settings.
  ///
  /// In ar, this message translates to:
  /// **'فتح إعدادات الموقع'**
  String get permissionIntroOpenLocationSettings;

  /// Title of the first-run notifications step.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الصلاة في وقتها'**
  String get permissionIntroNotificationsTitle;

  /// Why notifications help, shown before the system dialog.
  ///
  /// In ar, this message translates to:
  /// **'اسمح لسكينة بالإشعارات ليصلك تنبيه عند دخول وقت كل صلاة، وما تختاره من تذكيرات.'**
  String get permissionIntroNotificationsBody;

  /// Notifications benefit.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه عند دخول وقت كل صلاة'**
  String get permissionIntroNotificationsBenefit1;

  /// Notifications benefit: adhan sound where supported and enabled.
  ///
  /// In ar, this message translates to:
  /// **'الأذان مع التنبيه إذا فعّلته وكان جهازك يدعمه'**
  String get permissionIntroNotificationsBenefit2;

  /// Notifications benefit.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات الأذكار والورد اليومي'**
  String get permissionIntroNotificationsBenefit3;

  /// Notifications can be managed later in settings.
  ///
  /// In ar, this message translates to:
  /// **'تختار التنبيهات أو توقفها من الإعدادات متى شئت'**
  String get permissionIntroNotificationsBenefit4;

  /// Asks the system for notification permission.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الإشعارات'**
  String get permissionIntroEnableNotifications;

  /// Notifications were allowed.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات مفعّلة، وستصلك التنبيهات التي تختارها.'**
  String get permissionIntroNotificationsGranted;

  /// Notifications were refused but can be asked again later.
  ///
  /// In ar, this message translates to:
  /// **'لم تُفعَّل الإشعارات، ويمكنك تفعيلها لاحقًا من الإعدادات.'**
  String get permissionIntroNotificationsDenied;

  /// Notifications can only be allowed from system settings.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات متوقفة لسكينة في إعدادات الجهاز. لتفعيلها افتح الإعدادات واسمح بالإشعارات.'**
  String get permissionIntroNotificationsSettings;

  /// Title of the first-run location step.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت دقيقة لمكانك'**
  String get permissionIntroLocationTitle;

  /// Why location helps, shown before the system dialog.
  ///
  /// In ar, this message translates to:
  /// **'يستخدم سكينة موقعك لحساب مواقيت الصلاة لمدينتك وتحديد اتجاه القبلة. يجري الحساب على جهازك، ولا يُرسل موقعك إلى أي خادم.'**
  String get permissionIntroLocationBody;

  /// Location benefit.
  ///
  /// In ar, this message translates to:
  /// **'معرفة مدينتك الحالية'**
  String get permissionIntroLocationBenefit1;

  /// Location benefit.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت صلاة دقيقة لمكانك'**
  String get permissionIntroLocationBenefit2;

  /// Location benefit.
  ///
  /// In ar, this message translates to:
  /// **'اتجاه القبلة من حيث أنت'**
  String get permissionIntroLocationBenefit3;

  /// Location benefit.
  ///
  /// In ar, this message translates to:
  /// **'تحديث المواقيت إذا انتقلت إلى مدينة أخرى'**
  String get permissionIntroLocationBenefit4;

  /// Asks the system for foreground location permission.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الموقع'**
  String get permissionIntroEnableLocation;

  /// Opens manual city selection instead of location access.
  ///
  /// In ar, this message translates to:
  /// **'اختيار المدينة يدويًا'**
  String get permissionIntroChooseCity;

  /// Shown while the device position is being read.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحديد موقعك…'**
  String get permissionIntroLocating;

  /// The prayer location that is now active.
  ///
  /// In ar, this message translates to:
  /// **'موقع الصلاة: {label}'**
  String permissionIntroLocationSet(String label);

  /// Location was refused but can be asked again later.
  ///
  /// In ar, this message translates to:
  /// **'لم يُسمح بالوصول إلى الموقع. يمكنك اختيار مدينتك يدويًا أو السماح به لاحقًا.'**
  String get permissionIntroLocationDenied;

  /// Location can only be allowed from system settings.
  ///
  /// In ar, this message translates to:
  /// **'الوصول إلى الموقع متوقف لسكينة. افتح الإعدادات واسمح به أثناء استخدام التطبيق، أو اختر مدينتك يدويًا.'**
  String get permissionIntroLocationSettings;

  /// Device location services are off.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الموقع متوقفة في جهازك. فعّلها من الإعدادات، أو اختر مدينتك يدويًا.'**
  String get permissionIntroLocationServicesOff;

  /// The device fix was too imprecise to use.
  ///
  /// In ar, this message translates to:
  /// **'لم يحدد الجهاز موقعك بدقة كافية. جرّب في مكان مفتوح أو اختر مدينتك يدويًا.'**
  String get locationTooInaccurateMessage;

  /// Label of a device location close to, but outside, a listed city.
  ///
  /// In ar, this message translates to:
  /// **'بالقرب من {city}'**
  String nearCityLabel(String city);

  /// A last-known position was used because no new fix was available.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديد موقعك الآن، فاستُخدم آخر موقع معروف للجهاز. أعد المحاولة لاحقًا لتحديثه.'**
  String get staleLocationNotice;

  /// The active prayer location follows the device.
  ///
  /// In ar, this message translates to:
  /// **'المصدر: موقع الجهاز، ويتحدّث عند فتح التطبيق إذا انتقلت إلى مكان آخر.'**
  String get locationSourceDevice;

  /// The active prayer location was chosen by hand.
  ///
  /// In ar, this message translates to:
  /// **'المصدر: موقع اخترته يدويًا، ولا يتغير تلقائيًا.'**
  String get locationSourceManual;

  /// Reported accuracy of an approximate device location.
  ///
  /// In ar, this message translates to:
  /// **'موقع تقريبي في حدود {distance}، وهي دقة كافية لحساب المواقيت.'**
  String locationAccuracyApproximate(String distance);

  /// A distance in kilometres.
  ///
  /// In ar, this message translates to:
  /// **'{value} كم'**
  String distanceKilometers(String value);

  /// A distance in metres.
  ///
  /// In ar, this message translates to:
  /// **'{value} م'**
  String distanceMeters(String value);

  /// Quran index view: list of surahs.
  ///
  /// In ar, this message translates to:
  /// **'السور'**
  String get quranIndexSurahs;

  /// Quran index view: the 30 juz.
  ///
  /// In ar, this message translates to:
  /// **'الأجزاء'**
  String get quranIndexJuz;

  /// Quran index view: the 60 hizb.
  ///
  /// In ar, this message translates to:
  /// **'الأحزاب'**
  String get quranIndexHizb;

  /// Title of one juz in the index.
  ///
  /// In ar, this message translates to:
  /// **'الجزء {number}'**
  String quranJuzTitle(String number);

  /// Title of one hizb in the index.
  ///
  /// In ar, this message translates to:
  /// **'الحزب {number}'**
  String quranHizbTitle(String number);

  /// Where a juz or hizb begins.
  ///
  /// In ar, this message translates to:
  /// **'يبدأ من {surah}، الآية {ayah} • الصفحة {page}'**
  String quranDivisionStart(String surah, String ayah, String page);

  /// Button and dialog title: jump to a mushaf page or a verse.
  ///
  /// In ar, this message translates to:
  /// **'انتقال إلى صفحة أو آية'**
  String get quranGoTo;

  /// Label of the go-to field.
  ///
  /// In ar, this message translates to:
  /// **'رقم الصفحة أو السورة:الآية'**
  String get quranGoToLabel;

  /// Example input for the go-to field: a page, or surah:ayah.
  ///
  /// In ar, this message translates to:
  /// **'مثال: ٢٠٥ أو ٢:٢٥٥'**
  String get quranGoToHint;

  /// Go-to input does not match a page (1-604) or an existing verse.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد صفحة أو آية بهذا الرقم'**
  String get quranGoToInvalid;

  /// Confirms the go-to dialog.
  ///
  /// In ar, this message translates to:
  /// **'انتقال'**
  String get quranGoToAction;

  /// The juz/hizb index could not be built from the bundled Quran.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل فهرس الأجزاء والأحزاب.'**
  String get quranIndexLoadFailed;

  /// Calculation method: Gulf region (Fajr 19.5°, Isha 90 min).
  ///
  /// In ar, this message translates to:
  /// **'منطقة الخليج'**
  String get prayerMethodGulf;

  /// Calculation method: Kuwait.
  ///
  /// In ar, this message translates to:
  /// **'الكويت'**
  String get prayerMethodKuwait;

  /// Calculation method: Qatar.
  ///
  /// In ar, this message translates to:
  /// **'قطر'**
  String get prayerMethodQatar;

  /// Calculation method: Dubai / UAE.
  ///
  /// In ar, this message translates to:
  /// **'دبي (الإمارات)'**
  String get prayerMethodDubai;

  /// Calculation method: Jordan (Ministry of Awqaf).
  ///
  /// In ar, this message translates to:
  /// **'الأردن'**
  String get prayerMethodJordan;

  /// Calculation method: Algeria.
  ///
  /// In ar, this message translates to:
  /// **'الجزائر'**
  String get prayerMethodAlgeria;

  /// Calculation method: Tunisia.
  ///
  /// In ar, this message translates to:
  /// **'تونس'**
  String get prayerMethodTunisia;

  /// Calculation method: Morocco.
  ///
  /// In ar, this message translates to:
  /// **'المغرب'**
  String get prayerMethodMorocco;

  /// Calculation method: Türkiye, Diyanet.
  ///
  /// In ar, this message translates to:
  /// **'تركيا (رئاسة الشؤون الدينية)'**
  String get prayerMethodTurkiye;

  /// Calculation method: University of Islamic Sciences, Karachi.
  ///
  /// In ar, this message translates to:
  /// **'جامعة العلوم الإسلامية بكراتشي'**
  String get prayerMethodKarachi;

  /// Calculation method: ISNA (North America).
  ///
  /// In ar, this message translates to:
  /// **'الجمعية الإسلامية لأمريكا الشمالية'**
  String get prayerMethodNorthAmerica;

  /// Calculation method: Moonsighting Committee Worldwide.
  ///
  /// In ar, this message translates to:
  /// **'لجنة رؤية الهلال'**
  String get prayerMethodMoonsighting;

  /// Calculation method: France, UOIF 12°.
  ///
  /// In ar, this message translates to:
  /// **'فرنسا (اتحاد المنظمات الإسلامية)'**
  String get prayerMethodFrance;

  /// Calculation method: Spiritual Administration of Muslims of Russia.
  ///
  /// In ar, this message translates to:
  /// **'روسيا'**
  String get prayerMethodRussia;

  /// Calculation method: Portugal.
  ///
  /// In ar, this message translates to:
  /// **'البرتغال'**
  String get prayerMethodPortugal;

  /// Calculation method: Singapore (MUIS), also used in Malaysia and Brunei.
  ///
  /// In ar, this message translates to:
  /// **'سنغافورة وماليزيا'**
  String get prayerMethodSingapore;

  /// Calculation method: Indonesia (Kemenag).
  ///
  /// In ar, this message translates to:
  /// **'إندونيسيا'**
  String get prayerMethodIndonesia;

  /// Settings entry and sheet title: shift each prayer time by minutes.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المواقيت بالدقائق'**
  String get prayerAdjustmentsTitle;

  /// Why a user would adjust prayer times.
  ///
  /// In ar, this message translates to:
  /// **'لمطابقة مواقيت مسجدك أو التقويم الرسمي'**
  String get prayerAdjustmentsSubtitle;

  /// No minute adjustment is applied.
  ///
  /// In ar, this message translates to:
  /// **'بلا تعديل'**
  String get prayerAdjustmentsNone;

  /// A shift of a prayer time in minutes, e.g. +2 د.
  ///
  /// In ar, this message translates to:
  /// **'{sign}{minutes} د'**
  String prayerAdjustmentMinutes(String sign, String minutes);

  /// Screen-reader label: make this prayer one minute earlier.
  ///
  /// In ar, this message translates to:
  /// **'قبل {name} بدقيقة'**
  String prayerAdjustmentEarlier(String name);

  /// Screen-reader label: make this prayer one minute later.
  ///
  /// In ar, this message translates to:
  /// **'بعد {name} بدقيقة'**
  String prayerAdjustmentLater(String name);

  /// Resets all minute adjustments to zero.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء كل التعديلات'**
  String get prayerAdjustmentsReset;

  /// Explains that the shift applies every day and to alerts.
  ///
  /// In ar, this message translates to:
  /// **'يُضاف التعديل إلى الوقت المحسوب لكل يوم، ويُطبَّق على التنبيهات أيضًا.'**
  String get prayerAdjustmentsNote;

  /// Opens the explanation of the calculation.
  ///
  /// In ar, this message translates to:
  /// **'كيف حُسبت هذه المواقيت؟'**
  String get prayerExplainButton;

  /// Title of the calculation explanation sheet.
  ///
  /// In ar, this message translates to:
  /// **'طريقة حساب المواقيت'**
  String get prayerExplainTitle;

  /// Row label: calculation method.
  ///
  /// In ar, this message translates to:
  /// **'الطريقة'**
  String get prayerExplainMethod;

  /// Row label: how Fajr is found.
  ///
  /// In ar, this message translates to:
  /// **'الفجر'**
  String get prayerExplainFajr;

  /// Row label: how Isha is found.
  ///
  /// In ar, this message translates to:
  /// **'العشاء'**
  String get prayerExplainIsha;

  /// Twilight angle rule.
  ///
  /// In ar, this message translates to:
  /// **'عندما تكون الشمس {degrees}° تحت الأفق'**
  String prayerExplainAngle(String degrees);

  /// Isha a fixed time after Maghrib.
  ///
  /// In ar, this message translates to:
  /// **'بعد المغرب بـ {minutes} دقيقة'**
  String prayerExplainInterval(String minutes);

  /// Umm al-Qura Ramadan rule.
  ///
  /// In ar, this message translates to:
  /// **'في رمضان يكون العشاء بعد المغرب بـ ١٢٠ دقيقة بدل ٩٠، كما في تقويم أم القرى.'**
  String get prayerExplainRamadan;

  /// Row label: Asr rule.
  ///
  /// In ar, this message translates to:
  /// **'العصر'**
  String get prayerExplainAsr;

  /// Row label: high-latitude rule.
  ///
  /// In ar, this message translates to:
  /// **'خطوط العرض العليا'**
  String get prayerExplainHighLatitude;

  /// Seventh-of-the-night rule, used above 48° latitude.
  ///
  /// In ar, this message translates to:
  /// **'لا يتقدم الفجر ولا يتأخر العشاء عن سُبع الليل'**
  String get prayerExplainSeventh;

  /// Middle-of-the-night rule.
  ///
  /// In ar, this message translates to:
  /// **'لا يتجاوز الفجر والعشاء منتصف الليل'**
  String get prayerExplainMiddle;

  /// Row label: time zone used.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة الزمنية'**
  String get prayerExplainTimeZone;

  /// Row label: minutes the method itself adds (e.g. Dhuhr +1).
  ///
  /// In ar, this message translates to:
  /// **'تعديلات الطريقة'**
  String get prayerExplainMethodAdjustments;

  /// Row label: the user's own minute adjustments.
  ///
  /// In ar, this message translates to:
  /// **'تعديلاتك'**
  String get prayerExplainYourAdjustments;

  /// Explains offline astronomical calculation and where to change it.
  ///
  /// In ar, this message translates to:
  /// **'الحساب فلكي ويتم على جهازك دون إنترنت. إن اختلفت المواقيت عن مسجدك فغيّر الطريقة من «تعديل الموقع»، أو عدّل الدقائق من الإعدادات.'**
  String get prayerExplainFootnote;

  /// Name of sunrise in the adjustments list.
  ///
  /// In ar, this message translates to:
  /// **'الشروق'**
  String get prayerSunriseName;

  /// Separator between items of an inline list.
  ///
  /// In ar, this message translates to:
  /// **'، '**
  String get listSeparator;

  /// Card title: the method usually used in this country.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الحساب المعتادة في {country}'**
  String methodSuggestionTitle(String country);

  /// Explains the suggested method versus the current one.
  ///
  /// In ar, this message translates to:
  /// **'تستخدم الآن «{current}». الطريقة المعتادة هنا «{suggested}»، وقد تطابق مواقيت المساجد أكثر.'**
  String methodSuggestionBody(String current, String suggested);

  /// Accepts the suggested calculation method.
  ///
  /// In ar, this message translates to:
  /// **'استخدام «{method}»'**
  String methodSuggestionAccept(String method);

  /// Keeps the current method and hides the suggestion for this country.
  ///
  /// In ar, this message translates to:
  /// **'الإبقاء على طريقتي'**
  String get methodSuggestionDismiss;

  /// Hint of the offline city search field.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم المدينة بالعربية أو بالإنجليزية'**
  String get prayerCitySearchHint;

  /// Attribution for the bundled GeoNames city list.
  ///
  /// In ar, this message translates to:
  /// **'قائمة المدن ومناطقها الزمنية من GeoNames ‏(www.geonames.org)، بترخيص المشاع الإبداعي CC BY 4.0. أُخذت الأسماء العربية من الأسماء البديلة الموسومة بالعربية في GeoNames، وتظهر المدن التي لا اسم عربيًّا لها باسمها اللاتيني.'**
  String get dataSourcesCities;

  /// Alert health check screen title and Settings entry.
  ///
  /// In ar, this message translates to:
  /// **'هل ستصلني تنبيهات الصلاة؟'**
  String get alertHealthTitle;

  /// Settings subtitle of the alert health check.
  ///
  /// In ar, this message translates to:
  /// **'فحص سريع لكل ما يمنع وصول الأذان في وقته'**
  String get alertHealthEntrySubtitle;

  /// No problem found.
  ///
  /// In ar, this message translates to:
  /// **'كل شيء جاهز لوصول التنبيهات في وقتها'**
  String get alertHealthAllGood;

  /// Number of problems found.
  ///
  /// In ar, this message translates to:
  /// **'وُجد ما قد يمنع وصول التنبيهات ({count})'**
  String alertHealthProblems(String count);

  /// Prayer alerts waiting in the system.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات صلاة جاهزة في النظام الآن: {count}'**
  String alertHealthScheduledCount(String count);

  /// Problem: notifications not allowed.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات غير مسموح بها'**
  String get alertHealthNotificationsOff;

  /// Why notifications matter.
  ///
  /// In ar, this message translates to:
  /// **'لن يظهر أي تنبيه حتى تسمح لسكينة بإرسال الإشعارات.'**
  String get alertHealthNotificationsOffDetail;

  /// Asks for or opens notification permission.
  ///
  /// In ar, this message translates to:
  /// **'السماح بالإشعارات'**
  String get alertHealthOpenSettings;

  /// Problem: prayer alerts switched off in Settings.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الصلاة متوقفة'**
  String get alertHealthAlertsDisabled;

  /// Where to switch prayer alerts on.
  ///
  /// In ar, this message translates to:
  /// **'فعّل «تنبيهات الصلاة» في قسم الصلاة من الإعدادات.'**
  String get alertHealthAlertsDisabledDetail;

  /// Problem: no prayer location.
  ///
  /// In ar, this message translates to:
  /// **'لم يُحدَّد موقع للصلاة'**
  String get alertHealthNoLocation;

  /// How to set a location.
  ///
  /// In ar, this message translates to:
  /// **'اختر مدينتك أو موقع جهازك من «الموقع وطريقة الحساب» لتُحسب المواقيت.'**
  String get alertHealthNoLocationDetail;

  /// Problem: alerts on but none scheduled.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تنبيهات مجدولة'**
  String get alertHealthNothingScheduled;

  /// Explains and offers rescheduling.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات مفعّلة لكن لا يوجد أي تنبيه منتظر في النظام. أعد الجدولة الآن.'**
  String get alertHealthNothingScheduledDetail;

  /// Reschedules prayer alerts now.
  ///
  /// In ar, this message translates to:
  /// **'إعادة جدولة التنبيهات'**
  String get alertHealthReschedule;

  /// Problem: exact alarms not allowed.
  ///
  /// In ar, this message translates to:
  /// **'قد تتأخر التنبيهات'**
  String get alertHealthExactOff;

  /// Why exact alarms matter.
  ///
  /// In ar, this message translates to:
  /// **'لم يُسمح بالمنبهات الدقيقة، فقد يؤخر أندرويد الأذان بضع دقائق أو حتى فتح الشاشة.'**
  String get alertHealthExactOffDetail;

  /// Problem: battery optimisation restricts the app.
  ///
  /// In ar, this message translates to:
  /// **'توفير البطارية يقيّد سكينة'**
  String get alertHealthBattery;

  /// Why battery optimisation matters.
  ///
  /// In ar, this message translates to:
  /// **'قد يمنع ذلك تجديد التنبيهات في الخلفية، خاصة على هواتف شاومي وهواوي وسامسونج. اختر «غير مقيّد» لسكينة.'**
  String get alertHealthBatteryDetail;

  /// Problem: last background reschedule failed.
  ///
  /// In ar, this message translates to:
  /// **'فشلت آخر محاولة لتجديد التنبيهات'**
  String get alertHealthBackgroundFailing;

  /// Explains background failure.
  ///
  /// In ar, this message translates to:
  /// **'تجدد سكينة التنبيهات في الخلفية كل بضع ساعات، وآخر محاولة لم تنجح. أعد الجدولة الآن، وراجع «سجل التشخيص» إن تكرر ذلك.'**
  String get alertHealthBackgroundFailingDetail;

  /// Label: last successful background reschedule.
  ///
  /// In ar, this message translates to:
  /// **'آخر تجديد ناجح في الخلفية'**
  String get alertHealthLastBackground;

  /// Privacy note for the health check.
  ///
  /// In ar, this message translates to:
  /// **'يُجرى هذا الفحص على جهازك فقط، ولا يُرسَل شيء منه إلى أي جهة.'**
  String get alertHealthFootnote;

  /// Verse action: open al-Tafsir al-Muyassar.
  ///
  /// In ar, this message translates to:
  /// **'التفسير الميسر'**
  String get readerVerseTafsir;

  /// Tafsir sheet title: surah name and ayah number.
  ///
  /// In ar, this message translates to:
  /// **'{surah}، الآية {ayah}'**
  String tafsirTitle(String surah, String ayah);

  /// The bundled tafsir could not be read.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح التفسير.'**
  String get tafsirUnavailable;

  /// Attribution required by Tanzil and the translator.
  ///
  /// In ar, this message translates to:
  /// **'المصدر: التفسير الميسر، مجمع الملك فهد لطباعة المصحف الشريف، عن موقع تنزيل (tanzil.net). النص كما هو دون أي تعديل.'**
  String get tafsirSource;

  /// Saved verse colour.
  ///
  /// In ar, this message translates to:
  /// **'أخضر'**
  String get savedColorGreen;

  /// Saved verse colour.
  ///
  /// In ar, this message translates to:
  /// **'ذهبي'**
  String get savedColorGold;

  /// Saved verse colour.
  ///
  /// In ar, this message translates to:
  /// **'أزرق'**
  String get savedColorBlue;

  /// Saved verse colour.
  ///
  /// In ar, this message translates to:
  /// **'وردي'**
  String get savedColorRose;

  /// Saved verse colour.
  ///
  /// In ar, this message translates to:
  /// **'بنفسجي'**
  String get savedColorViolet;

  /// Verse action: save the verse with a colour.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الآية بلون'**
  String get readerVerseSave;

  /// Verse action: write a private note.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة على الآية'**
  String get readerVerseNote;

  /// Optional label of a saved verse.
  ///
  /// In ar, this message translates to:
  /// **'اسم قصير (اختياري)'**
  String get savedVerseLabel;

  /// Saves the verse.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get savedVerseSave;

  /// Removes a saved verse.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الحفظ'**
  String get savedVerseRemove;

  /// Confirmation: verse saved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظت الآية'**
  String get savedVerseSaved;

  /// Confirmation: verse removed.
  ///
  /// In ar, this message translates to:
  /// **'أُزيلت الآية من المحفوظات'**
  String get savedVerseRemoved;

  /// Saving to the local database failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الحفظ. حاول مرة أخرى.'**
  String get savedVerseFailed;

  /// Edit a saved verse or note.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get savedVerseEdit;

  /// Reference of a saved verse.
  ///
  /// In ar, this message translates to:
  /// **'{surah}، الآية {ayah}'**
  String savedVerseReference(String surah, String ayah);

  /// Hint of the note editor.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ما يخطر لك عند هذه الآية…'**
  String get verseNoteHint;

  /// Privacy note for saved verses and notes.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات والمحفوظات على جهازك فقط، ولا تُرسَل إلى أي جهة.'**
  String get verseNotePrivacy;

  /// Saves the note.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الملاحظة'**
  String get verseNoteSave;

  /// Confirmation: note saved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظت الملاحظة'**
  String get verseNoteSaved;

  /// Confirmation: empty note deleted.
  ///
  /// In ar, this message translates to:
  /// **'حُذفت الملاحظة'**
  String get verseNoteDeleted;

  /// Screen title and Quran index action.
  ///
  /// In ar, this message translates to:
  /// **'الآيات المحفوظة والملاحظات'**
  String get savedVersesTitle;

  /// Tab: saved verses.
  ///
  /// In ar, this message translates to:
  /// **'المحفوظة'**
  String get savedVersesTab;

  /// Tab: notes.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات'**
  String get verseNotesTab;

  /// Empty state of saved verses.
  ///
  /// In ar, this message translates to:
  /// **'لم تحفظ أي آية بعد. اضغط مطولًا على آية في المصحف واختر «حفظ الآية بلون».'**
  String get savedVersesEmpty;

  /// Empty state of notes.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ملاحظات بعد. اضغط مطولًا على آية واختر «ملاحظة على الآية».'**
  String get verseNotesEmpty;

  /// Settings section: export, import, erase user data.
  ///
  /// In ar, this message translates to:
  /// **'بياناتي'**
  String get myDataSection;

  /// Exports user data to a file.
  ///
  /// In ar, this message translates to:
  /// **'حفظ نسخة من بياناتي'**
  String get myDataExport;

  /// What the export contains.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات، والختمة، والعلامة، والمحفوظات، والملاحظات في ملف تحفظه أنت'**
  String get myDataExportSubtitle;

  /// Export done.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ الملف'**
  String get myDataExported;

  /// Imports user data from a backup file.
  ///
  /// In ar, this message translates to:
  /// **'استعادة بياناتي من ملف'**
  String get myDataImport;

  /// Import replaces current data.
  ///
  /// In ar, this message translates to:
  /// **'تحل بيانات الملف محل بياناتك الحالية'**
  String get myDataImportSubtitle;

  /// Import confirmation title.
  ///
  /// In ar, this message translates to:
  /// **'استعادة هذه النسخة؟'**
  String get myDataImportTitle;

  /// What the backup holds.
  ///
  /// In ar, this message translates to:
  /// **'نسخة بتاريخ {date}: {verses} آية محفوظة، و{notes} ملاحظة، و{settings} إعدادًا. ستحل محل بياناتك الحالية، ثم يُعاد فتح التطبيق.'**
  String myDataImportSummary(
    String date,
    String verses,
    String notes,
    String settings,
  );

  /// Confirms import.
  ///
  /// In ar, this message translates to:
  /// **'استعادة'**
  String get myDataImportConfirm;

  /// The picked file is not a usable backup.
  ///
  /// In ar, this message translates to:
  /// **'هذا الملف ليس نسخة من بيانات سكينة، أو أنه من إصدار أحدث.'**
  String get myDataInvalidFile;

  /// Erases user data.
  ///
  /// In ar, this message translates to:
  /// **'مسح كل بياناتي'**
  String get myDataReset;

  /// What erase does.
  ///
  /// In ar, this message translates to:
  /// **'يعيد الإعدادات والختمة والمحفوظات والملاحظات إلى البداية'**
  String get myDataResetSubtitle;

  /// Erase confirmation title.
  ///
  /// In ar, this message translates to:
  /// **'مسح كل بياناتك؟'**
  String get myDataResetTitle;

  /// Explains erase is permanent.
  ///
  /// In ar, this message translates to:
  /// **'ستُحذف إعداداتك وموقع الصلاة والختمة والعلامة والمحفوظات والملاحظات من هذا الجهاز، ولا يمكن التراجع إلا من نسخة محفوظة. احفظ نسخة أولًا إن أردت.'**
  String get myDataResetBody;

  /// Confirms erase.
  ///
  /// In ar, this message translates to:
  /// **'مسح البيانات'**
  String get myDataResetConfirm;

  /// Export, import or erase failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت العملية، ولم يتغير شيء.'**
  String get myDataFailed;

  /// Title of the complete Hisn al-Muslim collection.
  ///
  /// In ar, this message translates to:
  /// **'حصن المسلم'**
  String get hisnTitle;

  /// Subtitle of the Hisn al-Muslim entry on the adhkar screen.
  ///
  /// In ar, this message translates to:
  /// **'الكتاب كاملًا: كل الأبواب والأذكار'**
  String get hisnEntrySubtitle;

  /// Search field over chapter titles.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الأبواب'**
  String get hisnSearch;

  /// Number of entries in a chapter.
  ///
  /// In ar, this message translates to:
  /// **'{count} ذكر'**
  String hisnEntryCount(String count);

  /// Times said so far of the times to say.
  ///
  /// In ar, this message translates to:
  /// **'{done} من {total}'**
  String hisnProgress(String done, String total);

  /// All repetitions done.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get hisnDone;

  /// The bundled collection could not be read.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح حصن المسلم.'**
  String get hisnLoadFailed;

  /// Source line of Hisn al-Muslim.
  ///
  /// In ar, this message translates to:
  /// **'المصدر: حصن المسلم لسعيد بن علي بن وهف القحطاني، النص العربي من hisnmuslim.com دون تعديل. النص بانتظار مراجعة المالك قبل النشر.'**
  String get hisnSource;

  /// Label of the morning/evening reminder timing choice.
  ///
  /// In ar, this message translates to:
  /// **'وقت التذكير'**
  String get anchoredReminderLabel;

  /// Reminder rings at the chosen clock time.
  ///
  /// In ar, this message translates to:
  /// **'ساعة ثابتة (كما اخترتها أعلاه)'**
  String get anchoredClockTime;

  /// Reminder at the prayer time.
  ///
  /// In ar, this message translates to:
  /// **'عند أذان {prayer}'**
  String anchoredAtPrayer(String prayer);

  /// Reminder some minutes after the prayer.
  ///
  /// In ar, this message translates to:
  /// **'بعد {prayer} بـ {minutes} دقيقة'**
  String anchoredAfterPrayer(String minutes, String prayer);

  /// Title of the home card that follows the time of day.
  ///
  /// In ar, this message translates to:
  /// **'في هذا الوقت'**
  String get nowCardTitle;

  /// Suggestion: morning adhkar.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الصباح'**
  String get nowMorningAdhkar;

  /// Suggestion: evening adhkar.
  ///
  /// In ar, this message translates to:
  /// **'أذكار المساء'**
  String get nowEveningAdhkar;

  /// Suggestion: adhkar before sleep.
  ///
  /// In ar, this message translates to:
  /// **'أذكار النوم'**
  String get nowSleepAdhkar;

  /// Suggestion: Surat al-Mulk at night.
  ///
  /// In ar, this message translates to:
  /// **'سورة الملك'**
  String get nowSurahMulk;

  /// Suggestion: Surat al-Kahf on Friday.
  ///
  /// In ar, this message translates to:
  /// **'سورة الكهف يوم الجمعة'**
  String get nowSurahKahf;

  /// Hijri calendar screen title.
  ///
  /// In ar, this message translates to:
  /// **'التقويم الهجري'**
  String get calendarTitle;

  /// Hijri month and year heading.
  ///
  /// In ar, this message translates to:
  /// **'{month} {year}هـ'**
  String calendarMonthTitle(String month, String year);

  /// Previous Hijri month.
  ///
  /// In ar, this message translates to:
  /// **'الشهر السابق'**
  String get calendarPrevious;

  /// Next Hijri month.
  ///
  /// In ar, this message translates to:
  /// **'الشهر التالي'**
  String get calendarNext;

  /// Back to the current Hijri month.
  ///
  /// In ar, this message translates to:
  /// **'العودة إلى الشهر الحالي'**
  String get calendarToday;

  /// Heading of upcoming occasions.
  ///
  /// In ar, this message translates to:
  /// **'المناسبات القادمة'**
  String get calendarUpcoming;

  /// The occasion is happening now.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get calendarNow;

  /// Days until an occasion.
  ///
  /// In ar, this message translates to:
  /// **'بعد {days} يوم'**
  String calendarInDays(String days);

  /// Date outside the Umm al-Qura table.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ الهجري غير متاح لهذا اليوم.'**
  String get calendarUnavailable;

  /// How the calendar is computed and why it may differ.
  ///
  /// In ar, this message translates to:
  /// **'التقويم بحساب أم القرى مع تعديلك للتاريخ الهجري من الإعدادات، وقد تختلف بداية الأشهر في بلدك بحسب رؤية الهلال.'**
  String get calendarNote;

  /// Screen-reader hint: tapping the date opens the calendar.
  ///
  /// In ar, this message translates to:
  /// **'فتح التقويم الهجري'**
  String get calendarOpen;

  /// Day of Ramadan.
  ///
  /// In ar, this message translates to:
  /// **'رمضان: اليوم {day}'**
  String ramadanDay(String day);

  /// Imsak time label.
  ///
  /// In ar, this message translates to:
  /// **'الإمساك'**
  String get ramadanImsak;

  /// Iftar (Maghrib) time label.
  ///
  /// In ar, this message translates to:
  /// **'الإفطار'**
  String get ramadanIftar;

  /// Countdown to Imsak or Iftar.
  ///
  /// In ar, this message translates to:
  /// **'يبقى على {event} {hours} س {minutes} د'**
  String ramadanCountdown(String event, String hours, String minutes);

  /// Explains Imsak is a precaution before Fajr.
  ///
  /// In ar, this message translates to:
  /// **'الإمساك قبل الفجر بعشر دقائق احتياطًا، والصيام يبدأ من أذان الفجر.'**
  String get ramadanImsakNote;

  /// Button on an adhan notification that stops the sound
  ///
  /// In ar, this message translates to:
  /// **'إيقاف الأذان'**
  String get notificationActionStopAdhan;

  /// No description provided for @afterAdhanQuietTitle.
  ///
  /// In ar, this message translates to:
  /// **'صمت الهاتف بعد الأذان'**
  String get afterAdhanQuietTitle;

  /// No description provided for @afterAdhanQuietHelp.
  ///
  /// In ar, this message translates to:
  /// **'يُشغَّل وضع «عدم الإزعاج» بعد وقت الصلاة بخمس دقائق، ثم يعود الهاتف كما كان. لا يغيّر شيئًا إن كان الوضع مشغّلًا من قبل.'**
  String get afterAdhanQuietHelp;

  /// No description provided for @afterAdhanQuietOff.
  ///
  /// In ar, this message translates to:
  /// **'لا'**
  String get afterAdhanQuietOff;

  /// No description provided for @afterAdhanQuietMinutes.
  ///
  /// In ar, this message translates to:
  /// **'{minutes} دقيقة'**
  String afterAdhanQuietMinutes(String minutes);

  /// No description provided for @afterAdhanQuietNeedsAccess.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج صمت الهاتف إلى إذن «عدم الإزعاج» من إعدادات النظام.'**
  String get afterAdhanQuietNeedsAccess;

  /// No description provided for @afterAdhanGrant.
  ///
  /// In ar, this message translates to:
  /// **'السماح'**
  String get afterAdhanGrant;

  /// No description provided for @fajrWakeSettingTitle.
  ///
  /// In ar, this message translates to:
  /// **'منبّه الفجر'**
  String get fajrWakeSettingTitle;

  /// No description provided for @fajrWakeSettingHelp.
  ///
  /// In ar, this message translates to:
  /// **'يرنّ على الشاشة كلها بصوت يبدأ خافتًا ثم يرتفع، ويحلّ محلّ إشعار الفجر. التأجيل متاح ما دام الشروق بعيدًا.'**
  String get fajrWakeSettingHelp;

  /// No description provided for @fajrWakeNeedsFullScreen.
  ///
  /// In ar, this message translates to:
  /// **'اسمح لسكينة بعرض المنبّه على الشاشة كاملة حتى يظهر فوق شاشة القفل.'**
  String get fajrWakeNeedsFullScreen;

  /// No description provided for @fajrWakeSnoozeTitle.
  ///
  /// In ar, this message translates to:
  /// **'مدة التأجيل'**
  String get fajrWakeSnoozeTitle;

  /// No description provided for @fajrWakeSnooze.
  ///
  /// In ar, this message translates to:
  /// **'تأجيل {minutes} دقائق'**
  String fajrWakeSnooze(String minutes);

  /// No description provided for @fajrWakeTitle.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت صلاة الفجر'**
  String get fajrWakeTitle;

  /// No description provided for @fajrWakeBody.
  ///
  /// In ar, this message translates to:
  /// **'قم للصلاة قبل شروق الشمس'**
  String get fajrWakeBody;

  /// No description provided for @fajrWakeStop.
  ///
  /// In ar, this message translates to:
  /// **'أوقف المنبّه'**
  String get fajrWakeStop;

  /// %s is replaced natively with the minutes left; keep it
  ///
  /// In ar, this message translates to:
  /// **'باقٍ على الشروق %s دقيقة'**
  String get fajrWakeUntilSunrise;

  /// No description provided for @fajrWakeSunriseReached.
  ///
  /// In ar, this message translates to:
  /// **'أشرقت الشمس'**
  String get fajrWakeSunriseReached;

  /// No description provided for @fajrWakeChannel.
  ///
  /// In ar, this message translates to:
  /// **'منبّه الفجر'**
  String get fajrWakeChannel;

  /// No description provided for @practiceLogTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجلّ العبادة'**
  String get practiceLogTitle;

  /// No description provided for @practiceLogOpen.
  ///
  /// In ar, this message translates to:
  /// **'سجلّ الصلاة والصيام'**
  String get practiceLogOpen;

  /// No description provided for @practiceLogPrivacy.
  ///
  /// In ar, this message translates to:
  /// **'هذا السجلّ لك وحدك: يبقى على هاتفك ولا يُرسَل إلى أي مكان، ولا يدخل في ملف التصدير إلا إن صدّرت بياناتك.'**
  String get practiceLogPrivacy;

  /// No description provided for @practiceLogPreviousDay.
  ///
  /// In ar, this message translates to:
  /// **'اليوم السابق'**
  String get practiceLogPreviousDay;

  /// No description provided for @practiceLogNextDay.
  ///
  /// In ar, this message translates to:
  /// **'اليوم التالي'**
  String get practiceLogNextDay;

  /// No description provided for @practiceLogToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get practiceLogToday;

  /// No description provided for @prayerLogOnTime.
  ///
  /// In ar, this message translates to:
  /// **'في وقتها'**
  String get prayerLogOnTime;

  /// No description provided for @prayerLogLate.
  ///
  /// In ar, this message translates to:
  /// **'متأخرة'**
  String get prayerLogLate;

  /// No description provided for @prayerLogMissed.
  ///
  /// In ar, this message translates to:
  /// **'فاتتني'**
  String get prayerLogMissed;

  /// No description provided for @prayerLogExcused.
  ///
  /// In ar, this message translates to:
  /// **'بعذر'**
  String get prayerLogExcused;

  /// No description provided for @prayerLogNotLogged.
  ///
  /// In ar, this message translates to:
  /// **'لم تُسجَّل'**
  String get prayerLogNotLogged;

  /// No description provided for @prayerLogClear.
  ///
  /// In ar, this message translates to:
  /// **'مسح التسجيل'**
  String get prayerLogClear;

  /// No description provided for @practiceExcusedTitle.
  ///
  /// In ar, this message translates to:
  /// **'وضع العذر'**
  String get practiceExcusedTitle;

  /// No description provided for @practiceExcusedHelp.
  ///
  /// In ar, this message translates to:
  /// **'للأيام التي لا تجب فيها الصلاة. ما تسجّله فيها بعذر لا يُعدّ فائتًا.'**
  String get practiceExcusedHelp;

  /// No description provided for @practiceMarkDayExcused.
  ///
  /// In ar, this message translates to:
  /// **'علّم صلوات هذا اليوم بعذر'**
  String get practiceMarkDayExcused;

  /// No description provided for @practiceWeekTitle.
  ///
  /// In ar, this message translates to:
  /// **'آخر سبعة أيام'**
  String get practiceWeekTitle;

  /// No description provided for @practiceWeekSummary.
  ///
  /// In ar, this message translates to:
  /// **'{onTime} في وقتها، {late} متأخرة، {missed} فاتت، {excused} بعذر'**
  String practiceWeekSummary(
    String onTime,
    String late,
    String missed,
    String excused,
  );

  /// No description provided for @practiceDaySemantics.
  ///
  /// In ar, this message translates to:
  /// **'{day}: {summary}'**
  String practiceDaySemantics(String day, String summary);

  /// No description provided for @fastingTitle.
  ///
  /// In ar, this message translates to:
  /// **'الصيام'**
  String get fastingTitle;

  /// No description provided for @fastFasted.
  ///
  /// In ar, this message translates to:
  /// **'صُمت'**
  String get fastFasted;

  /// No description provided for @fastQada.
  ///
  /// In ar, this message translates to:
  /// **'قضاء'**
  String get fastQada;

  /// No description provided for @fastExcused.
  ///
  /// In ar, this message translates to:
  /// **'بعذر'**
  String get fastExcused;

  /// No description provided for @fastMissed.
  ///
  /// In ar, this message translates to:
  /// **'لم أصم'**
  String get fastMissed;

  /// No description provided for @qadaLeftTitle.
  ///
  /// In ar, this message translates to:
  /// **'أيام القضاء الباقية: {count}'**
  String qadaLeftTitle(String count);

  /// No description provided for @qadaHelp.
  ///
  /// In ar, this message translates to:
  /// **'تُضاف أيام رمضان التي سجّلتها بعذر أو بلا صيام، وينقص منها كل يوم قضاء تسجّله.'**
  String get qadaHelp;

  /// No description provided for @qadaBaseLabel.
  ///
  /// In ar, this message translates to:
  /// **'أيام عليّ من قبل: {count}'**
  String qadaBaseLabel(String count);

  /// No description provided for @qadaBaseIncrease.
  ///
  /// In ar, this message translates to:
  /// **'زيادة يوم'**
  String get qadaBaseIncrease;

  /// No description provided for @qadaBaseDecrease.
  ///
  /// In ar, this message translates to:
  /// **'إنقاص يوم'**
  String get qadaBaseDecrease;

  /// No description provided for @wirdPortionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'وزّع وردي على الصلوات'**
  String get wirdPortionsTitle;

  /// No description provided for @wirdPortionsHelp.
  ///
  /// In ar, this message translates to:
  /// **'يُقسَم ورد اليوم على الصلوات الخمس، مع تذكير هادئ بعد كل صلاة بعشرين دقيقة.'**
  String get wirdPortionsHelp;

  /// No description provided for @wirdPortionLine.
  ///
  /// In ar, this message translates to:
  /// **'بعد {prayer}: {range}'**
  String wirdPortionLine(String prayer, String range);

  /// No description provided for @wirdPortionPages.
  ///
  /// In ar, this message translates to:
  /// **'الصفحات {from}–{to}'**
  String wirdPortionPages(String from, String to);

  /// No description provided for @wirdPortionPage.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة {page}'**
  String wirdPortionPage(String page);

  /// No description provided for @wirdPortionNotificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'وردك بعد صلاة {prayer}'**
  String wirdPortionNotificationTitle(String prayer);

  /// No description provided for @wirdPortionNotificationBody.
  ///
  /// In ar, this message translates to:
  /// **'{pages} من المصحف'**
  String wirdPortionNotificationBody(String pages);

  /// No description provided for @iqamaTitle.
  ///
  /// In ar, this message translates to:
  /// **'أوقات الإقامة في مسجدي'**
  String get iqamaTitle;

  /// No description provided for @iqamaSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'كم دقيقة بعد الأذان تُقام كل صلاة؟ تظهر الإقامة تحت وقت الصلاة.'**
  String get iqamaSubtitle;

  /// No description provided for @iqamaPrivacy.
  ///
  /// In ar, this message translates to:
  /// **'تُحفظ هذه الأوقات على هاتفك فقط، ولا يُرسَل موقعك ولا مسجدك إلى أي مكان.'**
  String get iqamaPrivacy;

  /// No description provided for @iqamaNone.
  ///
  /// In ar, this message translates to:
  /// **'لم تُحدَّد'**
  String get iqamaNone;

  /// No description provided for @iqamaAfterMinutes.
  ///
  /// In ar, this message translates to:
  /// **'بعد الأذان بـ{minutes} دقيقة'**
  String iqamaAfterMinutes(String minutes);

  /// No description provided for @iqamaAlertTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه قبل الإقامة'**
  String get iqamaAlertTitle;

  /// No description provided for @iqamaAlertOff.
  ///
  /// In ar, this message translates to:
  /// **'بلا تنبيه'**
  String get iqamaAlertOff;

  /// No description provided for @iqamaAlertMinutes.
  ///
  /// In ar, this message translates to:
  /// **'قبلها بـ{minutes} دقائق'**
  String iqamaAlertMinutes(String minutes);

  /// No description provided for @iqamaLine.
  ///
  /// In ar, this message translates to:
  /// **'الإقامة {time}'**
  String iqamaLine(String time);

  /// No description provided for @iqamaNotificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإقامة بعد {minutes} دقائق'**
  String iqamaNotificationTitle(String minutes);

  /// No description provided for @iqamaNotificationBody.
  ///
  /// In ar, this message translates to:
  /// **'صلاة {prayer} في مسجدك الساعة {time}'**
  String iqamaNotificationBody(String prayer, String time);

  /// No description provided for @hifzTitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الحفظ'**
  String get hifzTitle;

  /// No description provided for @hifzSummary.
  ///
  /// In ar, this message translates to:
  /// **'حفظتَ {pages} صفحة، وللمراجعة اليوم {due}'**
  String hifzSummary(String pages, String due);

  /// No description provided for @hifzExplain.
  ///
  /// In ar, this message translates to:
  /// **'تُراجَع كل صفحة بعد يوم، ثم ثلاثة أيام، ثم أسبوع، ثم أسبوعين، ثم شهر. وإن تعثّرت فيها عادت إلى البداية.'**
  String get hifzExplain;

  /// No description provided for @hifzEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم تُضِف صفحات بعد. أضف ما تحفظه لتظهر مراجعته هنا.'**
  String get hifzEmpty;

  /// No description provided for @hifzAdd.
  ///
  /// In ar, this message translates to:
  /// **'أضف صفحات حفظتها'**
  String get hifzAdd;

  /// No description provided for @hifzAddFrom.
  ///
  /// In ar, this message translates to:
  /// **'من الصفحة'**
  String get hifzAddFrom;

  /// No description provided for @hifzAddTo.
  ///
  /// In ar, this message translates to:
  /// **'إلى الصفحة (اختياري)'**
  String get hifzAddTo;

  /// No description provided for @hifzAddInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل صفحات بين ١ و٦٠٤'**
  String get hifzAddInvalid;

  /// No description provided for @hifzAddConfirm.
  ///
  /// In ar, this message translates to:
  /// **'أضف'**
  String get hifzAddConfirm;

  /// No description provided for @hifzDueTitle.
  ///
  /// In ar, this message translates to:
  /// **'للمراجعة اليوم'**
  String get hifzDueTitle;

  /// No description provided for @hifzNothingDue.
  ///
  /// In ar, this message translates to:
  /// **'لا مراجعة اليوم.'**
  String get hifzNothingDue;

  /// No description provided for @hifzAllTitle.
  ///
  /// In ar, this message translates to:
  /// **'كل ما حفظت'**
  String get hifzAllTitle;

  /// No description provided for @hifzPageLine.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة {page} · {surah}'**
  String hifzPageLine(String page, String surah);

  /// No description provided for @hifzNextReview.
  ///
  /// In ar, this message translates to:
  /// **'المراجعة القادمة {date}'**
  String hifzNextReview(String date);

  /// No description provided for @hifzRemove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة من المحفوظ'**
  String get hifzRemove;

  /// No description provided for @hifzReviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الصفحة {page}'**
  String hifzReviewTitle(String page);

  /// No description provided for @hifzRevealAyah.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لإظهار الآية {number}'**
  String hifzRevealAyah(String number);

  /// No description provided for @hifzRevealAll.
  ///
  /// In ar, this message translates to:
  /// **'أظهر الصفحة كلها'**
  String get hifzRevealAll;

  /// No description provided for @hifzRemembered.
  ///
  /// In ar, this message translates to:
  /// **'تذكّرتها'**
  String get hifzRemembered;

  /// No description provided for @hifzStumbled.
  ///
  /// In ar, this message translates to:
  /// **'تعثّرت'**
  String get hifzStumbled;

  /// No description provided for @hifzOpenInMushaf.
  ///
  /// In ar, this message translates to:
  /// **'افتح في المصحف'**
  String get hifzOpenInMushaf;

  /// No description provided for @recitationListeningTitle.
  ///
  /// In ar, this message translates to:
  /// **'خيارات الاستماع'**
  String get recitationListeningTitle;

  /// No description provided for @recitationAutoNext.
  ///
  /// In ar, this message translates to:
  /// **'انتقل إلى السورة التالية تلقائيًا'**
  String get recitationAutoNext;

  /// No description provided for @recitationAyahRepeat.
  ///
  /// In ar, this message translates to:
  /// **'كرّر كل آية'**
  String get recitationAyahRepeat;

  /// No description provided for @recitationAyahRepeatOnce.
  ///
  /// In ar, this message translates to:
  /// **'مرة واحدة'**
  String get recitationAyahRepeatOnce;

  /// No description provided for @recitationAyahRepeatTimes.
  ///
  /// In ar, this message translates to:
  /// **'{times} مرات'**
  String recitationAyahRepeatTimes(String times);

  /// No description provided for @recitationSleepTitle.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف بعد'**
  String get recitationSleepTitle;

  /// No description provided for @recitationSleepMinutes.
  ///
  /// In ar, this message translates to:
  /// **'{minutes} دقيقة'**
  String recitationSleepMinutes(String minutes);

  /// No description provided for @recitationSleepSurahEnd.
  ///
  /// In ar, this message translates to:
  /// **'نهاية السورة'**
  String get recitationSleepSurahEnd;

  /// No description provided for @recitationSleepAt.
  ///
  /// In ar, this message translates to:
  /// **'يتوقف الساعة {time}'**
  String recitationSleepAt(String time);

  /// No description provided for @recitationSleepAtSurahEnd.
  ///
  /// In ar, this message translates to:
  /// **'يتوقف عند نهاية السورة'**
  String get recitationSleepAtSurahEnd;

  /// No description provided for @recitationSleepCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء المؤقت'**
  String get recitationSleepCancel;

  /// No description provided for @listenModeTitle.
  ///
  /// In ar, this message translates to:
  /// **'وضع الاستماع الميسّر'**
  String get listenModeTitle;

  /// No description provided for @listenModeHelp.
  ///
  /// In ar, this message translates to:
  /// **'اسحب يمينًا أو يسارًا للآية التالية أو السابقة. مع قارئ الشاشة: اسحب لأعلى أو لأسفل على منطقة الآية.'**
  String get listenModeHelp;

  /// No description provided for @listenModeChooseSurah.
  ///
  /// In ar, this message translates to:
  /// **'اختر السورة'**
  String get listenModeChooseSurah;

  /// No description provided for @listenModeNowPlaying.
  ///
  /// In ar, this message translates to:
  /// **'{surah}، الآية {ayah}'**
  String listenModeNowPlaying(String surah, String ayah);

  /// No description provided for @listenModeNothing.
  ///
  /// In ar, this message translates to:
  /// **'لم يبدأ الاستماع بعد'**
  String get listenModeNothing;

  /// No description provided for @listenModePrevious.
  ///
  /// In ar, this message translates to:
  /// **'الآية السابقة'**
  String get listenModePrevious;

  /// No description provided for @listenModeNext.
  ///
  /// In ar, this message translates to:
  /// **'الآية التالية'**
  String get listenModeNext;

  /// No description provided for @listenModePlay.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get listenModePlay;

  /// No description provided for @listenModePause.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get listenModePause;

  /// No description provided for @listenModeLoading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل…'**
  String get listenModeLoading;

  /// No description provided for @searchGoToVerse.
  ///
  /// In ar, this message translates to:
  /// **'انتقل إلى {surah}، الآية {ayah}'**
  String searchGoToVerse(String surah, String ayah);

  /// No description provided for @readerVerseShare.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get readerVerseShare;

  /// No description provided for @verseShareTitle.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الآية'**
  String get verseShareTitle;

  /// No description provided for @verseShareAsImage.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة كصورة'**
  String get verseShareAsImage;

  /// No description provided for @verseShareAsText.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة كنص'**
  String get verseShareAsText;

  /// No description provided for @verseShareShowAppName.
  ///
  /// In ar, this message translates to:
  /// **'إظهار اسم التطبيق على الصورة'**
  String get verseShareShowAppName;

  /// No description provided for @verseShareReference.
  ///
  /// In ar, this message translates to:
  /// **'{surah} · الآية {ayah}'**
  String verseShareReference(String surah, String ayah);

  /// No description provided for @verseShareFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت المشاركة. حاول مرة أخرى.'**
  String get verseShareFailed;

  /// No description provided for @hadithGrade.
  ///
  /// In ar, this message translates to:
  /// **'درجة الحديث'**
  String get hadithGrade;

  /// No description provided for @hadithAttribution.
  ///
  /// In ar, this message translates to:
  /// **'مَن رواه'**
  String get hadithAttribution;

  /// No description provided for @hadithExplanation.
  ///
  /// In ar, this message translates to:
  /// **'الشرح'**
  String get hadithExplanation;

  /// No description provided for @hadithLessons.
  ///
  /// In ar, this message translates to:
  /// **'من فوائد الحديث'**
  String get hadithLessons;

  /// No description provided for @hadithReferences.
  ///
  /// In ar, this message translates to:
  /// **'المراجع'**
  String get hadithReferences;

  /// No description provided for @hadithSourceTitle.
  ///
  /// In ar, this message translates to:
  /// **'المصدر'**
  String get hadithSourceTitle;

  /// No description provided for @hadithSource.
  ///
  /// In ar, this message translates to:
  /// **'نص الأحاديث وتخريجها ودرجتها وشرحها وفوائدها من «موسوعة الأحاديث النبوية» ‏(hadeethenc.com)، منقولة كما نُشرت.'**
  String get hadithSource;

  /// No description provided for @hadithSearch.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الأحاديث وشروحها'**
  String get hadithSearch;

  /// No description provided for @calmMinuteShow.
  ///
  /// In ar, this message translates to:
  /// **'معنى الآية في دقيقة'**
  String get calmMinuteShow;

  /// No description provided for @calmMinuteHide.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء المعنى'**
  String get calmMinuteHide;

  /// No description provided for @travelNoticeTitle.
  ///
  /// In ar, this message translates to:
  /// **'أنت الآن في {place}'**
  String travelNoticeTitle(String place);

  /// No description provided for @travelNoticeBody.
  ///
  /// In ar, this message translates to:
  /// **'حُدّثت مواقيت الصلاة وتنبيهاتها للمكان الجديد.'**
  String get travelNoticeBody;

  /// No description provided for @travelNoticeDismiss.
  ///
  /// In ar, this message translates to:
  /// **'حسنًا'**
  String get travelNoticeDismiss;

  /// No description provided for @simpleModeTitle.
  ///
  /// In ar, this message translates to:
  /// **'الوضع المبسّط'**
  String get simpleModeTitle;

  /// No description provided for @simpleModeHelp.
  ///
  /// In ar, this message translates to:
  /// **'شاشة رئيسية بأربع خانات كبيرة: القرآن والمواقيت والأذكار والقبلة، مع خط أكبر.'**
  String get simpleModeHelp;

  /// No description provided for @simpleHomeQuran.
  ///
  /// In ar, this message translates to:
  /// **'القرآن'**
  String get simpleHomeQuran;

  /// No description provided for @simpleHomePrayers.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة'**
  String get simpleHomePrayers;

  /// No description provided for @simpleHomeAdhkar.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get simpleHomeAdhkar;

  /// No description provided for @simpleHomeQibla.
  ///
  /// In ar, this message translates to:
  /// **'القبلة'**
  String get simpleHomeQibla;

  /// No description provided for @myDataPassphraseTitle.
  ///
  /// In ar, this message translates to:
  /// **'حماية النسخة بكلمة مرور'**
  String get myDataPassphraseTitle;

  /// No description provided for @myDataPassphraseHelp.
  ///
  /// In ar, this message translates to:
  /// **'تحوي النسخة سجلّ عبادتك وملاحظاتك. بكلمة مرور تُشفَّر فلا يقرؤها غيرك ولو حفظتها في خدمة سحابية. إن نسيت كلمة المرور فلا سبيل لفتح الملف.'**
  String get myDataPassphraseHelp;

  /// No description provided for @myDataPassphrase.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get myDataPassphrase;

  /// No description provided for @myDataPassphraseRepeat.
  ///
  /// In ar, this message translates to:
  /// **'أعد كتابة كلمة المرور'**
  String get myDataPassphraseRepeat;

  /// No description provided for @myDataPassphraseTooShort.
  ///
  /// In ar, this message translates to:
  /// **'ثمانية أحرف على الأقل'**
  String get myDataPassphraseTooShort;

  /// No description provided for @myDataPassphraseMismatch.
  ///
  /// In ar, this message translates to:
  /// **'الكلمتان غير متطابقتين'**
  String get myDataPassphraseMismatch;

  /// No description provided for @myDataWithoutPassphrase.
  ///
  /// In ar, this message translates to:
  /// **'بدون كلمة مرور'**
  String get myDataWithoutPassphrase;

  /// No description provided for @myDataEncryptAndSave.
  ///
  /// In ar, this message translates to:
  /// **'تشفير وحفظ'**
  String get myDataEncryptAndSave;

  /// No description provided for @myDataUnlockTitle.
  ///
  /// In ar, this message translates to:
  /// **'هذه النسخة محمية بكلمة مرور'**
  String get myDataUnlockTitle;

  /// No description provided for @myDataUnlock.
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get myDataUnlock;

  /// No description provided for @myDataWrongPassphrase.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور غير صحيحة، أو أن الملف تغيّر.'**
  String get myDataWrongPassphrase;

  /// No description provided for @myDataWorking.
  ///
  /// In ar, this message translates to:
  /// **'لحظة…'**
  String get myDataWorking;

  /// No description provided for @unifiedSearchTitle.
  ///
  /// In ar, this message translates to:
  /// **'البحث في سكينة'**
  String get unifiedSearchTitle;

  /// No description provided for @unifiedSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في القرآن والأذكار والأحاديث والدليل'**
  String get unifiedSearchHint;

  /// No description provided for @unifiedSearchIntro.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كلمة أو أكثر. يجري البحث في النصوص المضمّنة في التطبيق فقط، دون إنترنت.'**
  String get unifiedSearchIntro;

  /// No description provided for @unifiedSearchQuran.
  ///
  /// In ar, this message translates to:
  /// **'القرآن الكريم'**
  String get unifiedSearchQuran;

  /// No description provided for @unifiedSearchHisn.
  ///
  /// In ar, this message translates to:
  /// **'حصن المسلم'**
  String get unifiedSearchHisn;

  /// No description provided for @unifiedSearchHadith.
  ///
  /// In ar, this message translates to:
  /// **'الأحاديث'**
  String get unifiedSearchHadith;

  /// No description provided for @unifiedSearchGuide.
  ///
  /// In ar, this message translates to:
  /// **'الدليل'**
  String get unifiedSearchGuide;

  /// No description provided for @unifiedSearchGroup.
  ///
  /// In ar, this message translates to:
  /// **'{source} ({count})'**
  String unifiedSearchGroup(String source, String count);

  /// No description provided for @unifiedSearchShowAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض كل النتائج'**
  String get unifiedSearchShowAll;

  /// No description provided for @unifiedSearchFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل النصوص للبحث. أعد فتح الشاشة.'**
  String get unifiedSearchFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
