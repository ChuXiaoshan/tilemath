// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TileMath';

  @override
  String get sectionAreas => 'Areas';

  @override
  String get sectionTile => 'Tile';

  @override
  String get sectionResults => 'Results';

  @override
  String areaLabel(int number) {
    return 'Area $number';
  }

  @override
  String get length => 'Length';

  @override
  String get width => 'Width';

  @override
  String get tileWidth => 'Tile width';

  @override
  String get tileHeight => 'Tile height';

  @override
  String get groutWidth => 'Grout gap';

  @override
  String get wastePercent => 'Waste';

  @override
  String get addArea => 'Add area';

  @override
  String get cutout => 'Cutout';

  @override
  String get tilesNeededLabel => 'tiles needed';

  @override
  String tilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tiles',
      one: '$count tile',
    );
    return '$_temp0';
  }

  @override
  String boxesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boxes',
      one: '$count box',
    );
    return '$_temp0';
  }

  @override
  String get totalArea => 'Total area';

  @override
  String get settings => 'Settings';

  @override
  String get units => 'Units';

  @override
  String get unitImperial => 'Imperial';

  @override
  String get unitMetric => 'Metric';

  @override
  String get language => 'Language';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get keyNext => 'Next';

  @override
  String get keyDone => 'Done';

  @override
  String get keyClear => 'Clear';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get addCutout => 'Add cutout';

  @override
  String get layoutPattern => 'Layout pattern';

  @override
  String get patternStraight => 'Straight';

  @override
  String get patternDiagonal => 'Diagonal';

  @override
  String get patternHerringbone => 'Herringbone';

  @override
  String get patternCustom => 'Custom';

  @override
  String get boxesAndCost => 'Boxes & cost';

  @override
  String get tilesPerBox => 'Tiles per box';

  @override
  String get pricePerBox => 'Price per box';

  @override
  String get boxesToBuy => 'Boxes to buy';

  @override
  String get estimatedCost => 'Estimated cost';

  @override
  String wasteLine(int base, int waste) {
    return '$base tiles + $waste% waste';
  }

  @override
  String get smallAreaHint =>
      'Small areas produce more cut waste — consider +5%.';

  @override
  String get resultEmptyPrompt => 'Enter dimensions to see results';

  @override
  String get languageSystem => 'System default';

  @override
  String get currencySymbol => 'Currency symbol';

  @override
  String get versionLabel => 'Version';

  @override
  String get rateApp => 'Rate this app';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'Your calculations will appear here.';

  @override
  String get delete => 'Delete';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '$count minute ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '$count hour ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '$count day ago',
    );
    return '$_temp0';
  }

  @override
  String get clearAll => 'Clear all';

  @override
  String get clearAllConfirm => 'Delete all history?';

  @override
  String get cancel => 'Cancel';

  @override
  String get historyFooterNote =>
      'Every calculation is saved — free, no limit.';

  @override
  String get languagePageNote =>
      'Overrides the OS language for this app only — for older devices without per-app language settings.';

  @override
  String wasteShort(int pct) {
    return '$pct% waste';
  }
}
