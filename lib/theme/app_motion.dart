import 'package:flutter/animation.dart';

/// 动效常量 — 严格对应 design-tokens.md v0.9 §6 Motion
/// 减弱动效（reduced-motion）下全部退化为简单淡入淡出
abstract final class AppMotion {
  // 键盘入场
  static const Duration keyboardInDuration = Duration(milliseconds: 240);
  static const Cubic keyboardInCurve = Cubic(0.05, 0.7, 0.1, 1);

  // 键盘出场
  static const Duration keyboardOutDuration = Duration(milliseconds: 180);
  static const Cubic keyboardOutCurve = Cubic(0.3, 0, 0.8, 0.15);

  /// 结果值切换：立即替换 + 90ms 不透明度过渡（不做数字滚动）
  static const Duration resultSwapDuration = Duration(milliseconds: 90);

  // 行增/行删：高度 + 淡入淡出
  static const Duration rowAddDuration = Duration(milliseconds: 200);
  static const Duration rowRemoveDuration = Duration(milliseconds: 160);
  static const Cubic rowCurve = Cubic(0.2, 0, 0, 1);
}
