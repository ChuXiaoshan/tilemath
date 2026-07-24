import 'package:intl/intl.dart';

import '../domain/length.dart';
import '../keyboard/metric_editor.dart';
import '../state/settings_controller.dart';

const _sqMPerSqFt = 0.3048 * 0.3048;

/// 公制长度显示：按字段惯用单位输出，locale 决定小数分隔符。
/// 数字恒用西文数字（token 硬规则），intl 的 ar 数字格式需显式压回拉丁。
String formatMetric(Length l, MetricUnit unit, String locale) {
  final value = switch (unit) {
    MetricUnit.m => l.meters,
    MetricUnit.cm => l.cm,
    MetricUnit.mm => l.mm,
  };
  final f = NumberFormat.decimalPatternDigits(
    locale: _latinDigitsLocale(locale),
    decimalDigits: _trailingDigits(value),
  );
  return '${f.format(value)} ${unit.name}';
}

/// 长度显示统一入口：英制走 formatImperial，公制按字段惯用单位。
String formatLength(
  Length l,
  UnitSystem system,
  MetricUnit metricUnit,
  String locale,
) =>
    system == UnitSystem.imperial
        ? formatImperial(l)
        : formatMetric(l, metricUnit, locale);

/// 面积显示：ft² / m²，两位小数。
String formatArea(double sqM, UnitSystem system, String locale) {
  final value = system == UnitSystem.imperial ? sqM / _sqMPerSqFt : sqM;
  final unit = system == UnitSystem.imperial ? 'ft²' : 'm²';
  final f = NumberFormat.decimalPatternDigits(
    locale: _latinDigitsLocale(locale),
    decimalDigits: 2,
  );
  return '${f.format(value)} $unit';
}

/// 金额显示：货币符号前置 + 两位小数（骨架版，符号来自设置项）。
String formatCost(double cost, String symbol, String locale) {
  final f = NumberFormat.decimalPatternDigits(
    locale: _latinDigitsLocale(locale),
    decimalDigits: 2,
  );
  return '$symbol${f.format(cost)}';
}

/// 当前 locale 的小数分隔符（公制键盘键帽用）。
String decimalSeparatorOf(String locale) =>
    NumberFormat.decimalPattern(_latinDigitsLocale(locale)).symbols.DECIMAL_SEP;

/// 阿拉伯语 intl 默认输出阿拉伯-印度数字字形，与 token 硬规则（西文数字）冲突，
/// 直接退回 en_US 格式（0-9 + 点分隔）。
String _latinDigitsLocale(String locale) =>
    locale.startsWith('ar') ? 'en_US' : locale;

int _trailingDigits(double value) => value == value.roundToDouble() ? 0 : 2;
