import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/pattern_geometry.dart';
import 'package:tilemath/domain/tile_calculation.dart';

bool intersectsCanvas(TilePoly p, double w, double h) {
  var minX = double.infinity, maxX = -double.infinity;
  var minY = double.infinity, maxY = -double.infinity;
  for (final (x, y) in p.points) {
    if (x < minX) minX = x;
    if (x > maxX) maxX = x;
    if (y < minY) minY = y;
    if (y > maxY) maxY = y;
  }
  return maxX > 0 && minX < w && maxY > 0 && minY < h;
}

void main() {
  test('straight：100×100 画布、5 节距、无缝 → 恰好 5×5 个四边形', () {
    final polys = layoutTiles(
      width: 100, height: 100, tileWmm: 20, tileHmm: 20,
      groutMm: 0, pattern: LayoutPattern.straight, targetAcross: 5,
    );
    expect(polys.length, 25);
    for (final p in polys) {
      expect(p.points.length, 4);
    }
    // 量尺寸：单砖边长 = 100/5 = 20px（无缝）
    final first = polys.first.points;
    expect((first[1].$1 - first[0].$1).abs(), closeTo(20, 1e-6));
  });

  test('缝宽压缩砖面：节距不变，砖面变小', () {
    final polys = layoutTiles(
      width: 100, height: 100, tileWmm: 18, tileHmm: 18,
      groutMm: 2, pattern: LayoutPattern.straight, targetAcross: 5,
    );
    final first = polys.first.points;
    // 节距 20mm → 20px/节距，砖面 18px
    expect((first[1].$1 - first[0].$1).abs(), closeTo(18, 1e-6));
  });

  test('矩形砖长宽比保真（12×24）', () {
    final polys = layoutTiles(
      width: 120, height: 120, tileWmm: 305, tileHmm: 610,
      groutMm: 0, pattern: LayoutPattern.straight, targetAcross: 3,
    );
    final p = polys.first.points;
    final w = (p[1].$1 - p[0].$1).abs();
    final h = (p[2].$2 - p[1].$2).abs();
    expect(h / w, closeTo(2.0, 1e-6));
  });

  test('diagonal：顶点非轴对齐（旋转 45°）且覆盖画布', () {
    final polys = layoutTiles(
      width: 100, height: 100, tileWmm: 20, tileHmm: 20,
      groutMm: 0, pattern: LayoutPattern.diagonal, targetAcross: 5,
    );
    expect(polys.length, greaterThan(25)); // 旋转后需更大生成域
    final p = polys.first.points;
    expect((p[1].$2 - p[0].$2).abs(), greaterThan(1e-3)); // 边不再水平
    for (final poly in polys) {
      expect(intersectsCanvas(poly, 100, 100), isTrue);
    }
  });

  test('herringbone：产出 2:1 砖面且非轴对齐', () {
    final polys = layoutTiles(
      width: 100, height: 100, tileWmm: 20, tileHmm: 20,
      groutMm: 0, pattern: LayoutPattern.herringbone, targetAcross: 5,
    );
    expect(polys, isNotEmpty);
    final p = polys.first.points;
    final e1 = ((p[1].$1 - p[0].$1), (p[1].$2 - p[0].$2));
    final e2 = ((p[2].$1 - p[1].$1), (p[2].$2 - p[1].$2));
    double len((double, double) v) => (v.$1 * v.$1 + v.$2 * v.$2);
    // 邻边平方长度比 4:1（2:1 砖）
    final ratio = len(e1) > len(e2) ? len(e1) / len(e2) : len(e2) / len(e1);
    expect(ratio, closeTo(4.0, 1e-6));
    expect((p[1].$2 - p[0].$2).abs(), greaterThan(1e-3));
  });

  test('minGroutPx 保底可见缝：真实比例窄缝在小画布上放大到可见', () {
    // 12"×12" 砖（约 306.4mm）、1/16" 缝（约 1.6mm），84dp 预览画布，
    // 不加 minGroutPx 时缝宽在 84px 画布上是亚像素、几乎不可辨。
    final polys = layoutTiles(
      width: 84,
      height: 84,
      tileWmm: 306.4,
      tileHmm: 306.4,
      groutMm: 1.6,
      pattern: LayoutPattern.straight,
      targetAcross: 5,
      minGroutPx: 1.0,
    );
    expect(polys.length, 25);
    // 相邻两片砖（同一行）之间的可见缝隙 = 右邻砖左边 x - 本砖右边 x。
    final first = polys[0].points; // 第一行第一列
    final second = polys[1].points; // 第一行第二列
    final gap = second[0].$1 - first[1].$1;
    // 浮点误差容忍：语义是「≥1.0px」，允许亚 ns 级舍入噪声。
    expect(gap, greaterThanOrEqualTo(1.0 - 1e-6));
  });

  test('minGroutPx 不改变节距：砖面收窄的量正好等于缝隙放大的量', () {
    final withoutMin = layoutTiles(
      width: 84, height: 84, tileWmm: 306.4, tileHmm: 306.4,
      groutMm: 1.6, pattern: LayoutPattern.straight, targetAcross: 5,
    );
    final withMin = layoutTiles(
      width: 84, height: 84, tileWmm: 306.4, tileHmm: 306.4,
      groutMm: 1.6, pattern: LayoutPattern.straight, targetAcross: 5,
      minGroutPx: 1.0,
    );
    // 节距（相邻两砖同一顶点间距）不受 minGroutPx 影响
    final pitchWithout = withoutMin[1].points[0].$1 - withoutMin[0].points[0].$1;
    final pitchWith = withMin[1].points[0].$1 - withMin[0].points[0].$1;
    expect(pitchWith, closeTo(pitchWithout, 1e-6));
  });

  test('groutMm 为 0 时 minGroutPx 不生效，砖面仍满节距（无缝=真无缝）', () {
    final polys = layoutTiles(
      width: 100, height: 100, tileWmm: 20, tileHmm: 20,
      groutMm: 0, pattern: LayoutPattern.straight, targetAcross: 5,
      minGroutPx: 5.0,
    );
    final first = polys.first.points;
    // 无缝：砖面边长仍是整节距 20px，未被 minGroutPx 压缩
    expect((first[1].$1 - first[0].$1).abs(), closeTo(20, 1e-6));
    // 相邻两砖之间没有缝隙
    final second = polys[1].points;
    expect(second[0].$1 - first[1].$1, closeTo(0, 1e-6));
  });

  test('custom 按 straight 绘制；非法入参返回空', () {
    final custom = layoutTiles(
      width: 100, height: 100, tileWmm: 20, tileHmm: 20,
      groutMm: 0, pattern: LayoutPattern.custom, targetAcross: 5,
    );
    expect(custom.length, 25);
    expect(
      layoutTiles(
        width: 0, height: 100, tileWmm: 20, tileHmm: 20,
        groutMm: 0, pattern: LayoutPattern.straight,
      ),
      isEmpty,
    );
  });
}
