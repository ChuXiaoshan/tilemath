import 'dart:io';

import 'package:flutter/painting.dart' show Rect;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'share_card_renderer.dart';

/// 渲染分享卡 → 临时文件 → 系统分享面板。异常向上抛，由 UI 兜 SnackBar。
///
/// share_plus 解析出的是 12.x：旧版 `Share.shareXFiles` 已标 `@Deprecated`，
/// 改走新版规范入口 `SharePlus.instance.share(ShareParams(...))`。
///
/// [sharePositionOrigin] 必填：iPad/Mac 上分享面板以 popover 形式弹出，
/// 需要一个全局坐标锚点矩形；share_plus 12 起 iOS 实现在 iPad 缺锚点时
/// 直接返回 FlutterError（不弹面板），不是可选的美化参数。iPhone 上传入
/// 无副作用（该平台忽略此参数）。
Future<void> shareResultCard(
  ShareCardData data, {
  required Rect sharePositionOrigin,
}) async {
  final bytes = await renderShareCardPng(data);
  final dir = await getTemporaryDirectory();
  final file = File(
      '${dir.path}/tilemath-share-${DateTime.now().millisecondsSinceEpoch}.png');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'image/png')],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}
