import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'consent_manager.dart';

/// 广告初始化编排：UMP 同意 gate → MobileAds 初始化。
///
/// 主会话应在启动后（首帧后）调用一次 [initialize]；广告组件内部也会
/// 调用它以等待/复用初始化结果，重复调用安全。
class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  bool _ready = false;
  Future<bool>? _initializing;

  /// SDK 是否已完成初始化（同意通过且 MobileAds 初始化成功）。
  bool get isReady => _ready;

  /// 初始化广告。返回是否可以请求广告。
  ///
  /// - 同意流失败或被拒：返回 false，不初始化 SDK，可再次调用重试。
  /// - 并发调用共享同一初始化过程；失败后清除缓存以允许重试。
  Future<bool> initialize() {
    if (_ready) return Future.value(true);
    return _initializing ??= _doInitialize().then((ok) {
      _ready = ok;
      if (!ok) _initializing = null; // 允许重试
      return ok;
    });
  }

  Future<bool> _doInitialize() async {
    final canRequest = await ConsentManager.instance.gatherConsent();
    if (!canRequest) return false;
    try {
      await MobileAds.instance.initialize();
      return true;
    } catch (e) {
      debugPrint('MobileAds 初始化失败: $e');
      return false;
    }
  }
}
