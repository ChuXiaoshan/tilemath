/// 尺寸常量 — 严格对应 design-tokens.md v0.9 §4/§5/§6
abstract final class AppDimens {
  // ---- Spacing（4dp 基准）----
  /// 图标↔文字间距、键帽内边距
  static const double space4 = 4;

  /// 按键槽、chip 间距、结果行堆叠
  static const double space8 = 8;

  /// 区域行间距、输入框水平内边距
  static const double space12 = 12;

  /// 屏幕边距、键盘托盘内边距
  static const double space16 = 16;

  /// 表单分区之间（留白即分隔线）
  static const double space24 = 24;

  /// 结果块上方；两栏布局列间距
  static const double space32 = 32;

  /// 最小触控目标对应的间距步进
  static const double space48 = 48;

  // ---- Radius（禁止胶囊圆角 — 一切都是切好的瓷砖，不是胶囊）----
  /// 迷你铺贴预览小块
  static const double radius1 = 1;

  /// 输入框、键帽、chip、标签、分段选项
  static const double radius2 = 2;

  /// 结果面板、对话框、banner 占位
  static const double radius4 = 4;

  // ---- 触控 ----
  /// 最小触控目标（视觉可更小，命中区扩展到 48）
  static const double minTouchTarget = 48;

  /// 平板键盘键位尺寸
  static const double tabletKeySize = 56;

  // ---- 键盘↔banner 非交互间隔带（16–18dp）----
  static const double keyboardBannerGapMin = 16;
  static const double keyboardBannerGapMax = 18;
}
