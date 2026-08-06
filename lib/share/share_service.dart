import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'share_card_renderer.dart';

/// 渲染分享卡 → 临时文件 → 系统分享面板。异常向上抛，由 UI 兜 SnackBar。
///
/// share_plus 解析出的是 12.x：旧版 `Share.shareXFiles` 已标 `@Deprecated`，
/// 改走新版规范入口 `SharePlus.instance.share(ShareParams(...))`。
Future<void> shareResultCard(ShareCardData data) async {
  final bytes = await renderShareCardPng(data);
  final dir = await getTemporaryDirectory();
  final file = File(
      '${dir.path}/tilemath-share-${DateTime.now().millisecondsSinceEpoch}.png');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path, mimeType: 'image/png')]),
  );
}
