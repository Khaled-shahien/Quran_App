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

  /// Display text used in lib/core/services/firebase_messaging_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'إشعار جديد'**
  String get firebaseMessagingServiceMessage1;

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
  /// **'إشعارات الاختبار'**
  String get notificationServiceMessage7;

  /// Display text used in lib/core/services/notification_service.dart.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات اختبار التطبيق'**
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
  /// **'تطبيق ختمة'**
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
  /// **'mailto:contact@quranapp.com?subject=تطبيق ختمة - تواصل'**
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
  /// **'تُرسل الإحداثيات إلى Aladhan لحساب المواقيت. أدخل موقعاً يدوياً أو استخدم موقع الجهاز.'**
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
  /// **'الحمدلله'**
  String get tasbeehScreenMessage2;

  /// Display text used in lib/features/quran/presentation/screens/tasbeeh_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'لا اله الا الله'**
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
  /// **'تُحفظ إحداثيات موقع الصلاة وطريقة الحساب على الجهاز، وتُرسل إلى خدمة Aladhan لجلب المواقيت. يمكنك تعديلها من شاشة الصلاة. تستخدم القبلة إذن الموقع لحساب الاتجاه. يمكن إلغاء الإذن من إعدادات الجهاز.'**
  String get dataSourcesScreenMessage2;

  /// Display text used in lib/features/settings/presentation/screens/data_sources_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'البيانات والتذكيرات'**
  String get dataSourcesScreenMessage3;

  /// Display text used in lib/features/settings/presentation/screens/data_sources_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تُحفظ المفضلة والعلامات والختمة والإعدادات محلياً. مسح بيانات التطبيق من إعدادات النظام يزيل البيانات المحلية. التذكيرات محلية ولا تحتاج خدمة رسائل عن بُعد. عند إتاحة تقارير الأعطال والاستخدام يمكنك اختيار تفعيلها أو إيقافها من الإعدادات؛ لا نضيف الموقع أو البحث أو سجل القراءة إلى هذه التقارير. قد تتلقى الخدمات الخارجية بيانات الاتصال. حذف البيانات المحلية لا يعني حذف سجلات الخدمات الخارجية أو النسخ الاحتياطية.'**
  String get dataSourcesScreenMessage4;

  /// Display text used in lib/features/settings/presentation/screens/data_sources_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'مصادر المحتوى'**
  String get dataSourcesScreenMessage5;

  /// Display text used in lib/features/settings/presentation/screens/data_sources_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'القرآن والأحاديث والأدعية متاحة ضمن ملفات التطبيق للعمل دون اتصال. توثيق الطبعة والمصدر والترخيص واعتماد المراجعة لكل مجموعة لم يكتمل بعد. بصمات سلامة الملفات تكشف التغييرات ولا تُعد توثيقاً شرعياً للمحتوى.'**
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
  /// **'الحالة'**
  String get notificationTestScreenMessage3;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'غير معروفة'**
  String get notificationTestScreenMessage4;

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
  /// **'إشعارات الدفع (FCM)'**
  String get notificationTestScreenMessage12;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'طلب الصلاحيات'**
  String get notificationTestScreenMessage13;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'رمز FCM:'**
  String get notificationTestScreenMessage14;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get notificationTestScreenMessage15;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get notificationTestScreenMessage16;

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
  /// **'تم تحديث الرمز'**
  String get notificationTestScreenMessage33;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الرمز'**
  String get notificationTestScreenMessage34;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'تم إعادة جدولة جميع المنبهات'**
  String get notificationTestScreenMessage35;

  /// Display text used in lib/features/settings/presentation/screens/notification_test_screen.dart.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح'**
  String get notificationTestScreenMessage36;

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
  /// **'إرسال تقارير الأعطال وبيانات الاستخدام'**
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

  /// Application title.
  ///
  /// In ar, this message translates to:
  /// **'Sakina'**
  String get applicationTitle;
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
