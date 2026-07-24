import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';
import 'ads_service.dart';

/// 常驻锚定自适应 Banner（anchored adaptive banner）。
///
/// 自包含：内部完成初始化等待、尺寸计算、加载与释放。
/// 未同意 / 初始化失败 / 加载失败时渲染同高度占位，不抛异常。
/// 加载失败按有限退避重试；可用宽度显著变化时释放旧广告并按新宽度重载。
///
/// 布局约定（AdMob 误触政策）：本 Widget 不绘制分隔带，键盘等交互区与
/// Banner 之间的 16-18dp 非交互隔离带由页面布局负责。
class AnchoredBanner extends StatefulWidget {
  const AnchoredBanner({super.key});

  @override
  State<AnchoredBanner> createState() => _AnchoredBannerState();
}

class _AnchoredBannerState extends State<AnchoredBanner> {
  /// 尺寸预取失败时的占位高度兜底（adaptive banner 实际高度随设备在 50-70dp 浮动）。
  /// 正常路径使用预取的 [_adSize] 高度，保证加载成功前后高度一致、无布局跳动。
  static const double _fallbackPlaceholderHeight = 60;

  /// 加载失败的有限重试退避序列（30s/60s/120s，共 3 次）：
  /// 兼顾 no-fill/网络抖动后的恢复与请求成本，用尽后保持占位，不做无限重试。
  static const List<Duration> _retryBackoff = [
    Duration(seconds: 30),
    Duration(seconds: 60),
    Duration(seconds: 120),
  ];

  /// 触发重载的宽度变化阈值（逻辑像素）：小于该值的抖动（如系统栏微调）不重载。
  static const double _widthChangeThreshold = 8;

  BannerAd? _bannerAd;
  bool _isLoaded = false;

  /// 预取的自适应尺寸：请求广告与占位高度共用，杜绝加载瞬间高度跳变。
  AnchoredAdaptiveBannerAdSize? _adSize;

  /// 当前广告/加载流程对应的请求宽度（SafeArea 内实际可用宽度）。
  int? _requestedWidth;

  int _retryCount = 0;
  Timer? _retryTimer;

  /// 加载代次：宽度变化重载时自增，使仍在途的旧异步流程失效并释放其结果。
  int _loadGeneration = 0;

  /// 根据布局实际可用宽度启动加载或重载。build（LayoutBuilder）中调用：
  /// 只做字段更新与异步调度，不直接 setState。
  void _onWidthAvailable(double maxWidth) {
    if (!maxWidth.isFinite || maxWidth <= 0) return;
    final width = maxWidth.truncate();

    final requested = _requestedWidth;
    if (requested == null) {
      _requestedWidth = width;
      _startLoad(width);
      return;
    }
    if ((width - requested).abs() >= _widthChangeThreshold) {
      // 宽度显著变化（旋转/分屏等）：作废旧广告与重试计划，按新宽度重载
      _requestedWidth = width;
      _retryTimer?.cancel();
      _retryTimer = null;
      _retryCount = 0;
      _bannerAd?.dispose();
      _bannerAd = null;
      _isLoaded = false;
      _startLoad(width);
    }
  }

  void _startLoad(int width) {
    _loadGeneration++;
    unawaited(_loadAd(width, _loadGeneration));
  }

  Future<void> _loadAd(int width, int generation) async {
    // 等待/复用初始化结果；未同意或初始化失败则保持占位
    final ready = await AdsService.instance.initialize();
    if (!ready || !mounted || generation != _loadGeneration) return;

    // 9.0.0 起旧的 getCurrentOrientationAnchoredAdaptiveBannerAdSize 已废弃
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || generation != _loadGeneration) return;
    if (size == null) return;

    if (_adSize?.height != size.height) {
      // 占位提前采用广告实际高度，加载成功时高度不再变化
      setState(() => _adSize = size);
    } else {
      _adSize = size;
    }

    final ad = BannerAd(
      adUnitId: AdIds.anchoredBanner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || generation != _loadGeneration) {
            ad.dispose();
            return;
          }
          _retryCount = 0;
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          // 加载失败：释放并保持占位，带退避有限重试
          debugPrint('Banner 加载失败: ${error.code} ${error.message}');
          ad.dispose();
          if (!mounted || generation != _loadGeneration) return;
          _scheduleRetry();
        },
      ),
    );
    try {
      await ad.load();
    } catch (e) {
      debugPrint('Banner load 异常: $e');
      await ad.dispose();
      if (mounted && generation == _loadGeneration) _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_retryCount >= _retryBackoff.length) return; // 重试用尽：保持占位
    final delay = _retryBackoff[_retryCount];
    _retryCount++;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (!mounted) return;
      final width = _requestedWidth;
      if (width == null) return;
      _startLoad(width);
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _loadGeneration++; // 使在途加载失效，其结果在回调中自行 dispose
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder 置于 SafeArea 之内：以扣除左右安全区后的实际可用宽度
    // 请求自适应尺寸，避免横屏刘海机上广告被父级内缩裁切。
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _onWidthAvailable(constraints.maxWidth);

          final ad = _bannerAd;
          if (ad != null && _isLoaded) {
            return SizedBox(
              width: ad.size.width.toDouble(),
              height: ad.size.height.toDouble(),
              child: AdWidget(ad: ad),
            );
          }
          final placeholderHeight =
              _adSize?.height.toDouble() ?? _fallbackPlaceholderHeight;
          return SizedBox(width: double.infinity, height: placeholderHeight);
        },
      ),
    );
  }
}
