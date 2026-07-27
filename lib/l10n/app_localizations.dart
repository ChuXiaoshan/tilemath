import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('zh'),
  ];

  /// Brand name, not localized (2026-07-24 user decision)
  ///
  /// In en, this message translates to:
  /// **'TileMath'**
  String get appTitle;

  /// Section kicker above the room/area inputs
  ///
  /// In en, this message translates to:
  /// **'Areas'**
  String get sectionAreas;

  /// Section kicker above tile size and grout inputs
  ///
  /// In en, this message translates to:
  /// **'Tile'**
  String get sectionTile;

  /// Section kicker above the result card
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get sectionResults;

  /// Row label for one measured area
  ///
  /// In en, this message translates to:
  /// **'Area {number}'**
  String areaLabel(int number);

  /// No description provided for @length.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get length;

  /// No description provided for @width.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get width;

  /// No description provided for @tileWidth.
  ///
  /// In en, this message translates to:
  /// **'Tile width'**
  String get tileWidth;

  /// No description provided for @tileHeight.
  ///
  /// In en, this message translates to:
  /// **'Tile height'**
  String get tileHeight;

  /// No description provided for @groutWidth.
  ///
  /// In en, this message translates to:
  /// **'Grout gap'**
  String get groutWidth;

  /// No description provided for @wastePercent.
  ///
  /// In en, this message translates to:
  /// **'Waste'**
  String get wastePercent;

  /// Text button that appends a new area row
  ///
  /// In en, this message translates to:
  /// **'Add area'**
  String get addArea;

  /// Tag for a negative (excluded) area, e.g. bathtub footprint
  ///
  /// In en, this message translates to:
  /// **'Cutout'**
  String get cutout;

  /// Caption under the big result figure
  ///
  /// In en, this message translates to:
  /// **'tiles needed'**
  String get tilesNeededLabel;

  /// No description provided for @tilesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} tile} other{{count} tiles}}'**
  String tilesCount(int count);

  /// No description provided for @boxesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} box} other{{count} boxes}}'**
  String boxesCount(int count);

  /// No description provided for @totalArea.
  ///
  /// In en, this message translates to:
  /// **'Total area'**
  String get totalArea;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @unitImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get unitImperial;

  /// No description provided for @unitMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get unitMetric;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @keyNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get keyNext;

  /// No description provided for @keyDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get keyDone;

  /// No description provided for @keyClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get keyClear;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// Text button that appends a negative (excluded) area row
  ///
  /// In en, this message translates to:
  /// **'Add cutout'**
  String get addCutout;

  /// No description provided for @layoutPattern.
  ///
  /// In en, this message translates to:
  /// **'Layout pattern'**
  String get layoutPattern;

  /// No description provided for @patternStraight.
  ///
  /// In en, this message translates to:
  /// **'Straight'**
  String get patternStraight;

  /// No description provided for @patternDiagonal.
  ///
  /// In en, this message translates to:
  /// **'Diagonal'**
  String get patternDiagonal;

  /// No description provided for @patternHerringbone.
  ///
  /// In en, this message translates to:
  /// **'Herringbone'**
  String get patternHerringbone;

  /// No description provided for @patternCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get patternCustom;

  /// No description provided for @boxesAndCost.
  ///
  /// In en, this message translates to:
  /// **'Boxes & cost'**
  String get boxesAndCost;

  /// No description provided for @tilesPerBox.
  ///
  /// In en, this message translates to:
  /// **'Tiles per box'**
  String get tilesPerBox;

  /// No description provided for @pricePerBox.
  ///
  /// In en, this message translates to:
  /// **'Price per box'**
  String get pricePerBox;

  /// No description provided for @boxesToBuy.
  ///
  /// In en, this message translates to:
  /// **'Boxes to buy'**
  String get boxesToBuy;

  /// No description provided for @estimatedCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated cost'**
  String get estimatedCost;

  /// Secondary line under the big tiles-needed figure
  ///
  /// In en, this message translates to:
  /// **'{base, plural, one{{base} tile + {waste}% waste} other{{base} tiles + {waste}% waste}}'**
  String wasteLine(int base, int waste);

  /// No description provided for @smallAreaHint.
  ///
  /// In en, this message translates to:
  /// **'Small areas produce more cut waste — consider +5%.'**
  String get smallAreaHint;

  /// No description provided for @resultEmptyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter dimensions to see results'**
  String get resultEmptyPrompt;

  /// Default entry in the language list: follow device language
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @currencySymbol.
  ///
  /// In en, this message translates to:
  /// **'Currency symbol'**
  String get currencySymbol;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate this app'**
  String get rateApp;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your calculations will appear here.'**
  String get historyEmpty;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} minute ago} other{{count} minutes ago}}'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @clearAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all history?'**
  String get clearAllConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @historyFooterNote.
  ///
  /// In en, this message translates to:
  /// **'Every calculation is saved — free, no limit.'**
  String get historyFooterNote;

  /// No description provided for @languagePageNote.
  ///
  /// In en, this message translates to:
  /// **'Overrides the OS language for this app only — for older devices without per-app language settings.'**
  String get languagePageNote;

  /// No description provided for @linkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link'**
  String get linkOpenFailed;

  /// No description provided for @wasteShort.
  ///
  /// In en, this message translates to:
  /// **'{pct}% waste'**
  String wasteShort(int pct);
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
      <String>['ar', 'en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
