import 'package:flutter/material.dart';

import '../domain/length.dart';
import '../domain/pattern_geometry.dart';
import '../domain/tile_calculation.dart';
import '../theme/app_dimens.dart';

/// 迷你铺贴预览（brief v2 §3.4 / 设计稿 10a）：按真实比例绘制当前
/// 砖尺寸 + 缝宽 + 铺法，输入变化实时重绘。
class PatternPreview extends StatelessWidget {
  final Length tileWidth;
  final Length tileHeight;
  final Length grout;
  final LayoutPattern pattern;
  final double size;

  const PatternPreview({
    super.key,
    required this.tileWidth,
    required this.tileHeight,
    required this.grout,
    required this.pattern,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radius1),
      child: CustomPaint(
        size: Size.square(size),
        painter: PatternPreviewPainter(
          tileWmm: tileWidth.mm,
          tileHmm: tileHeight.mm,
          groutMm: grout.mm,
          pattern: pattern,
          // 砖面用品牌青 primaryContainer（2026-08-06 拍板：视觉增强
          // 只用现有青色系、不引入新色），缝色为托盘表面色，明暗主题
          // 由 scheme 自动适配。
          tileColor: scheme.primaryContainer,
          groutColor: scheme.surfaceContainerLow,
        ),
      ),
    );
  }
}

class PatternPreviewPainter extends CustomPainter {
  final double tileWmm;
  final double tileHmm;
  final double groutMm;
  final LayoutPattern pattern;
  final Color tileColor;
  final Color groutColor;

  const PatternPreviewPainter({
    required this.tileWmm,
    required this.tileHmm,
    required this.groutMm,
    required this.pattern,
    required this.tileColor,
    required this.groutColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 底色即缝色：砖面之间露出的就是缝
    canvas.drawRect(Offset.zero & size, Paint()..color = groutColor);
    final polys = layoutTiles(
      width: size.width,
      height: size.height,
      tileWmm: tileWmm,
      tileHmm: tileHmm,
      groutMm: groutMm,
      pattern: pattern,
    );
    final paint = Paint()..color = tileColor;
    for (final poly in polys) {
      final path = Path()
        ..moveTo(poly.points.first.$1, poly.points.first.$2);
      for (final (x, y) in poly.points.skip(1)) {
        path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(PatternPreviewPainter oldDelegate) =>
      tileWmm != oldDelegate.tileWmm ||
      tileHmm != oldDelegate.tileHmm ||
      groutMm != oldDelegate.groutMm ||
      pattern != oldDelegate.pattern ||
      tileColor != oldDelegate.tileColor ||
      groutColor != oldDelegate.groutColor;
}
