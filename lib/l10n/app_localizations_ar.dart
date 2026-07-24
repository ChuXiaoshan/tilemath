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
  String get tilesNeededLabel => 'البلاط المطلوب';

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
  String get unitImperial => 'إمبراطوري (ft-in)';

  @override
  String get unitMetric => 'متري (m-cm)';

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
    return '$base بلاطة + $waste% هدر';
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
}
