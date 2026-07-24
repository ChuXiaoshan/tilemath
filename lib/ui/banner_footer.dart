import 'package:flutter/material.dart';

import '../ads/anchored_banner.dart';
import '../theme/app_dimens.dart';

/// 底部广告底座：非交互隔离带（16dp + 表面色差，AdMob 误触政策）+ anchored banner。
/// 系统 IME 弹出时整体隐藏——banner 不得紧贴系统键盘。
/// 设计稿（5a/5b）：主页/History/Settings 三页底部均锚定此底座。
class BannerFooter extends StatelessWidget {
  const BannerFooter({super.key});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: AppDimens.keyboardBannerGapMin,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
        const AnchoredBanner(),
      ],
    );
  }
}
