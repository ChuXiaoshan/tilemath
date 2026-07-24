import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// UMP（User Messaging Platform）同意流封装。
///
/// 流程：请求同意信息更新 → 需要时加载并展示同意表单 → 以 canRequestAds 为准。
///
/// iOS ATT 策略：ATT 弹窗应在 UMP 同意流完成之后再请求（先 GDPR 表单、后 ATT，
/// 避免弹窗叠加）。ATT 请求本身是否引入 app_tracking_transparency 依赖由主会话
/// 决定，本文件不自行添加依赖。
/// TODO(main): 在 [gatherConsent] 完成后接入 ATT 请求（如需要）。
class ConsentManager {
  ConsentManager._();

  static final ConsentManager instance = ConsentManager._();

  /// 执行同意流。返回当前是否允许请求广告。
  ///
  /// 任何一步失败均不抛异常、不阻塞启动：降级为返回 canRequestAds 的当前值
  /// （通常为 false，即不请求广告）。方法可重复调用以重试。
  Future<bool> gatherConsent() async {
    final completer = Completer<FormError?>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        // 同意信息更新成功：需要时加载并展示同意表单（不需要时立即回调）
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
            if (!completer.isCompleted) completer.complete(formError);
          });
        } catch (e) {
          debugPrint('UMP 表单展示异常: $e');
          if (!completer.isCompleted) completer.complete(null);
        }
      },
      (error) {
        // 同意信息更新失败（如无网络）
        if (!completer.isCompleted) completer.complete(error);
      },
    );

    final error = await completer.future;
    if (error != null) {
      debugPrint('UMP 同意流失败: ${error.errorCode} ${error.message}');
    }
    return canRequestAds();
  }

  /// 当前是否允许请求广告（含同意被拒/未完成同意流的情况）。
  Future<bool> canRequestAds() async {
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      debugPrint('canRequestAds 查询异常: $e');
      return false;
    }
  }
}
