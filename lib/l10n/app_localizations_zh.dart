// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'TileMath';

  @override
  String get sectionAreas => '区域';

  @override
  String get sectionTile => '瓷砖';

  @override
  String get sectionResults => '结果';

  @override
  String areaLabel(int number) {
    return '区域 $number';
  }

  @override
  String get length => '长度';

  @override
  String get width => '宽度';

  @override
  String get tileWidth => '瓷砖宽';

  @override
  String get tileHeight => '瓷砖长';

  @override
  String get groutWidth => '留缝宽度';

  @override
  String get wastePercent => '损耗';

  @override
  String get addArea => '添加区域';

  @override
  String get cutout => '扣除区域';

  @override
  String tilesNeededLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '所需瓷砖',
    );
    return '$_temp0';
  }

  @override
  String tilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 块',
    );
    return '$_temp0';
  }

  @override
  String boxesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 箱',
    );
    return '$_temp0';
  }

  @override
  String get totalArea => '总面积';

  @override
  String get settings => '设置';

  @override
  String get units => '单位';

  @override
  String get unitImperial => '英制';

  @override
  String get unitMetric => '公制';

  @override
  String get language => '语言';

  @override
  String get themeMode => '外观';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get keyNext => '下一项';

  @override
  String get keyDone => '完成';

  @override
  String get keyClear => '清除';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get addCutout => '添加扣除区域';

  @override
  String get layoutPattern => '铺贴方式';

  @override
  String get patternStraight => '正铺';

  @override
  String get patternDiagonal => '斜铺';

  @override
  String get patternHerringbone => '人字铺';

  @override
  String get patternCustom => '自定义';

  @override
  String get boxesAndCost => '箱规与成本';

  @override
  String get tilesPerBox => '每箱片数';

  @override
  String get pricePerBox => '每箱价格';

  @override
  String get boxesToBuy => '购买箱数';

  @override
  String get estimatedCost => '预估成本';

  @override
  String wasteLine(int base, int waste) {
    String _temp0 = intl.Intl.pluralLogic(
      base,
      locale: localeName,
      other: '$base 片 + $waste% 损耗',
    );
    return '$_temp0';
  }

  @override
  String get smallAreaHint => '小面积切割损耗更高，建议加 5%。';

  @override
  String get resultEmptyPrompt => '输入尺寸后显示结果';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get currencySymbol => '货币符号';

  @override
  String get versionLabel => '版本';

  @override
  String get rateApp => '给个好评';

  @override
  String get historyTitle => '历史记录';

  @override
  String get historyEmpty => '算过的记录会出现在这里';

  @override
  String get delete => '删除';

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟前',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小时前',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天前',
    );
    return '$_temp0';
  }

  @override
  String get clearAll => '清空全部';

  @override
  String get clearAllConfirm => '确定清空全部历史记录？';

  @override
  String get cancel => '取消';

  @override
  String get historyFooterNote => '每次计算都会保存——免费，无上限。';

  @override
  String get languagePageNote => '仅覆盖本应用的语言——为没有分应用语言设置的旧设备提供。';

  @override
  String get linkOpenFailed => '无法打开链接';

  @override
  String wasteShort(int pct) {
    return '$pct% 损耗';
  }

  @override
  String get sectionMaterials => '辅料';

  @override
  String get materialsDefaults => '已按默认值计算';

  @override
  String get tileThickness => '瓷砖厚度';

  @override
  String get jointDepth => '缝深';

  @override
  String get jointDepthFollows => '= 砖厚';

  @override
  String get trowelLabel => '镘刀';

  @override
  String get trowelAuto => '自动';

  @override
  String get trowelAutoCaption => '自动按砖尺寸选齿号。';

  @override
  String get groutNeeded => '填缝剂';

  @override
  String get thinsetNeeded => '胶粘剂';

  @override
  String thinsetBagsLine(int bags, String spec) {
    String _temp0 = intl.Intl.pluralLogic(
      bags,
      locale: localeName,
      other: '≈ $bags 袋 · $spec',
    );
    return '$_temp0';
  }

  @override
  String get materialsDisclaimer => '用量为估算，请以所购产品的覆盖率表为准。';

  @override
  String get shareResult => '分享';

  @override
  String get shareFailed => '分享失败，请重试。';

  @override
  String get shareCardFooter => 'TileMath — 带分数英寸键盘的瓷砖计算器';

  @override
  String previewCaption(String pattern, String grout) {
    return '$pattern · 缝 $grout';
  }
}
