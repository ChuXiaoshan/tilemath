import 'dart:math' as math;

import 'tile_calculation.dart';

/// 一片砖面的多边形（画布 px 坐标，顶点首尾不重复）。
class TilePoly {
  final List<(double, double)> points;

  const TilePoly(this.points);
}

/// 生成铺贴预览多边形（spec §2.3）。
/// 比例真实：横向约 [targetAcross] 个铺贴节距（砖+缝）；
/// straight/custom 正铺，diagonal 旋转 45°，herringbone 用 2:1 错缝砖
/// 旋转 45° 示意（真人字互扣留后续版本）。
List<TilePoly> layoutTiles({
  required double width,
  required double height,
  required double tileWmm,
  required double tileHmm,
  required double groutMm,
  required LayoutPattern pattern,
  double targetAcross = 5,
  // 缝隙视觉下限（px）：真实比例下窄缝（如 1/16″）在小画布上是亚像素，
  // 预览需要保底可见缝才能辨认铺法。仅在 groutMm > 0 时生效——
  // 无缝铺法（groutMm = 0）保持真无缝语义，不强加视觉缝。默认 0 不
  // 改变既有行为（调用方不传即保持原样）。
  double minGroutPx = 0,
}) {
  if (width <= 0 || height <= 0 || tileWmm <= 0 || tileHmm <= 0) {
    return const [];
  }
  final pitchWmm = tileWmm + groutMm;
  final scale = width / (targetAcross * pitchWmm);
  // 节距（砖+缝）由 scale 决定，必须保持不变；保底缝只改变节距内
  // 砖/缝的分配比例——缝变大 delta 少，砖面同量收窄，节距恒定。
  final rawGroutPx = groutMm * scale;
  final groutPx = groutMm > 0 ? math.max(rawGroutPx, minGroutPx) : 0.0;
  final delta = groutPx - rawGroutPx;
  switch (pattern) {
    case LayoutPattern.straight:
    case LayoutPattern.custom:
      return _grid(width, height, tileWmm * scale - delta,
          tileHmm * scale - delta, groutPx, angle: 0, brickOffset: false);
    case LayoutPattern.diagonal:
      return _grid(width, height, tileWmm * scale - delta,
          tileHmm * scale - delta, groutPx,
          angle: math.pi / 4, brickOffset: false);
    case LayoutPattern.herringbone:
      // 2:1 砖：长边 = 2×短边（正方砖）或实际长短边（矩形砖）
      final shortPx = math.min(tileWmm, tileHmm) * scale;
      final longPx = tileWmm == tileHmm
          ? shortPx * 2
          : math.max(tileWmm, tileHmm) * scale;
      return _grid(width, height, longPx - delta, shortPx - delta, groutPx,
          angle: -math.pi / 4, brickOffset: true);
  }
}

/// 网格生成：angle=0 时只生成与画布相交的整行整列（数量可精确断言）；
/// 旋转时扩大生成域再绕画布中心旋转，最后按包围盒剔除画布外多边形。
List<TilePoly> _grid(
  double width,
  double height,
  double tilePxW,
  double tilePxH,
  double groutPx, {
  required double angle,
  required bool brickOffset,
}) {
  final pitchX = tilePxW + groutPx;
  final pitchY = tilePxH + groutPx;
  final rotated = angle != 0;
  // 旋转覆盖半径：画布对角线的一半，向外再放一圈
  final radius = rotated ? math.sqrt(width * width + height * height) / 2 : 0.0;
  final x0 = rotated ? -(radius + pitchX) : 0.0;
  final x1 = rotated ? width + radius + pitchX : width;
  final y0 = rotated ? -(radius + pitchY) : 0.0;
  final y1 = rotated ? height + radius + pitchY : height;
  final cx = width / 2;
  final cy = height / 2;
  final cosA = math.cos(angle);
  final sinA = math.sin(angle);

  (double, double) transform(double x, double y) {
    if (!rotated) return (x, y);
    final dx = x - cx;
    final dy = y - cy;
    return (cx + dx * cosA - dy * sinA, cy + dx * sinA + dy * cosA);
  }

  final polys = <TilePoly>[];
  var rowIndex = 0;
  for (var y = y0; y < y1 - 1e-9; y += pitchY, rowIndex++) {
    // 错缝：奇数行横移半个节距（herringbone 示意用）
    final shift = brickOffset && rowIndex.isOdd ? -pitchX / 2 : 0.0;
    for (var x = x0 + shift; x < x1 - 1e-9; x += pitchX) {
      final pts = [
        transform(x, y),
        transform(x + tilePxW, y),
        transform(x + tilePxW, y + tilePxH),
        transform(x, y + tilePxH),
      ];
      if (rotated) {
        var minX = double.infinity, maxX = -double.infinity;
        var minY = double.infinity, maxY = -double.infinity;
        for (final (px, py) in pts) {
          minX = math.min(minX, px);
          maxX = math.max(maxX, px);
          minY = math.min(minY, py);
          maxY = math.max(maxY, py);
        }
        if (maxX <= 0 || minX >= width || maxY <= 0 || minY >= height) {
          continue;
        }
      }
      polys.add(TilePoly(pts));
    }
  }
  return polys;
}
