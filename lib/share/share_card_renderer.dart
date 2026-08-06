import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/pattern_geometry.dart';
import '../domain/tile_calculation.dart';

/// 分享卡数据：文案由调用方本地化后传入，渲染器不碰 BuildContext。
class ShareCardData {
  final String appName;
  final String date;
  final String tilesLabel;
  final String tilesValue;
  final String wasteLine;

  /// (标签, 值) 明细行；未填的行调用方直接不传。
  final List<(String, String)> rows;
  final String specLine;
  final String footer;
  final double tileWmm;
  final double tileHmm;
  final double groutMm;
  final LayoutPattern pattern;

  const ShareCardData({
    required this.appName,
    required this.date,
    required this.tilesLabel,
    required this.tilesValue,
    required this.wasteLine,
    required this.rows,
    required this.specLine,
    required this.footer,
    required this.tileWmm,
    required this.tileHmm,
    required this.groutMm,
    required this.pattern,
  });
}

// 浅色主题固定（token 表 Light）：分享出去的卡不跟随深色模式。
// 砖面用品牌青 primaryContainer(Light)，顶部品牌青条（2026-08-06 拍板：
// 视觉增强只用现有青色系）。
const _bg = Color(0xFFF3F2F2);
const _ink = Color(0xFF201E1D);
const _sub = Color(0xFF605D5D);
const _tile = Color(0xFFCBEEFF);
const _grout = Color(0xFFEAE9E9);
const _brand = Color(0xFF0088B0);

const _w = 1080.0;
const _h = 1350.0;
const _pad = 66.0;

/// 离屏渲染分享卡（设计稿 10c）：Canvas 手绘，不依赖 widget 树。
Future<Uint8List> renderShareCardPng(ShareCardData data) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, _w, _h), Paint()..color = _bg);
  // 顶部品牌识别条
  canvas.drawRect(const Rect.fromLTWH(0, 0, _w, 18), Paint()..color = _brand);

  double y = _pad;

  // 品牌头：名称左、日期右
  _text(canvas, data.appName, const Offset(_pad, 0),
      size: 45, weight: FontWeight.w700, baselineY: y + 45);
  _text(canvas, data.date, Offset(_w - _pad, 0),
      size: 33, color: _sub, alignRight: true, baselineY: y + 45);
  y += 45 + 54;

  // 大数字块
  _text(canvas, data.tilesLabel, Offset(_pad, 0),
      size: 36, color: _sub, weight: FontWeight.w600,
      letterSpacing: 2.9, baselineY: y + 36);
  y += 36 + 24;
  _text(canvas, data.tilesValue, Offset(_pad, 0),
      size: 168, weight: FontWeight.w600, baselineY: y + 160);
  y += 168 + 18;
  _text(canvas, data.wasteLine, Offset(_pad, 0),
      size: 39, color: _sub, baselineY: y + 39);
  y += 39 + 48;

  // 明细行
  for (final (label, value) in data.rows) {
    _text(canvas, label, Offset(_pad, 0),
        size: 39, color: _sub, baselineY: y + 39);
    _text(canvas, value, Offset(_w - _pad, 0),
        size: 45, weight: FontWeight.w600, alignRight: true, baselineY: y + 42);
    y += 45 + 21;
  }
  y += 27;

  // 铺贴预览条
  const previewH = 168.0;
  final previewRect = Rect.fromLTWH(_pad, y, _w - 2 * _pad, previewH);
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(previewRect, const Radius.circular(6)));
  canvas.drawRect(previewRect, Paint()..color = _grout);
  final polys = layoutTiles(
    width: previewRect.width,
    height: previewRect.height,
    tileWmm: data.tileWmm,
    tileHmm: data.tileHmm,
    groutMm: data.groutMm,
    pattern: data.pattern,
    targetAcross: 10,
  );
  final tilePaint = Paint()..color = _tile;
  for (final poly in polys) {
    final path = Path()
      ..moveTo(previewRect.left + poly.points.first.$1,
          previewRect.top + poly.points.first.$2);
    for (final (px, py) in poly.points.skip(1)) {
      path.lineTo(previewRect.left + px, previewRect.top + py);
    }
    path.close();
    canvas.drawPath(path, tilePaint);
  }
  canvas.restore();
  y += previewH + 33;

  // 参数行 + 页脚
  _text(canvas, data.specLine, Offset(_pad, 0),
      size: 33, color: _sub, baselineY: y + 33);
  _text(canvas, data.footer, Offset(_pad, 0),
      size: 31, color: _sub, baselineY: _h - _pad);

  final picture = recorder.endRecording();
  final image = await picture.toImage(_w.toInt(), _h.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

/// 文本绘制：value/尺寸表达式恒 LTR；alignRight 以 x 为右缘。
void _text(
  Canvas canvas,
  String content,
  Offset at, {
  required double size,
  required double baselineY,
  Color color = _ink,
  FontWeight weight = FontWeight.w400,
  double letterSpacing = 0,
  bool alignRight = false,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: content,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        fontFeatures: const [ui.FontFeature.tabularFigures()],
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: _w - 2 * _pad);
  final dx = alignRight ? at.dx - painter.width : at.dx;
  painter.paint(canvas, Offset(dx, baselineY - painter.height));
}
