// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'TileMath';

  @override
  String get sectionAreas => 'المساحات';

  @override
  String get sectionTile => 'البلاطة';

  @override
  String get sectionResults => 'النتائج';

  @override
  String areaLabel(int number) {
    return 'مساحة $number';
  }

  @override
  String get length => 'الطول';

  @override
  String get width => 'العرض';

  @override
  String get tileWidth => 'عرض البلاطة';

  @override
  String get tileHeight => 'طول البلاطة';

  @override
  String get groutWidth => 'عرض الفاصل';

  @override
  String get wastePercent => 'الهدر';

  @override
  String get addArea => 'إضافة مساحة';

  @override
  String get cutout => 'اقتطاع';

  @override
  String tilesNeededLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'البلاط المطلوب',
    );
    return '$_temp0';
  }

  @override
  String tilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بلاطة',
      many: '$count بلاطة',
      few: '$count بلاطات',
      two: 'بلاطتان',
      one: 'بلاطة واحدة',
      zero: 'بدون بلاط',
    );
    return '$_temp0';
  }

  @override
  String boxesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صندوق',
      many: '$count صندوقًا',
      few: '$count صناديق',
      two: 'صندوقان',
      one: 'صندوق واحد',
      zero: 'بدون صناديق',
    );
    return '$_temp0';
  }

  @override
  String get totalArea => 'المساحة الإجمالية';

  @override
  String get settings => 'الإعدادات';

  @override
  String get units => 'الوحدات';

  @override
  String get unitImperial => 'إمبراطوري';

  @override
  String get unitMetric => 'متري';

  @override
  String get language => 'اللغة';

  @override
  String get themeMode => 'المظهر';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get keyNext => 'التالي';

  @override
  String get keyDone => 'تم';

  @override
  String get keyClear => 'مسح';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get addCutout => 'إضافة اقتطاع';

  @override
  String get layoutPattern => 'نمط التركيب';

  @override
  String get patternStraight => 'مستقيم';

  @override
  String get patternDiagonal => 'قطري';

  @override
  String get patternHerringbone => 'متعرج';

  @override
  String get patternCustom => 'مخصص';

  @override
  String get boxesAndCost => 'الصناديق والتكلفة';

  @override
  String get tilesPerBox => 'بلاطات لكل صندوق';

  @override
  String get pricePerBox => 'سعر الصندوق';

  @override
  String get boxesToBuy => 'الصناديق المطلوبة';

  @override
  String get estimatedCost => 'التكلفة التقديرية';

  @override
  String wasteLine(int base, int waste) {
    String _temp0 = intl.Intl.pluralLogic(
      base,
      locale: localeName,
      other: '$base بلاطة + هدر $waste%',
      many: '$base بلاطة + هدر $waste%',
      few: '$base بلاطات + هدر $waste%',
      two: 'بلاطتان + هدر $waste%',
      one: 'بلاطة واحدة + هدر $waste%',
      zero: 'هدر $waste%',
    );
    return '$_temp0';
  }

  @override
  String get smallAreaHint =>
      'المساحات الصغيرة تزيد هدر القص — يُنصح بإضافة 5%.';

  @override
  String get resultEmptyPrompt => 'أدخل المقاسات لعرض النتائج';

  @override
  String get languageSystem => 'لغة النظام';

  @override
  String get currencySymbol => 'رمز العملة';

  @override
  String get versionLabel => 'الإصدار';

  @override
  String get rateApp => 'قيّم التطبيق';

  @override
  String get historyTitle => 'السجل';

  @override
  String get historyEmpty => 'ستظهر حساباتك هنا.';

  @override
  String get delete => 'حذف';

  @override
  String get justNow => 'الآن';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count دقيقة',
      many: 'قبل $count دقيقة',
      few: 'قبل $count دقائق',
      two: 'قبل دقيقتين',
      one: 'قبل دقيقة',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count ساعة',
      many: 'قبل $count ساعة',
      few: 'قبل $count ساعات',
      two: 'قبل ساعتين',
      one: 'قبل ساعة',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count يوم',
      many: 'قبل $count يومًا',
      few: 'قبل $count أيام',
      two: 'قبل يومين',
      one: 'قبل يوم',
    );
    return '$_temp0';
  }

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get clearAllConfirm => 'هل تريد حذف كل السجل؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get historyFooterNote => 'يُحفظ كل حساب — مجانًا وبلا حدود.';

  @override
  String get languagePageNote =>
      'يغيّر لغة هذا التطبيق فقط — للأجهزة القديمة التي لا تدعم لغة لكل تطبيق.';

  @override
  String get linkOpenFailed => 'تعذّر فتح الرابط';

  @override
  String wasteShort(int pct) {
    return 'هدر $pct%';
  }

  @override
  String get sectionMaterials => 'مواد التركيب';

  @override
  String get materialsDefaults => 'قيم افتراضية مطبّقة';

  @override
  String get tileThickness => 'سماكة البلاطة';

  @override
  String get jointDepth => 'عمق الفاصل';

  @override
  String get jointDepthFollows => '= السماكة';

  @override
  String get trowelLabel => 'المالج';

  @override
  String get trowelAuto => 'تلقائي';

  @override
  String get trowelAutoCaption => 'يُختار حجم السن تلقائيًا حسب مقاس البلاطة.';

  @override
  String get groutNeeded => 'الروبة';

  @override
  String get thinsetNeeded => 'اللاصق';

  @override
  String thinsetBagsLine(int bags, String spec) {
    String _temp0 = intl.Intl.pluralLogic(
      bags,
      locale: localeName,
      other: '≈ $bags كيس · $spec',
      many: '≈ $bags كيسًا · $spec',
      few: '≈ $bags أكياس · $spec',
      two: '≈ كيسان · $spec',
      one: '≈ كيس واحد · $spec',
    );
    return '$_temp0';
  }

  @override
  String get materialsDisclaimer =>
      'الكميات تقديرية — اتبع جدول التغطية الخاص بمنتجك.';

  @override
  String get shareResult => 'مشاركة';

  @override
  String get shareFailed => 'تعذّرت المشاركة. حاول مرة أخرى.';

  @override
  String get shareCardFooter =>
      'TileMath — حاسبة بلاط بلوحة مفاتيح كسور البوصة';

  @override
  String previewCaption(String pattern, String grout) {
    return '$pattern · فاصل $grout';
  }
}
