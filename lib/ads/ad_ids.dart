// 广告位 ID 常量。
//
// ⚠️ 当前全部为 Google 官方测试 ID，上架前必须替换为正式 ID。
// App ID 同时配置在 AndroidManifest.xml / Info.plist 中，替换时三处同步。

import 'dart:io';

/// AdMob 广告 ID（按平台区分）。
class AdIds {
  AdIds._();

  /// App ID（仅作记录，实际生效位置在原生配置文件中）
  static String get appId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544~3347511713'
      : 'ca-app-pub-3940256099942544~1458002511';

  /// 锚定自适应 Banner 测试单元 ID
  static String get anchoredBanner => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/9214589741'
      : 'ca-app-pub-3940256099942544/2435281174';

  /// 插屏测试单元 ID
  static String get interstitial => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';
}
