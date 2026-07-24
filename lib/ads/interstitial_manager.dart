import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';
import 'ads_service.dart';

/// 插屏广告频控管理。
///
/// 用法：页面在每次有效计算完成时调 [recordCalculation]，
/// 在自然断点（如查看结果后返回）调 [maybeShow]。
/// 加载失败、未同意、频控未满足均静默处理，不影响主流程。
class InterstitialManager {
  InterstitialManager._();

  static final InterstitialManager instance = InterstitialManager._();

  // 低频策略是产品决策：工具类 app 口碑与留存优先，插屏只在自然断点低频出现。
  /// 两次插屏展示的最短间隔
  static const Duration minInterval = Duration(minutes: 3);

  /// 自上次展示后需完成的有效计算次数
  static const int minCalculationsBetweenShows = 3;

  InterstitialAd? _ad;
  bool _isLoading = false;
  DateTime? _lastShownAt;
  int _calculationsSinceLastShow = 0;

  /// 记录一次有效计算。计数达标时提前预加载。
  void recordCalculation() {
    _calculationsSinceLastShow++;
    if (_calculationsSinceLastShow >= minCalculationsBetweenShows) {
      unawaited(_preload());
    }
  }

  /// 自然断点入口：满足频控且已有预加载广告时展示，否则静默返回 false。
  Future<bool> maybeShow() async {
    if (!_frequencyAllows()) return false;

    final ad = _ad;
    if (ad == null) {
      // 没有可用广告：本次放弃并补预加载
      unawaited(_preload());
      return false;
    }
    _ad = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(_preload()); // 展示后重新预加载
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('插屏展示失败: ${error.code} ${error.message}');
        ad.dispose();
        unawaited(_preload());
      },
    );

    _lastShownAt = DateTime.now();
    _calculationsSinceLastShow = 0;
    try {
      await ad.show();
      return true;
    } catch (e) {
      debugPrint('插屏 show 异常: $e');
      await ad.dispose();
      return false;
    }
  }

  bool _frequencyAllows() {
    if (_calculationsSinceLastShow < minCalculationsBetweenShows) return false;
    final last = _lastShownAt;
    if (last == null) return true; // 从未展示过：仅受计算次数约束
    return DateTime.now().difference(last) >= minInterval;
  }

  /// 预加载插屏。已有广告或正在加载时跳过；加载失败静默（下次断点再试）。
  Future<void> _preload() async {
    if (_ad != null || _isLoading) return;
    // 进入即同步置位，杜绝并发调用在 await 间隙同时通过检查导致双重加载
    //（后一个 load 的结果会覆盖前一个，被覆盖的 InterstitialAd 泄漏不 dispose）。
    _isLoading = true;

    // load 请求成功受理后由 onAdLoaded/onAdFailedToLoad 回调负责复位 _isLoading；
    // 未受理（初始化失败/抛异常）则在 finally 复位。
    var loadDispatched = false;
    try {
      final ready = await AdsService.instance.initialize();
      if (!ready) return;

      await InterstitialAd.load(
        adUnitId: AdIds.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _isLoading = false;
            _ad = ad;
          },
          onAdFailedToLoad: (error) {
            _isLoading = false;
            debugPrint('插屏加载失败: ${error.code} ${error.message}');
          },
        ),
      );
      loadDispatched = true;
    } catch (e) {
      debugPrint('插屏加载异常: $e');
    } finally {
      if (!loadDispatched) _isLoading = false;
    }
  }
}
