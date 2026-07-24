import 'package:flutter/material.dart';

/// 颜色方案 — 严格对应 design-tokens.md v0.9 §1/§2
/// Seed: #0088B0（process cyan）
abstract final class AppColors {
  /// Light（主方案，工地日光场景）
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    // 填充类操作：Done 键、选中 chip
    primary: Color(0xFF006786),
    onPrimary: Color(0xFFF3F2F2),
    // 激活段键（in）、编辑段高亮
    primaryContainer: Color(0xFFCBEEFF),
    onPrimaryContainer: Color(0xFF004961),
    // 焦点环、光标、选区、聚焦输入框边框 — 仅限非文本
    secondary: Color(0xFF0088B0),
    // token 表未给出，secondary 仅作非文本用途，沿用 onPrimary
    onSecondary: Color(0xFFF3F2F2),
    // token 表未给出，沿用 primaryContainer / onPrimaryContainer
    secondaryContainer: Color(0xFFCBEEFF),
    onSecondaryContainer: Color(0xFF004961),
    // 切角语义（负空间）— 保留色，禁止装饰性使用
    tertiary: Color(0xFFAA0B56),
    // token 表未给出，tertiary 为深色填充，沿用 onPrimary
    onTertiary: Color(0xFFF3F2F2),
    // 切角标签
    tertiaryContainer: Color(0xFFFFF1F4),
    onTertiaryContainer: Color(0xFF790E3D),
    // 应用背景（"纸面"）
    surface: Color(0xFFF3F2F2),
    onSurface: Color(0xFF201E1D),
    // 标签/说明文字 ≥12sp；数字禁用此角色
    onSurfaceVariant: Color(0xFF605D5D),
    // 输入框/按键边框
    outline: Color(0xFF949191),
    // 仅组件内部发丝线（禁止用作分区分隔线）
    outlineVariant: Color(0xFFD1D0D0),
    // 仅校验用
    error: Color(0xFFB3261E),
    // token 表未给出，error 为深色填充，沿用 onPrimary
    onError: Color(0xFFF3F2F2),
    // 凸起键帽
    surfaceContainerLowest: Color(0xFFF8F4F4),
    // 输入框填充、键盘托盘
    surfaceContainerLow: Color(0xFFEAE9E9),
    // 按压态、广告 banner 占位底
    surfaceContainerHigh: Color(0xFFD7D3D3),
  );

  /// Dark（重新校准，非简单反色）
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    // 深色下可承载文本（8.5:1）
    primary: Color(0xFF62C5EE),
    onPrimary: Color(0xFF0A303E),
    primaryContainer: Color(0xFF004961),
    onPrimaryContainer: Color(0xFFCBEEFF),
    // 焦点/光标
    secondary: Color(0xFF38A6CF),
    // token 表未给出，secondary 仅作非文本用途，沿用 onPrimary
    onSecondary: Color(0xFF0A303E),
    // token 表未给出，沿用 primaryContainer / onPrimaryContainer
    secondaryContainer: Color(0xFF004961),
    onSecondaryContainer: Color(0xFFCBEEFF),
    // 切角
    tertiary: Color(0xFFFF90B1),
    // token 表未给出，tertiary 为浅色填充，取 surface 深色以保证对比
    onTertiary: Color(0xFF201E1D),
    // token 表未给出，按 primary 的明暗互换规律由 light 版对调推导
    tertiaryContainer: Color(0xFF790E3D),
    onTertiaryContainer: Color(0xFFFFF1F4),
    surface: Color(0xFF201E1D),
    onSurface: Color(0xFFEAE7E7),
    onSurfaceVariant: Color(0xFFBAB6B6),
    outline: Color(0xFF605D5D),
    outlineVariant: Color(0xFF444141),
    error: Color(0xFFF2B8B5),
    // token 表未给出，error 为浅色填充，取 surface 深色以保证对比
    onError: Color(0xFF201E1D),
    // 托盘
    surfaceContainerLow: Color(0xFF2D2B2B),
    // 键帽
    surfaceContainerHigh: Color(0xFF444141),
    // token 表 dark 未定义 surfaceContainerLowest，留空回退到 surface
  );
}
