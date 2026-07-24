import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// 主题汇总 — colorScheme + textTheme，不加 token 表之外的组件样式
abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: AppColors.light,
    textTheme: AppTypography.textTheme,
    scaffoldBackgroundColor: AppColors.light.surface,
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: AppColors.dark,
    textTheme: AppTypography.textTheme,
    scaffoldBackgroundColor: AppColors.dark.surface,
  );
}
