import 'package:flutter/material.dart';

/// 字体排印 — 严格对应 design-tokens.md v0.9 §3
/// 数字、单位、尺寸表达式在所有语言下均用 Latin 字族 + tabular figures
abstract final class AppTypography {
  static const String _family = 'IBM Plex Sans';
  static const List<String> _fallback = ['IBM Plex Sans Arabic', 'Noto Sans SC'];
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static const TextTheme textTheme = TextTheme(
    // 所需瓷砖数大字（一臂距离可读）
    displayLarge: TextStyle(
      fontFamily: _family,
      fontFamilyFallback: _fallback,
      fontSize: 64,
      height: 64 / 64,
      fontWeight: FontWeight.w600,
      letterSpacing: -1.0,
      fontFeatures: _tabular,
    ),
    // 键盘数字
    headlineSmall: TextStyle(
      fontFamily: _family,
      fontFamilyFallback: _fallback,
      fontSize: 23,
      height: 28 / 23,
      fontWeight: FontWeight.w600,
      fontFeatures: _tabular,
    ),
    // App bar 标题
    titleLarge: TextStyle(
      fontFamily: _family,
      fontFamilyFallback: _fallback,
      fontSize: 19,
      height: 26 / 19,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    // 结果值（面积、箱数、费用）
    titleMedium: TextStyle(
      fontFamily: _family,
      fontFamilyFallback: _fallback,
      fontSize: 17,
      height: 24 / 17,
      fontWeight: FontWeight.w600,
      fontFeatures: _tabular,
    ),
    // 字段值、分数键帽
    bodyLarge: TextStyle(
      fontFamily: _family,
      fontFamilyFallback: _fallback,
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
      fontFeatures: _tabular,
    ),
    // 辅助文案、提示
    bodyMedium: TextStyle(
      fontFamily: _family,
      fontFamilyFallback: _fallback,
      fontSize: 14,
      height: 21 / 14,
      fontWeight: FontWeight.w400,
    ),
    // 说明文字、广告标注
    bodySmall: TextStyle(
      fontFamily: _family,
      fontFamilyFallback: _fallback,
      fontSize: 12,
      height: 18 / 12,
      fontWeight: FontWeight.w400,
    ),
    // 文本按钮（+ Add area）、功能键帽（ft/in/Next/Done）
    labelLarge: TextStyle(
      fontFamily: _family,
      fontFamilyFallback: _fallback,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    // 分区导语（使用处需自行大写）
    labelMedium: TextStyle(
      fontFamily: _family,
      fontFamilyFallback: _fallback,
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
    ),
    // 行标签（Area 1）
    labelSmall: TextStyle(
      fontFamily: _family,
      fontFamilyFallback: _fallback,
      fontSize: 11,
      height: 16 / 11,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.2,
    ),
  );
}
