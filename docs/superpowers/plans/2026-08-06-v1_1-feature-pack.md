# v1.1 功能包实现计划（4.2 拒审重提）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 TileMath 增加材料估算、铺贴预览、图片分享、iPad 支持，以 1.1.0+7 重新提交 App Store 审核。

**Architecture:** 沿现有分层扩展——`domain/` 加两个纯函数模块（材料计算、铺贴几何），`state/CalculatorController` 加材料参数与派生结果，UI 层加 Materials 区块、图案卡选择器、结果卡预览/材料行、Canvas 离屏分享渲染。历史记录向前兼容（缺字段给默认）。

**Tech Stack:** Flutter（fvm 固定 3.44.8）、provider、shared_preferences；新增 share_plus、path_provider（均本地插件，无网络）。

**Spec:** `docs/superpowers/specs/2026-08-06-v1_1-feature-pack-design.md`　**设计稿:** Claude Design「Tile Calculator」→ v1.1 Feature Pack 页（t10）

## Global Constraints

- 一切 Flutter 命令用 `fvm flutter ...`（工作目录 `tilemath/`），禁止动全局 Flutter。
- 改任何 `lib/l10n/*.arb` 后必须 `fvm flutter gen-l10n`；改 `app_zh.arb` 后还要重跑 `tool/fonts/subset_noto_sc.sh`。
- 每个任务提交前该任务的测试必须全绿；最终任务跑全量 `fvm flutter analyze` + `fvm flutter test`。
- UI/布局测试要写量尺寸、计次数的断言（findsOneWidget 抓不住布局缺陷——项目 CLAUDE.md 硬规则）。
- 注释中文；数字、单位、尺寸表达式恒 LTR 西文数字；英制分数用真撇号 ′ ″（U+2032/U+2033）。
- 新依赖仅允许 `share_plus`、`path_provider`。
- git 仅本地 commit，不 push；commit 信息用仓库惯例（`feat:` / `fix:` / `refactor:` 中文描述）。
- 材料量是估算：UI 免责句必须随材料行显示。

---

### Task 1: 材料估算 domain 模块

**Files:**
- Modify: `lib/domain/tile_calculation.dart:83`（`_ceilGuarded` 提升为公开 `ceilGuarded`，3 处调用点同步改名）
- Create: `lib/domain/materials_calculation.dart`
- Test: `test/domain/materials_calculation_test.dart`

**Interfaces:**
- Consumes: `Length`（`lib/domain/length.dart`）、`ceilGuarded`（本任务从 `tile_calculation.dart` 提升）
- Produces:
  - `enum Trowel { vNotch316, square14, notch1438, square12 }`，成员带 `double coverageSqFtPer50Lb`、`double coverageSqMPer20Kg`、`String label`
  - `Trowel recommendTrowel(Length tileWidth, Length tileHeight)`
  - `class MaterialsInput { Length tileWidth, tileHeight, grout, tileThickness; Length? jointDepth; Trowel? trowel; double netAreaSqM; double wasteRate; }`
  - `class MaterialsResult { double groutKg; double get groutLb; int thinsetBags50Lb; int thinsetBags20Kg; Trowel trowel; Length jointDepth; }`
  - `MaterialsResult calculateMaterials(MaterialsInput input)`

- [ ] **Step 1: 写失败测试**

```dart
// test/domain/materials_calculation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/length.dart';
import 'package:tilemath/domain/materials_calculation.dart';

/// 设计稿 10a 黄金用例：净面积 129.3333 ft²（12.01555 m²）、12×12″ 砖、
/// 1/16″ 缝、5/16″ 厚、直铺 10% 损耗。
/// 手算：(304.8+304.8)/(304.8×304.8)×7.9375×1.5875×1.8×12.01555×1.1 ≈ 1.967 kg
MaterialsInput goldenInput({Length? jointDepth, Trowel? trowel}) => MaterialsInput(
      tileWidth: Length.ofInches(12),
      tileHeight: Length.ofInches(12),
      grout: Length.imperial(sixteenths: 1),
      tileThickness: Length.imperial(sixteenths: 5),
      jointDepth: jointDepth,
      trowel: trowel,
      netAreaSqM: 129.3333 * 0.3048 * 0.3048,
      wasteRate: 0.10,
    );

void main() {
  group('填缝剂', () {
    test('黄金用例 ≈1.967 kg / 4.34 lb', () {
      final r = calculateMaterials(goldenInput());
      expect(r.groutKg, closeTo(1.967, 0.005));
      expect(r.groutLb, closeTo(r.groutKg * 2.20462, 1e-9));
    });
    test('缝宽 0 → 0 kg', () {
      final input = MaterialsInput(
        tileWidth: Length.ofInches(12),
        tileHeight: Length.ofInches(12),
        grout: Length.ofMm(0),
        tileThickness: Length.ofMm(8),
        jointDepth: null,
        trowel: null,
        netAreaSqM: 10,
        wasteRate: 0.10,
      );
      expect(calculateMaterials(input).groutKg, 0);
    });
    test('缝深默认跟随砖厚，超过砖厚被 clamp', () {
      final follow = calculateMaterials(goldenInput());
      expect(follow.jointDepth.mm, closeTo(7.9375, 1e-9));
      final over = calculateMaterials(goldenInput(jointDepth: Length.ofMm(20)));
      expect(over.jointDepth.mm, closeTo(7.9375, 1e-9)); // clamp 到砖厚
      final under = calculateMaterials(goldenInput(jointDepth: Length.ofMm(4)));
      expect(under.groutKg, closeTo(1.967 * 4 / 7.9375, 0.005));
    });
  });

  group('胶粘剂', () {
    test('黄金用例 Auto → 1/4″×3/8″ → 142.27 ft² / 60 = 3 袋（50 lb）', () {
      final r = calculateMaterials(goldenInput());
      expect(r.trowel, Trowel.notch1438);
      expect(r.thinsetBags50Lb, 3);
      // 公制袋规：13.217 m² / 4.9 = 2.697 → 3 袋
      expect(r.thinsetBags20Kg, 3);
    });
    test('手动选大齿档覆盖率变小', () {
      final r = calculateMaterials(goldenInput(trowel: Trowel.square12));
      expect(r.trowel, Trowel.square12);
      expect(r.thinsetBags50Lb, 4); // 142.27 / 45 = 3.16 → 4
    });
    test('净面积 0 → 全 0', () {
      final input = MaterialsInput(
        tileWidth: Length.ofInches(12),
        tileHeight: Length.ofInches(12),
        grout: Length.imperial(sixteenths: 1),
        tileThickness: Length.ofMm(8),
        jointDepth: null,
        trowel: null,
        netAreaSqM: 0,
        wasteRate: 0.10,
      );
      final r = calculateMaterials(input);
      expect(r.groutKg, 0);
      expect(r.thinsetBags50Lb, 0);
      expect(r.thinsetBags20Kg, 0);
    });
  });

  group('Auto 镘刀档位边界（max 边判定）', () {
    Trowel rec(double wMm, double hMm) =>
        recommendTrowel(Length.ofMm(wMm), Length.ofMm(hMm));
    test('≤100mm → 3/16″ V', () {
      expect(rec(100, 50), Trowel.vNotch316);
    });
    test('100–220mm → 1/4″×1/4″', () {
      expect(rec(101, 50), Trowel.square14);
      expect(rec(152, 152), Trowel.square14); // 6×6″
      expect(rec(220, 100), Trowel.square14);
    });
    test('220–420mm → 1/4″×3/8″', () {
      expect(rec(221, 100), Trowel.notch1438);
      expect(rec(305, 305), Trowel.notch1438); // 12×12″
      expect(rec(420, 100), Trowel.notch1438);
    });
    test('>420mm → 1/2″×1/2″', () {
      expect(rec(421, 100), Trowel.square12);
      expect(rec(305, 610), Trowel.square12); // 12×24″ 按 max 边
    });
  });

  group('参数断言', () {
    test('砖厚 ≤0 抛 ArgumentError', () {
      expect(
        () => calculateMaterials(MaterialsInput(
          tileWidth: Length.ofInches(12),
          tileHeight: Length.ofInches(12),
          grout: Length.ofMm(2),
          tileThickness: Length.ofMm(0),
          jointDepth: null,
          trowel: null,
          netAreaSqM: 10,
          wasteRate: 0.10,
        )),
        throwsArgumentError,
      );
    });
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd /Users/chuxiaoshan/project/indev/tile/tilemath && fvm flutter test test/domain/materials_calculation_test.dart`
Expected: FAIL（`materials_calculation.dart` 不存在，编译错误）

- [ ] **Step 3: 提升 ceilGuarded 并实现模块**

`lib/domain/tile_calculation.dart` 中：

```dart
/// 带浮点护栏的向上取整：120.000000000001 不得进位成 121。
int ceilGuarded(double value) => (value - 1e-9).ceil();
```

（删掉原 `_ceilGuarded`，文件内 3 处调用 `_ceilGuarded(` 改为 `ceilGuarded(`。）

`lib/domain/materials_calculation.dart` 全文：

```dart
import 'dart:math' as math;

import 'length.dart';
import 'tile_calculation.dart';

/// 镘刀档位与每袋覆盖面积（spec §2.2 基准值，来源为厂商覆盖表典型值）。
/// label 恒 LTR 分数英寸表达，不进 l10n。
enum Trowel {
  vNotch316(90, 7.4, '3/16″ V'),
  square14(80, 6.5, '1/4″×1/4″'),
  notch1438(60, 4.9, '1/4″×3/8″'),
  square12(45, 3.7, '1/2″×1/2″');

  /// 每 50 lb 袋覆盖 ft²（英制显示用）。
  final double coverageSqFtPer50Lb;

  /// 每 20 kg 袋覆盖 m²（公制显示用）。
  final double coverageSqMPer20Kg;

  final String label;

  const Trowel(this.coverageSqFtPer50Lb, this.coverageSqMPer20Kg, this.label);
}

/// Auto 档：按砖的长边推荐（spec §2.2）。
Trowel recommendTrowel(Length tileWidth, Length tileHeight) {
  final maxEdge = math.max(tileWidth.mm, tileHeight.mm);
  if (maxEdge <= 100) return Trowel.vNotch316;
  if (maxEdge <= 220) return Trowel.square14;
  if (maxEdge <= 420) return Trowel.notch1438;
  return Trowel.square12;
}

class MaterialsInput {
  final Length tileWidth;
  final Length tileHeight;

  /// 缝宽（复用主计算的 grout 输入）。
  final Length grout;
  final Length tileThickness;

  /// null = 跟随砖厚；有效值超过砖厚时按砖厚 clamp。
  final Length? jointDepth;

  /// null = Auto（按砖尺寸推荐）。
  final Trowel? trowel;

  final double netAreaSqM;

  /// 与铺法损耗一致，材料同损耗（spec §2.1）。合法域 0–0.30。
  final double wasteRate;

  MaterialsInput({
    required this.tileWidth,
    required this.tileHeight,
    required this.grout,
    required this.tileThickness,
    required this.jointDepth,
    required this.trowel,
    required this.netAreaSqM,
    required this.wasteRate,
  });
}

class MaterialsResult {
  final double groutKg;

  /// 生效档位（Auto 解析后）与生效缝深（clamp 后），UI 回显用。
  final Trowel trowel;
  final Length jointDepth;

  final int thinsetBags50Lb;
  final int thinsetBags20Kg;

  const MaterialsResult({
    required this.groutKg,
    required this.trowel,
    required this.jointDepth,
    required this.thinsetBags50Lb,
    required this.thinsetBags20Kg,
  });

  double get groutLb => groutKg * 2.20462;
}

/// 水泥基填缝剂典型密度 kg/L（spec §2.1，估算值）。
const _groutDensityKgPerL = 1.8;
const _sqMPerSqFt = 0.3048 * 0.3048;

MaterialsResult calculateMaterials(MaterialsInput input) {
  if (input.tileWidth.mm <= 0 || input.tileHeight.mm <= 0) {
    throw ArgumentError('瓷砖尺寸必须大于 0');
  }
  if (input.tileThickness.mm <= 0) {
    throw ArgumentError('瓷砖厚度必须大于 0');
  }
  if (input.wasteRate < 0 || input.wasteRate > 0.30) {
    throw ArgumentError('损耗率合法域为 0–0.30，实际 ${input.wasteRate}');
  }

  final trowel =
      input.trowel ?? recommendTrowel(input.tileWidth, input.tileHeight);
  final jointDepth = Length.ofMm(
    math.min(input.jointDepth?.mm ?? input.tileThickness.mm,
        input.tileThickness.mm),
  );

  final areaWithWaste = math.max(0.0, input.netAreaSqM) * (1 + input.wasteRate);
  if (areaWithWaste <= 0) {
    return MaterialsResult(
      groutKg: 0,
      trowel: trowel,
      jointDepth: jointDepth,
      thinsetBags50Lb: 0,
      thinsetBags20Kg: 0,
    );
  }

  // 填缝剂 kg/m² = (L+W)/(L×W) × 缝深 × 缝宽 × 密度（各长度 mm，spec §2.1）
  final l = input.tileWidth.mm;
  final w = input.tileHeight.mm;
  final groutKgPerSqM =
      (l + w) / (l * w) * jointDepth.mm * input.grout.mm * _groutDensityKgPerL;
  final groutKg = groutKgPerSqM * areaWithWaste;

  final bags50Lb =
      ceilGuarded(areaWithWaste / _sqMPerSqFt / trowel.coverageSqFtPer50Lb);
  final bags20Kg = ceilGuarded(areaWithWaste / trowel.coverageSqMPer20Kg);

  return MaterialsResult(
    groutKg: groutKg,
    trowel: trowel,
    jointDepth: jointDepth,
    thinsetBags50Lb: bags50Lb,
    thinsetBags20Kg: bags20Kg,
  );
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `fvm flutter test test/domain/materials_calculation_test.dart test/domain/tile_calculation_test.dart`
Expected: 全部 PASS（含原 tile_calculation 回归——改名不改行为）

- [ ] **Step 5: Commit**

```bash
git add lib/domain/tile_calculation.dart lib/domain/materials_calculation.dart test/domain/materials_calculation_test.dart
git commit -m "feat: 材料估算 domain 模块（填缝剂/胶粘剂/镘刀 Auto 档）"
```

---

### Task 2: 铺贴几何 domain 模块

**Files:**
- Create: `lib/domain/pattern_geometry.dart`
- Test: `test/domain/pattern_geometry_test.dart`

**Interfaces:**
- Consumes: `LayoutPattern`（`lib/domain/tile_calculation.dart`）
- Produces:
  - `class TilePoly { final List<(double, double)> points; }`（顶点为画布 px 坐标，首尾不重复）
  - `List<TilePoly> layoutTiles({required double width, required double height, required double tileWmm, required double tileHmm, required double groutMm, required LayoutPattern pattern, double targetAcross = 5})`
- 行为约定：straight/custom 为正铺网格；diagonal 为整体旋转 45° 的网格；herringbone 为 2:1 错缝砖旋转 45°（预览示意，spec §2.3；砖非正方形时用实际长短边）。比例真实：横向约 targetAcross 个铺贴节距。

- [ ] **Step 1: 写失败测试**

```dart
// test/domain/pattern_geometry_test.dart
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
```

- [ ] **Step 2: 跑测试确认失败**

Run: `fvm flutter test test/domain/pattern_geometry_test.dart`
Expected: FAIL（文件不存在）

- [ ] **Step 3: 实现**

`lib/domain/pattern_geometry.dart` 全文：

```dart
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
}) {
  if (width <= 0 || height <= 0 || tileWmm <= 0 || tileHmm <= 0) {
    return const [];
  }
  final pitchWmm = tileWmm + groutMm;
  final scale = width / (targetAcross * pitchWmm);
  switch (pattern) {
    case LayoutPattern.straight:
    case LayoutPattern.custom:
      return _grid(width, height, tileWmm * scale, tileHmm * scale,
          groutMm * scale, angle: 0, brickOffset: false);
    case LayoutPattern.diagonal:
      return _grid(width, height, tileWmm * scale, tileHmm * scale,
          groutMm * scale, angle: math.pi / 4, brickOffset: false);
    case LayoutPattern.herringbone:
      // 2:1 砖：长边 = 2×短边（正方砖）或实际长短边（矩形砖）
      final shortPx = math.min(tileWmm, tileHmm) * scale;
      final longPx = tileWmm == tileHmm
          ? shortPx * 2
          : math.max(tileWmm, tileHmm) * scale;
      return _grid(width, height, longPx, shortPx, groutMm * scale,
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
```

- [ ] **Step 4: 跑测试确认通过**

Run: `fvm flutter test test/domain/pattern_geometry_test.dart`
Expected: 全部 PASS

- [ ] **Step 5: Commit**

```bash
git add lib/domain/pattern_geometry.dart test/domain/pattern_geometry_test.dart
git commit -m "feat: 铺贴预览几何模块（正铺/斜铺/人字示意）"
```

---

### Task 3: CalculatorController 材料状态 + 键盘接入

**Files:**
- Modify: `lib/state/calculator_controller.dart`
- Modify: `lib/ui/keyboard/tile_keyboard.dart:133-135`（公制单位键小字段判定）
- Test: `test/state/materials_state_test.dart`（新建）

**Interfaces:**
- Consumes: Task 1 的 `Trowel` / `MaterialsInput` / `MaterialsResult` / `calculateMaterials` / `recommendTrowel`
- Produces（`CalculatorController` 上）:
  - `FieldKind` 新增 `tileThickness`、`jointDepth`
  - `Length tileThickness`（默认英制 5/16″ / 公制 8mm，切单位制未动过则换默认）
  - `Length? jointDepth`（null=跟随砖厚）、`Trowel? trowel`（null=Auto）
  - `void setTrowel(Trowel? t)`
  - `MaterialsResult? get materialsResult`（`result == null` 或净面积 ≤0 时为 null；build 期读取永不抛错）

- [ ] **Step 1: 写失败测试**

```dart
// test/state/materials_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/length.dart';
import 'package:tilemath/domain/materials_calculation.dart';
import 'package:tilemath/state/calculator_controller.dart';
import 'package:tilemath/state/settings_controller.dart';

CalculatorController filledController() {
  final c = CalculatorController(UnitSystem.imperial);
  c.startEditing(const FieldId(FieldKind.areaLength, 0));
  c.keyDigit(1);
  c.keyDigit(2);
  c.keyFt();
  c.commitAndNext(); // → areaWidth
  c.keyDigit(1);
  c.keyDigit(0);
  c.keyFt();
  c.commitAndClose();
  c.setTilePreset(Length.ofInches(12), Length.ofInches(12));
  return c;
}

void main() {
  test('默认值：厚度 5/16″、缝深跟随、镘刀 Auto', () {
    final c = CalculatorController(UnitSystem.imperial);
    expect(c.tileThickness.mm, closeTo(7.9375, 1e-9));
    expect(c.jointDepth, isNull);
    expect(c.trowel, isNull);
  });

  test('公制默认厚度 8mm；已动过的厚度切单位制保留', () {
    final metric = CalculatorController(UnitSystem.metric);
    expect(metric.tileThickness.mm, closeTo(8, 1e-9));

    final c = CalculatorController(UnitSystem.imperial);
    c.startEditing(const FieldId(FieldKind.tileThickness));
    c.keyDigit(1); // 1 英寸（inchesOnly 字段）
    c.commitAndClose();
    expect(c.tileThickness.mm, closeTo(25.4, 1e-9));
    c.unitSystem = UnitSystem.metric;
    expect(c.tileThickness.mm, closeTo(25.4, 1e-9)); // 保留不重置
  });

  test('materialsResult：无结果时 null，有结果时与 domain 一致', () {
    final empty = CalculatorController(UnitSystem.imperial);
    expect(empty.materialsResult, isNull);

    final c = filledController();
    final m = c.materialsResult;
    expect(m, isNotNull);
    expect(m!.trowel, Trowel.notch1438); // 12×12 Auto
    final direct = calculateMaterials(MaterialsInput(
      tileWidth: c.tileWidth!,
      tileHeight: c.tileHeight!,
      grout: c.grout,
      tileThickness: c.tileThickness,
      jointDepth: c.jointDepth,
      trowel: c.trowel,
      netAreaSqM: c.result!.netAreaSqM,
      wasteRate: c.wasteRate,
    ));
    expect(m.groutKg, closeTo(direct.groutKg, 1e-9));
    expect(m.thinsetBags50Lb, direct.thinsetBags50Lb);
  });

  test('setTrowel 改变胶粘剂档位并通知', () {
    final c = filledController();
    var notified = 0;
    c.addListener(() => notified++);
    c.setTrowel(Trowel.square12);
    expect(notified, 1);
    expect(c.materialsResult!.trowel, Trowel.square12);
    c.setTrowel(null); // 回 Auto
    expect(c.materialsResult!.trowel, Trowel.notch1438);
  });

  test('厚度提交 0 被忽略；缝深可清空回跟随', () {
    final c = filledController();
    c.startEditing(const FieldId(FieldKind.tileThickness));
    c.keyDigit(0);
    c.commitAndClose();
    expect(c.tileThickness.mm, closeTo(7.9375, 1e-9)); // 0 无效，保留默认

    c.startEditing(const FieldId(FieldKind.jointDepth));
    c.keyDigit(4); // 4 英寸——会被 domain clamp，但字段接受
    c.commitAndClose();
    expect(c.jointDepth!.mm, closeTo(4 * 25.4, 1e-9));
    c.startEditing(const FieldId(FieldKind.jointDepth));
    c.keyClear();
    c.commitAndClose();
    expect(c.jointDepth, isNull); // 清空 = 回到跟随砖厚
  });

  test('Next 链：厚度 → 缝深 → 收起', () {
    final c = filledController();
    c.startEditing(const FieldId(FieldKind.tileThickness));
    c.commitAndNext();
    expect(c.editing, const FieldId(FieldKind.jointDepth));
    c.commitAndNext();
    expect(c.editing, isNull);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `fvm flutter test test/state/materials_state_test.dart`
Expected: FAIL（`FieldKind.tileThickness` 等未定义）

- [ ] **Step 3: 实现 controller 扩展**

`lib/state/calculator_controller.dart` 修改点（其余不动）：

```dart
// import 区新增
import '../domain/materials_calculation.dart';

// FieldKind 追加两个成员
enum FieldKind { areaLength, areaWidth, tileWidth, tileHeight, grout,
  tileThickness, jointDepth }

// 字段区（grout 附近）追加：
/// 瓷砖厚度（材料估算用），默认英制 5/16″ / 公制 8mm，同 grout 的默认策略。
late Length tileThickness;
bool _thicknessTouched = false;

/// 缝深：null = 跟随砖厚（spec §2.1）。
Length? jointDepth;

/// 镘刀：null = Auto 按砖尺寸推荐。
Trowel? trowel;

// 构造函数补一行：
CalculatorController(this._unitSystem) {
  grout = _defaultGrout(_unitSystem);
  tileThickness = _defaultThickness(_unitSystem);
}

static Length _defaultThickness(UnitSystem system) =>
    system == UnitSystem.imperial
        ? Length.imperial(sixteenths: 5)
        : Length.ofMm(8);

// unitSystem setter 中 `if (!_groutTouched) ...` 后追加：
if (!_thicknessTouched) tileThickness = _defaultThickness(system);

// result getter 之后追加：
/// 材料估算派生结果；无有效结果或净面积为 0 时为 null（材料行整体隐藏）。
/// 与 [result] 同契约：build 期读取永不抛错。
MaterialsResult? get materialsResult {
  final r = result;
  final tw = tileWidth;
  final th = tileHeight;
  if (r == null || tw == null || th == null || r.netAreaSqM <= 0) return null;
  return calculateMaterials(MaterialsInput(
    tileWidth: tw,
    tileHeight: th,
    grout: grout,
    tileThickness: tileThickness,
    jointDepth: jointDepth,
    trowel: trowel,
    netAreaSqM: r.netAreaSqM,
    wasteRate: wasteRate,
  ));
}

void setTrowel(Trowel? t) {
  trowel = t;
  notifyListeners();
}

// _metricDefaultFor 的 switch 追加分支（保持穷举）：
FieldKind.tileThickness || FieldKind.jointDepth => MetricUnit.mm,

// _commit 的清空分支 switch 追加：
case FieldKind.tileThickness:
  break; // 非空字段（有默认值），不参与清空
case FieldKind.jointDepth:
  jointDepth = null; // 清空 = 回到跟随砖厚

// _commit 的赋值分支 switch 追加：
case FieldKind.tileThickness:
  if (value.mm > 0) {
    tileThickness = value;
    _thicknessTouched = true;
  }
case FieldKind.jointDepth:
  jointDepth = value;

// _nextField 的 switch 追加（grout 分支保持返回 null 不变）：
case FieldKind.tileThickness:
  return const FieldId(FieldKind.jointDepth);
case FieldKind.jointDepth:
  return null;
```

`lib/ui/keyboard/tile_keyboard.dart` `_metricGrid` 中小字段判定改为（原 `isGrout` 一段）：

```dart
// 单位键按字段自适应：缝宽/厚度/缝深惯用 mm，两键给 cm/mm；其余维持 m/cm。
final kind = controller.editing?.kind;
final smallField = kind == FieldKind.grout ||
    kind == FieldKind.tileThickness ||
    kind == FieldKind.jointDepth;
final upperUnit = smallField ? MetricUnit.cm : MetricUnit.m;
final lowerUnit = smallField ? MetricUnit.mm : MetricUnit.cm;
```

- [ ] **Step 4: 跑测试确认通过**

Run: `fvm flutter test test/state/`
Expected: 全部 PASS（含既有 state 测试回归）

- [ ] **Step 5: Commit**

```bash
git add lib/state/calculator_controller.dart lib/ui/keyboard/tile_keyboard.dart test/state/materials_state_test.dart
git commit -m "feat: 计算控制器接入材料参数（厚度/缝深/镘刀）与派生结果"
```

---

### Task 4: 历史记录兼容

**Files:**
- Modify: `lib/history/history_entry.dart`
- Modify: `lib/state/calculator_controller.dart`（`snapshot` / `restoreFrom`）
- Test: `test/history/materials_compat_test.dart`（新建）

**Interfaces:**
- Consumes: Task 3 的 controller 字段；`Trowel`
- Produces（`HistoryEntry` 上）: `double tileThicknessMm`、`double? jointDepthMm`、`String? trowelName`；JSON 键 `'thick'` / `'jointDepth'` / `'trowel'`；老 JSON 缺字段 → 厚度 7.9375（5/16″）、缝深 null、镘刀 null

- [ ] **Step 1: 写失败测试**

```dart
// test/history/materials_compat_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/length.dart';
import 'package:tilemath/domain/materials_calculation.dart';
import 'package:tilemath/history/history_entry.dart';
import 'package:tilemath/state/calculator_controller.dart';
import 'package:tilemath/state/settings_controller.dart';

CalculatorController filledController() {
  final c = CalculatorController(UnitSystem.imperial);
  c.startEditing(const FieldId(FieldKind.areaLength, 0));
  c.keyDigit(1);
  c.keyDigit(2);
  c.keyFt();
  c.commitAndNext();
  c.keyDigit(1);
  c.keyDigit(0);
  c.keyFt();
  c.commitAndClose();
  c.setTilePreset(Length.ofInches(12), Length.ofInches(12));
  return c;
}

void main() {
  test('snapshot 携带材料参数，JSON 往返一致', () {
    final c = filledController();
    c.setTrowel(Trowel.square12);
    c.startEditing(const FieldId(FieldKind.jointDepth));
    c.keyDigit(4);
    c.commitAndClose();

    final entry = c.snapshot()!;
    expect(entry.tileThicknessMm, closeTo(7.9375, 1e-9));
    expect(entry.jointDepthMm, closeTo(4 * 25.4, 1e-9));
    expect(entry.trowelName, 'square12');

    final back = HistoryEntry.fromJson(entry.toJson());
    expect(back.tileThicknessMm, entry.tileThicknessMm);
    expect(back.jointDepthMm, entry.jointDepthMm);
    expect(back.trowelName, entry.trowelName);
    expect(back.sameInputs(entry), isTrue);
  });

  test('老版本 JSON（无材料字段）可读并给默认', () {
    final c = filledController();
    final json = c.snapshot()!.toJson()
      ..remove('thick')
      ..remove('jointDepth')
      ..remove('trowel');
    final legacy = HistoryEntry.fromJson(json);
    expect(legacy.tileThicknessMm, closeTo(7.9375, 1e-9));
    expect(legacy.jointDepthMm, isNull);
    expect(legacy.trowelName, isNull);
  });

  test('材料参数不同 → sameInputs false（去重不吞掉参数变化）', () {
    final c = filledController();
    final a = c.snapshot()!;
    c.setTrowel(Trowel.square12);
    final b = c.snapshot()!;
    expect(a.sameInputs(b), isFalse);
  });

  test('restoreFrom 回填材料参数；未知 trowel 名回退 Auto', () {
    final c = filledController();
    c.setTrowel(Trowel.square12);
    final entry = c.snapshot()!;

    final fresh = CalculatorController(UnitSystem.imperial);
    fresh.restoreFrom(entry);
    expect(fresh.tileThickness.mm, closeTo(7.9375, 1e-9));
    expect(fresh.trowel, Trowel.square12);

    final unknown = HistoryEntry.fromJson(
      entry.toJson()..['trowel'] = 'laserTrowel9000',
    );
    fresh.restoreFrom(unknown);
    expect(fresh.trowel, isNull); // 回退 Auto
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `fvm flutter test test/history/materials_compat_test.dart`
Expected: FAIL（`tileThicknessMm` 未定义）

- [ ] **Step 3: 实现**

`lib/history/history_entry.dart`：

```dart
// 字段区（groutMm 之后）追加：
/// 材料参数（v1.1 追加；老记录缺省见 fromJson）。
final double tileThicknessMm;
final double? jointDepthMm;

/// Trowel.name 序列化形态，向前兼容未知值；null = Auto。
final String? trowelName;

// 构造函数参数追加（required this.tileThicknessMm, required this.jointDepthMm,
// required this.trowelName）。

// sameInputs 的首个条件组追加三行比较：
    tileThicknessMm != other.tileThicknessMm ||
    jointDepthMm != other.jointDepthMm ||
    trowelName != other.trowelName ||

// toJson 追加：
'thick': tileThicknessMm,
'jointDepth': jointDepthMm,
'trowel': trowelName,

// fromJson 追加（老 JSON 缺字段给默认 5/16″）：
tileThicknessMm: (json['thick'] as num?)?.toDouble() ?? 7.9375,
jointDepthMm: (json['jointDepth'] as num?)?.toDouble(),
trowelName: json['trowel'] as String?,
```

`lib/state/calculator_controller.dart`：

```dart
// snapshot() 的 HistoryEntry(...) 里追加：
tileThicknessMm: tileThickness.mm,
jointDepthMm: jointDepth?.mm,
trowelName: trowel?.name,

// restoreFrom() 的 `_groutTouched = true;` 之后追加：
tileThickness = Length.ofMm(entry.tileThicknessMm);
_thicknessTouched = true;
jointDepth =
    entry.jointDepthMm == null ? null : Length.ofMm(entry.jointDepthMm!);
trowel = Trowel.values
    .where((t) => t.name == entry.trowelName)
    .firstOrNull; // 未知名回退 Auto（null）
```

- [ ] **Step 4: 跑测试确认通过**

Run: `fvm flutter test test/history/ test/state/`
Expected: 全部 PASS（既有 history 测试若因构造函数新增 required 参数编译失败，在测试里补 `tileThicknessMm: 7.9375, jointDepthMm: null, trowelName: null`——行为不变的机械修补）

- [ ] **Step 5: Commit**

```bash
git add lib/history/history_entry.dart lib/state/calculator_controller.dart test/history/
git commit -m "feat: 历史记录携带材料参数并向前兼容老数据"
```

---

### Task 5: 三语文案

**Files:**
- Modify: `lib/l10n/app_en.arb`、`lib/l10n/app_zh.arb`、`lib/l10n/app_ar.arb`
- 生成物: `fvm flutter gen-l10n` + `tool/fonts/subset_noto_sc.sh`

**Interfaces:**
- Produces（`AppLocalizations` getter/方法，后续 UI 任务全部依赖）:
  `sectionMaterials`、`materialsDefaults`、`tileThickness`、`jointDepth`、`jointDepthFollows`、`trowelLabel`、`trowelAuto`、`trowelAutoCaption`、`groutNeeded`、`thinsetNeeded`、`thinsetBagsLine(int bags, String spec)`、`materialsDisclaimer`、`shareResult`、`shareFailed`、`shareCardFooter`、`previewCaption(String pattern, String grout)`

- [ ] **Step 1: 三个 arb 各追加同名键**

`app_en.arb`（追加到文件末尾大括号内，注意补前一行逗号）：

```json
"sectionMaterials": "Materials",
"materialsDefaults": "Defaults applied",
"tileThickness": "Tile thickness",
"jointDepth": "Joint depth",
"jointDepthFollows": "= thickness",
"trowelLabel": "Trowel",
"trowelAuto": "Auto",
"trowelAutoCaption": "Auto picks a notch by tile size.",
"groutNeeded": "Grout",
"thinsetNeeded": "Thinset",
"thinsetBagsLine": "{bags, plural, one{≈ {bags} bag · {spec}} other{≈ {bags} bags · {spec}}}",
"@thinsetBagsLine": {
  "placeholders": {
    "bags": {"type": "int"},
    "spec": {"type": "String"}
  }
},
"materialsDisclaimer": "Material amounts are estimates — follow your product's coverage chart.",
"shareResult": "Share",
"shareFailed": "Couldn't share. Please try again.",
"shareCardFooter": "TileMath — tile calculator with a fraction-inch keyboard",
"previewCaption": "{pattern} · {grout} grout",
"@previewCaption": {
  "placeholders": {
    "pattern": {"type": "String"},
    "grout": {"type": "String"}
  }
}
```

`app_zh.arb`：

```json
"sectionMaterials": "辅料",
"materialsDefaults": "已按默认值计算",
"tileThickness": "瓷砖厚度",
"jointDepth": "缝深",
"jointDepthFollows": "= 砖厚",
"trowelLabel": "镘刀",
"trowelAuto": "自动",
"trowelAutoCaption": "自动按砖尺寸选齿号。",
"groutNeeded": "填缝剂",
"thinsetNeeded": "胶粘剂",
"thinsetBagsLine": "{bags, plural, other{≈ {bags} 袋 · {spec}}}",
"materialsDisclaimer": "用量为估算，请以所购产品的覆盖率表为准。",
"shareResult": "分享",
"shareFailed": "分享失败，请重试。",
"shareCardFooter": "TileMath — 带分数英寸键盘的瓷砖计算器",
"previewCaption": "{pattern} · 缝 {grout}"
```

`app_ar.arb`：

```json
"sectionMaterials": "مواد التركيب",
"materialsDefaults": "قيم افتراضية مطبّقة",
"tileThickness": "سماكة البلاطة",
"jointDepth": "عمق الفاصل",
"jointDepthFollows": "= السماكة",
"trowelLabel": "المالج",
"trowelAuto": "تلقائي",
"trowelAutoCaption": "يُختار حجم السن تلقائيًا حسب مقاس البلاطة.",
"groutNeeded": "الروبة",
"thinsetNeeded": "اللاصق",
"thinsetBagsLine": "{bags, plural, one{≈ كيس واحد · {spec}} two{≈ كيسان · {spec}} few{≈ {bags} أكياس · {spec}} many{≈ {bags} كيسًا · {spec}} other{≈ {bags} كيس · {spec}}}",
"materialsDisclaimer": "الكميات تقديرية — اتبع جدول التغطية الخاص بمنتجك.",
"shareResult": "مشاركة",
"shareFailed": "تعذّرت المشاركة. حاول مرة أخرى.",
"shareCardFooter": "TileMath — حاسبة بلاط بلوحة مفاتيح كسور البوصة",
"previewCaption": "{pattern} · فاصل {grout}"
```

- [ ] **Step 2: 生成本地化代码 + 中文字体子集**

```bash
fvm flutter gen-l10n
tool/fonts/subset_noto_sc.sh
```

Expected: gen-l10n 无报错；`lib/l10n/app_localizations*.dart` 出现新 getter；字体子集脚本重生成 `assets/fonts/NotoSansSC-*-subset.ttf`

- [ ] **Step 3: 编译验证**

Run: `fvm flutter analyze`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/ assets/fonts/
git commit -m "feat: v1.1 三语文案（辅料/分享/预览 caption）"
```

---

### Task 6: ValueField 抽取（无行为重构）

**Files:**
- Create: `lib/ui/value_field.dart`
- Modify: `lib/ui/home_page.dart`（删除 `_ValueField`/`_ValueFieldState`，改用 import；`_AreaRow`/`_TileSection` 内 `_ValueField(` 全部改 `ValueField(`）

**Interfaces:**
- Produces: `class ValueField extends StatefulWidget`——构造参数与原 `_ValueField` 完全一致（`calc`、`id`、`label`、`value`、`metricUnit`、`accent`），Task 8 的 Materials 区块复用

- [ ] **Step 1: 机械搬移**

把 `lib/ui/home_page.dart` 的 `_ValueField` + `_ValueFieldState` 两个类整体剪切到新文件 `lib/ui/value_field.dart`，类名去下划线（`ValueField` / `_ValueFieldState`），文件头补齐原类用到的 import：

```dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../domain/length.dart';
import '../keyboard/metric_editor.dart';
import '../state/calculator_controller.dart';
import '../state/settings_controller.dart';
import '../theme/app_dimens.dart';
import 'format.dart';
```

`home_page.dart` 加 `import 'value_field.dart';`，5 处 `_ValueField(` → `ValueField(`（`_AreaRow` 2 处、`_TileSection` 3 处），并清掉 home_page 里因搬移而不再使用的 import（`flutter/rendering.dart` 若仅 `_reveal` 在用）。

- [ ] **Step 2: 全量回归**

Run: `fvm flutter analyze && fvm flutter test`
Expected: analyze 无 issue；全部测试 PASS（纯搬移不改行为）

- [ ] **Step 3: Commit**

```bash
git add lib/ui/value_field.dart lib/ui/home_page.dart
git commit -m "refactor: ValueField 抽为独立文件供辅料区块复用"
```

---

### Task 7: 铺贴预览组件

**Files:**
- Create: `lib/ui/pattern_preview.dart`
- Test: `test/ui/pattern_preview_test.dart`

**Interfaces:**
- Consumes: Task 2 `layoutTiles` / `TilePoly`
- Produces: `class PatternPreview extends StatelessWidget`，构造参数 `{required Length tileWidth, required Length tileHeight, required Length grout, required LayoutPattern pattern, required double size}`——正方形 `size×size`。砖面用**品牌青 `primaryContainer`**（2026-08-06 拍板：视觉增强只用现有青色系、不引入新色；浅 #CBEEFF / 深 #004961 由主题自动给出），缝色 `surfaceContainerLow`，预览不用灰阶

- [ ] **Step 1: 写失败测试**

```dart
// test/ui/pattern_preview_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/length.dart';
import 'package:tilemath/domain/tile_calculation.dart';
import 'package:tilemath/ui/pattern_preview.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('按 size 渲染正方形 CustomPaint（量尺寸）', (tester) async {
    await tester.pumpWidget(host(PatternPreview(
      tileWidth: Length.ofInches(12),
      tileHeight: Length.ofInches(12),
      grout: Length.imperial(sixteenths: 1),
      pattern: LayoutPattern.straight,
      size: 84,
    )));
    final paint = find.byType(CustomPaint).last;
    expect(tester.getSize(paint), const Size(84, 84));
  });

  testWidgets('参数变化触发重绘（shouldRepaint）', (tester) async {
    final painterA = PatternPreviewPainter(
      tileWmm: 300, tileHmm: 300, groutMm: 2,
      pattern: LayoutPattern.straight,
      tileColor: const Color(0xFFD7D3D3),
      groutColor: const Color(0xFFEAE9E9),
    );
    final painterB = PatternPreviewPainter(
      tileWmm: 300, tileHmm: 300, groutMm: 4, // 缝宽变了
      pattern: LayoutPattern.straight,
      tileColor: const Color(0xFFD7D3D3),
      groutColor: const Color(0xFFEAE9E9),
    );
    expect(painterB.shouldRepaint(painterA), isTrue);
    expect(painterA.shouldRepaint(painterA), isFalse);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `fvm flutter test test/ui/pattern_preview_test.dart`
Expected: FAIL（文件不存在）

- [ ] **Step 3: 实现**

`lib/ui/pattern_preview.dart` 全文：

```dart
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
```

（`AppDimens.radius1` 若不存在则在 `lib/theme/app_dimens.dart` 补 `static const radius1 = 1.0;`——token 表 §5「1dp 迷你预览砖块」。）

- [ ] **Step 4: 跑测试确认通过**

Run: `fvm flutter test test/ui/pattern_preview_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/ui/pattern_preview.dart lib/theme/app_dimens.dart test/ui/pattern_preview_test.dart
git commit -m "feat: 迷你铺贴预览组件（CustomPaint + 几何模块）"
```

---

### Task 8: 铺法图案卡选择器

**Files:**
- Modify: `lib/ui/home_page.dart:633-729`（`_PatternSelector` 重写选择控件，滑块与损耗行保留）
- Test: `test/ui/pattern_cards_test.dart`（新建）

**Interfaces:**
- Consumes: `calc.pattern` / `calc.setPattern` / `calc.customWastePct`（不变）
- Produces: 视觉升级，无新公开 API。四张卡等宽 Grid，卡内：20dp 图案缩略（`_PatternGlyphPainter`）+ 名称 + 损耗%

- [ ] **Step 1: 写失败测试**

先建共用 harness `test/ui/test_harness.dart`（若 `test/ui/home_flow_test.dart` 已有等价组装函数，抄它的 provider 组装方式为准——尤其 `SettingsController`/`HistoryController` 的构造签名）：

```dart
// test/ui/test_harness.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilemath/history/history_controller.dart';
import 'package:tilemath/l10n/app_localizations.dart';
import 'package:tilemath/state/calculator_controller.dart';
import 'package:tilemath/state/settings_controller.dart';
import 'package:tilemath/ui/home_page.dart';

Future<CalculatorController> pumpHome(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsController(prefs);
  final calc = CalculatorController(settings.unitSystem);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: calc),
      ChangeNotifierProvider(create: (_) => HistoryController(prefs)),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomePage(),
    ),
  ));
  return calc;
}
```

```dart
// test/ui/pattern_cards_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/tile_calculation.dart';
import 'test_harness.dart';

void main() {
  testWidgets('四张图案卡且高度一致（量尺寸）', (tester) async {
    await pumpHome(tester);
    final cards = find.byKey(const ValueKey('pattern-card-straight'))
        .evaluate()
        .toList();
    expect(cards, hasLength(1));
    final keys = ['straight', 'diagonal', 'herringbone', 'custom'];
    final heights = <double>{};
    for (final k in keys) {
      final f = find.byKey(ValueKey('pattern-card-$k'));
      expect(f, findsOneWidget);
      heights.add(tester.getSize(f).height);
    }
    expect(heights, hasLength(1)); // 四卡等高不跳动
  });

  testWidgets('点卡切换铺法；custom 出滑块', (tester) async {
    final calc = await pumpHome(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('pattern-card-herringbone')));
    await tester.tap(find.byKey(const ValueKey('pattern-card-herringbone')));
    await tester.pump();
    expect(calc.pattern, LayoutPattern.herringbone);
    expect(find.byType(Slider), findsNothing);

    await tester.tap(find.byKey(const ValueKey('pattern-card-custom')));
    await tester.pump();
    expect(calc.pattern, LayoutPattern.custom);
    expect(find.byType(Slider), findsOneWidget);
  });
}
```


- [ ] **Step 2: 跑测试确认失败**

Run: `fvm flutter test test/ui/pattern_cards_test.dart`
Expected: FAIL（找不到 `pattern-card-*` key）

- [ ] **Step 3: 重写 _PatternSelector 的选择控件**

`_PatternSelector.build` 中 `SizedBox(width: double.infinity, child: SegmentedButton...)` 整段替换为：

```dart
LayoutBuilder(builder: (context, constraints) {
  final cardW =
      (constraints.maxWidth - 3 * AppDimens.space8) / 4;
  return Row(
    children: [
      for (final p in LayoutPattern.values) ...[
        if (p != LayoutPattern.values.first)
          const SizedBox(width: AppDimens.space8),
        SizedBox(
          width: cardW,
          child: _PatternCard(
            pattern: p,
            name: nameOf(p),
            pct: pctOf(p),
            selected: calc.pattern == p,
            onTap: () => calc.setPattern(p),
          ),
        ),
      ],
    ],
  );
}),
```

`home_page.dart` 追加两个私有类（`_PatternSelector` 之后）：

```dart
/// 铺法图案卡（设计稿 10a/1a）：缩略图 + 名称 + 损耗%，选中态 secondary
/// 描边 + primaryContainer 底。名称行 FittedBox 缩字不换行，四卡恒等高。
class _PatternCard extends StatelessWidget {
  final LayoutPattern pattern;
  final String name;
  final int pct;
  final bool selected;
  final VoidCallback onTap;

  const _PatternCard({
    required this.pattern,
    required this.name,
    required this.pct,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppDimens.radius2),
      child: InkWell(
        key: ValueKey('pattern-card-${pattern.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radius2),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space4,
            vertical: AppDimens.space8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radius2),
            border: Border.all(
              color: selected ? scheme.secondary : scheme.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size.square(20),
                painter: _PatternGlyphPainter(pattern: pattern, color: fg),
              ),
              const SizedBox(height: AppDimens.space4),
              SizedBox(
                height: 18,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name,
                    maxLines: 1,
                    softWrap: false,
                    style: text.labelLarge!.copyWith(color: fg),
                  ),
                ),
              ),
              Text(
                '$pct%',
                textDirection: TextDirection.ltr,
                style: text.labelSmall!.copyWith(
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 20dp 铺法缩略图（线稿，与设计稿 1a 图形一致）。
class _PatternGlyphPainter extends CustomPainter {
  final LayoutPattern pattern;
  final Color color;

  const _PatternGlyphPainter({required this.pattern, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;
    final s = size.width;
    switch (pattern) {
      case LayoutPattern.straight:
        canvas.drawRect(Rect.fromLTWH(s * .15, s * .15, s * .7, s * .7), paint);
        canvas.drawLine(Offset(s * .5, s * .15), Offset(s * .5, s * .85), paint);
        canvas.drawLine(Offset(s * .15, s * .5), Offset(s * .85, s * .5), paint);
      case LayoutPattern.diagonal:
        canvas.save();
        canvas.translate(s / 2, s / 2);
        canvas.rotate(0.785398); // 45°
        canvas.translate(-s / 2, -s / 2);
        canvas.drawRect(
            Rect.fromLTWH(s * .225, s * .225, s * .55, s * .55), paint);
        canvas.drawLine(Offset(s * .5, s * .225), Offset(s * .5, s * .775), paint);
        canvas.drawLine(Offset(s * .225, s * .5), Offset(s * .775, s * .5), paint);
        canvas.restore();
      case LayoutPattern.herringbone:
        final path = Path()
          ..moveTo(s * .15, s * .70)
          ..lineTo(s * .40, s * .45)
          ..lineTo(s * .55, s * .60)
          ..lineTo(s * .30, s * .85)
          ..close()
          ..moveTo(s * .45, s * .40)
          ..lineTo(s * .70, s * .15)
          ..lineTo(s * .85, s * .30)
          ..lineTo(s * .60, s * .55)
          ..close();
        canvas.drawPath(path, paint);
      case LayoutPattern.custom:
        canvas.drawLine(Offset(s * .15, s * .5), Offset(s * .85, s * .5), paint);
        canvas.drawCircle(Offset(s * .6, s * .5), s * .15, paint);
    }
  }

  @override
  bool shouldRepaint(_PatternGlyphPainter oldDelegate) =>
      pattern != oldDelegate.pattern || color != oldDelegate.color;
}
```

（滑块段与 `wastePercent` 行原样保留。）

- [ ] **Step 4: 跑测试确认通过**

Run: `fvm flutter test test/ui/pattern_cards_test.dart test/ui/`
Expected: PASS（含既有 UI 测试；`waste_slider_haptics_test.dart`、`home_flow_test.dart` 若断言了 SegmentedButton，改为按 `pattern-card-*` key 点选——交互语义不变的机械修补）

- [ ] **Step 5: Commit**

```bash
git add lib/ui/home_page.dart test/ui/
git commit -m "feat: 铺法选择器升级为图案卡（回接设计稿 1a）"
```

---

### Task 9: Materials 区块 UI

**Files:**
- Create: `lib/ui/materials_section.dart`
- Modify: `lib/ui/home_page.dart:240`（`_BoxesAndCost` 之后插入 `MaterialsSection(calc: calc)`）
- Test: `test/ui/materials_section_test.dart`（新建，pumpHome helper 同 Task 8）

**Interfaces:**
- Consumes: Task 3 controller 字段/`setTrowel`、Task 5 文案、Task 6 `ValueField`、`Trowel`（label/`recommendTrowel`）、`formatLength`
- Produces: `class MaterialsSection extends StatelessWidget`，构造参数 `{required CalculatorController calc}`

- [ ] **Step 1: 写失败测试**

```dart
// test/ui/materials_section_test.dart（pumpHome 来自 Task 8 建的 test/ui/test_harness.dart）
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/materials_calculation.dart';
import 'test_harness.dart';

void main() {
  testWidgets('默认收起，回显「厚度 · Auto」摘要；展开出三组控件', (tester) async {
    await pumpHome(tester);
    expect(find.byKey(const ValueKey('materials-summary')), findsOneWidget);
    expect(find.byKey(const ValueKey('field-tileThickness--1')), findsNothing);

    await tester.ensureVisible(find.byKey(const ValueKey('materials-header')));
    await tester.tap(find.byKey(const ValueKey('materials-header')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('field-tileThickness--1')), findsOneWidget);
    expect(find.byKey(const ValueKey('field-jointDepth--1')), findsOneWidget);
    // 5 个档位 chip：Auto + 4 档
    expect(find.byKey(const ValueKey('trowel-chip-auto')), findsOneWidget);
    for (final t in Trowel.values) {
      expect(find.byKey(ValueKey('trowel-chip-${t.name}')), findsOneWidget);
    }
  });

  testWidgets('点档位 chip 改 controller；再点 Auto 回推荐', (tester) async {
    final calc = await pumpHome(tester);
    await tester.tap(find.byKey(const ValueKey('materials-header')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('trowel-chip-square12')));
    await tester.tap(find.byKey(const ValueKey('trowel-chip-square12')));
    await tester.pump();
    expect(calc.trowel, Trowel.square12);
    await tester.tap(find.byKey(const ValueKey('trowel-chip-auto')));
    await tester.pump();
    expect(calc.trowel, isNull);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `fvm flutter test test/ui/materials_section_test.dart`
Expected: FAIL（key 不存在）

- [ ] **Step 3: 实现**

`lib/ui/materials_section.dart` 全文：

```dart
import 'package:flutter/material.dart';

import '../domain/materials_calculation.dart';
import '../keyboard/metric_editor.dart';
import '../l10n/app_localizations.dart';
import '../state/calculator_controller.dart';
import '../theme/app_dimens.dart';
import 'format.dart';
import 'value_field.dart';

/// 辅料参数区（设计稿 10a/10b）：可折叠但有默认值——收起 ≠ 不参与，
/// 结果卡的材料行始终按当前参数计算。
class MaterialsSection extends StatelessWidget {
  final CalculatorController calc;

  const MaterialsSection({super.key, required this.calc});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    // 收起态摘要：厚度 · 镘刀（Auto 显示本地化「自动」）
    final thicknessText = formatLength(
      calc.tileThickness, calc.unitSystem, MetricUnit.mm, locale);
    final trowelText = calc.trowel?.label ?? l10n.trowelAuto;

    return ExpansionTile(
      key: const ValueKey('materials-header'),
      title: Text(l10n.sectionMaterials),
      subtitle: Text(
        l10n.materialsDefaults,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Text(
        '$thicknessText · $trowelText',
        key: const ValueKey('materials-summary'),
        textDirection: TextDirection.ltr,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      childrenPadding: const EdgeInsets.only(bottom: AppDimens.space8),
      children: [
        Row(
          children: [
            Expanded(
              child: ValueField(
                calc: calc,
                id: const FieldId(FieldKind.tileThickness),
                label: l10n.tileThickness,
                value: calc.tileThickness,
                metricUnit: MetricUnit.mm,
              ),
            ),
            const SizedBox(width: AppDimens.space12),
            Expanded(
              child: calc.jointDepth == null &&
                      calc.editing?.kind != FieldKind.jointDepth
                  ? _followField(context, l10n)
                  : ValueField(
                      calc: calc,
                      id: const FieldId(FieldKind.jointDepth),
                      label: l10n.jointDepth,
                      value: calc.jointDepth,
                      metricUnit: MetricUnit.mm,
                    ),
            ),
            const SizedBox(width: AppDimens.space12),
            const Spacer(),
          ],
        ),
        const SizedBox(height: AppDimens.space12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            l10n.trowelLabel,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(height: AppDimens.space4),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Wrap(
            spacing: AppDimens.space8,
            runSpacing: AppDimens.space8,
            children: [
              ChoiceChip(
                key: const ValueKey('trowel-chip-auto'),
                label: Text(calc.trowel == null && calc.tileWidth != null
                    ? '${l10n.trowelAuto} · ${recommendTrowel(calc.tileWidth!, calc.tileHeight ?? calc.tileWidth!).label}'
                    : l10n.trowelAuto),
                selected: calc.trowel == null,
                onSelected: (_) => calc.setTrowel(null),
              ),
              for (final t in Trowel.values)
                ChoiceChip(
                  key: ValueKey('trowel-chip-${t.name}'),
                  label: Text(t.label, textDirection: TextDirection.ltr),
                  selected: calc.trowel == t,
                  onSelected: (_) => calc.setTrowel(t),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.space4),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            l10n.trowelAutoCaption,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  /// 缝深「= 砖厚」占位：点击即开始编辑缝深（转成真实字段）。
  Widget _followField(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.jointDepth,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.labelSmall!.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        InkWell(
          key: const ValueKey('field-jointDepth-follow'),
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            calc.startEditing(const FieldId(FieldKind.jointDepth));
          },
          borderRadius: BorderRadius.circular(AppDimens.radius2),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppDimens.minTouchTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space12,
              vertical: AppDimens.space8,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimens.radius2),
              border: Border.all(color: scheme.outline),
            ),
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.jointDepthFollows,
              textDirection: TextDirection.ltr,
              style: text.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}
```

`home_page.dart` `_InputForm.build` 的 `_BoxesAndCost(calc: calc)` 之后追加：

```dart
const SizedBox(height: AppDimens.space24),
MaterialsSection(calc: calc),
```

（并加 `import 'materials_section.dart';`。）

- [ ] **Step 4: 跑测试确认通过**

Run: `fvm flutter test test/ui/materials_section_test.dart test/ui/`
Expected: PASS（既有 layout_guard/home_flow 若因页面长度断言失败，按新增区块修正预期值）

- [ ] **Step 5: Commit**

```bash
git add lib/ui/materials_section.dart lib/ui/home_page.dart test/ui/
git commit -m "feat: 主页新增辅料参数区块（厚度/缝深/镘刀）"
```

---

### Task 10: 结果卡 v1.1（预览 + 材料行 + 免责）

**Files:**
- Modify: `lib/ui/result_card.dart`
- Modify: `lib/ui/home_page.dart`（`_ResultsSection` 传新参数）
- Modify: `lib/ui/format.dart`（新增 `formatGroutAmount`）
- Test: `test/ui/result_card_materials_test.dart`（新建）

**Interfaces:**
- Consumes: `MaterialsResult`、`PatternPreview`、Task 5 文案
- Produces:
  - `ResultCard` 新增构造参数：`MaterialsResult? materials`、`Length? tileWidth`、`Length? tileHeight`、`Length? grout`、`LayoutPattern? pattern`、`double previewSize = 84`（双栏传 120）
  - `String formatGroutAmount(double kg, UnitSystem system, String locale)` → 英制 `'≈ 4.3 lb (2.0 kg)'` / 公制 `'≈ 2.0 kg (4.3 lb)'`

- [ ] **Step 1: 写失败测试**

```dart
// test/ui/result_card_materials_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/length.dart';
import 'package:tilemath/domain/materials_calculation.dart';
import 'package:tilemath/domain/tile_calculation.dart';
import 'package:tilemath/l10n/app_localizations.dart';
import 'package:tilemath/state/settings_controller.dart';
import 'package:tilemath/ui/format.dart';
import 'package:tilemath/ui/pattern_preview.dart';
import 'package:tilemath/ui/result_card.dart';

void main() {
  test('formatGroutAmount 主次单位随单位制', () {
    expect(formatGroutAmount(1.967, UnitSystem.imperial, 'en'),
        '≈ 4.3 lb (2.0 kg)');
    expect(formatGroutAmount(1.967, UnitSystem.metric, 'en'),
        '≈ 2.0 kg (4.3 lb)');
  });

  Widget host(ResultCard card) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: card)),
      );

  final result = calculateTiles(TileCalcInput(
    areas: [
      AreaEntry(
        length: Length.imperial(feet: 12),
        width: Length.imperial(feet: 10),
      ),
    ],
    tileWidth: Length.ofInches(12),
    tileHeight: Length.ofInches(12),
    grout: Length.imperial(sixteenths: 1),
    wasteRate: 0.10,
  ));
  final materials = calculateMaterials(MaterialsInput(
    tileWidth: Length.ofInches(12),
    tileHeight: Length.ofInches(12),
    grout: Length.imperial(sixteenths: 1),
    tileThickness: Length.imperial(sixteenths: 5),
    jointDepth: null,
    trowel: null,
    netAreaSqM: result.netAreaSqM,
    wasteRate: 0.10,
  ));

  testWidgets('完整态：预览 84dp + 材料两行 + 免责', (tester) async {
    await tester.pumpWidget(host(ResultCard(
      result: result,
      materials: materials,
      tileWidth: Length.ofInches(12),
      tileHeight: Length.ofInches(12),
      grout: Length.imperial(sixteenths: 1),
      pattern: LayoutPattern.straight,
      unitSystem: UnitSystem.imperial,
      currencySymbol: r'$',
      wastePct: 10,
    )));
    final preview = find.byType(PatternPreview);
    expect(preview, findsOneWidget);
    expect(tester.getSize(preview), const Size(84, 84)); // 量尺寸
    expect(find.byKey(const ValueKey('grout-row')), findsOneWidget);
    expect(find.byKey(const ValueKey('thinset-row')), findsOneWidget);
    expect(find.byKey(const ValueKey('materials-disclaimer')), findsOneWidget);
  });

  testWidgets('materials 为 null 时材料行与免责整体隐藏', (tester) async {
    await tester.pumpWidget(host(ResultCard(
      result: result,
      materials: null,
      tileWidth: Length.ofInches(12),
      tileHeight: Length.ofInches(12),
      grout: Length.imperial(sixteenths: 1),
      pattern: LayoutPattern.straight,
      unitSystem: UnitSystem.imperial,
      currencySymbol: r'$',
      wastePct: 10,
    )));
    expect(find.byKey(const ValueKey('grout-row')), findsNothing);
    expect(find.byKey(const ValueKey('materials-disclaimer')), findsNothing);
  });

  testWidgets('空态不画预览', (tester) async {
    await tester.pumpWidget(host(const ResultCard(
      result: null,
      materials: null,
      tileWidth: null,
      tileHeight: null,
      grout: null,
      pattern: null,
      unitSystem: UnitSystem.imperial,
      currencySymbol: r'$',
      wastePct: 10,
    )));
    expect(find.byType(PatternPreview), findsNothing);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `fvm flutter test test/ui/result_card_materials_test.dart`
Expected: FAIL（新参数不存在）

- [ ] **Step 3: 实现**

`lib/ui/format.dart` 追加：

```dart
/// 材料重量行：主单位随单位制，副单位括号随行（数字恒 LTR）。
String formatGroutAmount(double kg, UnitSystem system, String locale) {
  final f = NumberFormat.decimalPatternDigits(
    locale: _latinDigitsLocale(locale),
    decimalDigits: 1,
  );
  final lb = kg * 2.20462;
  return system == UnitSystem.imperial
      ? '≈ ${f.format(lb)} lb (${f.format(kg)} kg)'
      : '≈ ${f.format(kg)} kg (${f.format(lb)} lb)';
}
```

`lib/ui/result_card.dart`：构造新增六个字段（同 Interfaces），build 的完整态 `Column` 修改：

1. 大数字 `Center(...)` 段替换为「左数字右预览」行（预览条件：`tileWidth/tileHeight/grout/pattern` 全非空）：

```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimens.space8),
        decoration: BoxDecoration(
          // 大数字区轻层次（2026-08-06 视觉增强拍板）：primaryContainer
          // 半透明底，纸面纹理透出，不抢数字对比度。
          color: scheme.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppDimens.radius2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r.tilesNeeded}',
                textDirection: TextDirection.ltr, style: text.displayLarge),
            Text(l10n.tilesNeededLabel(r.tilesNeeded),
                style:
                    text.bodySmall!.copyWith(color: scheme.onSurfaceVariant)),
            Text(l10n.wasteLine(r.baseTiles, wastePct),
                style:
                    text.bodySmall!.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    ),
    if (tileWidth != null && tileHeight != null &&
        grout != null && pattern != null)
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PatternPreview(
            tileWidth: tileWidth!,
            tileHeight: tileHeight!,
            grout: grout!,
            pattern: pattern!,
            size: previewSize,
          ),
          const SizedBox(height: AppDimens.space4),
          Text(
            l10n.previewCaption(
              _patternName(l10n, pattern!),
              formatLength(grout!, unitSystem, MetricUnit.mm, locale),
            ),
            style: text.bodySmall!.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
  ],
),
```

2. `smallAreaHint` 段之前插入材料行与免责：

```dart
if (materials != null) ...[
  const SizedBox(height: AppDimens.space8),
  KeyedSubtree(
    key: const ValueKey('grout-row'),
    child: _labeledRow(
      context,
      l10n.groutNeeded,
      formatGroutAmount(materials!.groutKg, unitSystem, locale),
    ),
  ),
  const SizedBox(height: AppDimens.space8),
  KeyedSubtree(
    key: const ValueKey('thinset-row'),
    child: _labeledRow(
      context,
      l10n.thinsetNeeded,
      l10n.thinsetBagsLine(
        unitSystem == UnitSystem.imperial
            ? materials!.thinsetBags50Lb
            : materials!.thinsetBags20Kg,
        unitSystem == UnitSystem.imperial ? '50 lb' : '20 kg',
      ),
    ),
  ),
  const SizedBox(height: AppDimens.space8),
  Row(
    key: const ValueKey('materials-disclaimer'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
      const SizedBox(width: AppDimens.space8),
      Expanded(
        child: Text(
          l10n.materialsDisclaimer,
          style: text.bodySmall!.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    ],
  ),
],
```

3. 文件内补私有 helper 与 import（`pattern_preview.dart`、`length.dart`、`metric_editor.dart`）：

```dart
String _patternName(AppLocalizations l10n, LayoutPattern p) => switch (p) {
      LayoutPattern.straight => l10n.patternStraight,
      LayoutPattern.diagonal => l10n.patternDiagonal,
      LayoutPattern.herringbone => l10n.patternHerringbone,
      LayoutPattern.custom => l10n.patternCustom,
    };
```

`home_page.dart`：`_ResultsSection` 增加 `final bool twoPane;`（构造参数 `this.twoPane = false`），`HomePage` 的 `LayoutBuilder` 内改为 `final results = _ResultsSection(calc: calc, settings: settings, twoPane: twoPane);`（spec §3：双栏预览 120dp）。`_ResultsSection.build` 传参：

```dart
ResultCard(
  result: calc.result,
  materials: calc.materialsResult,
  tileWidth: calc.tileWidth,
  tileHeight: calc.tileHeight,
  grout: calc.grout,
  pattern: calc.pattern,
  previewSize: twoPane ? 120 : 84,
  unitSystem: calc.unitSystem,
  currencySymbol: settings.currencySymbol,
  wastePct: (calc.wasteRate * 100).round(),
),
```

- [ ] **Step 4: 跑测试确认通过**

Run: `fvm flutter test test/ui/`
Expected: PASS（`display_polish_test.dart` 等涉及结果卡结构的既有断言按新布局修正）

- [ ] **Step 5: Commit**

```bash
git add lib/ui/result_card.dart lib/ui/home_page.dart lib/ui/format.dart test/ui/
git commit -m "feat: 结果卡接入铺贴预览与材料估算行"
```

---

### Task 11: 分享（渲染器 + 服务 + 入口）

**Files:**
- Modify: `pubspec.yaml`（dependencies 追加 `share_plus: ^10.1.0`、`path_provider: ^2.1.4`）
- Create: `lib/share/share_card_renderer.dart`
- Create: `lib/share/share_service.dart`
- Modify: `lib/ui/home_page.dart`（`_ResultsSection` kicker 行加分享按钮）
- Test: `test/share/share_card_renderer_test.dart`（新建）

**Interfaces:**
- Consumes: `layoutTiles`、`MaterialsResult`、Task 5 文案（由调用方取好传入，渲染器不依赖 BuildContext）
- Produces:
  - `class ShareCardData { String appName; String date; String tilesLabel; String tilesValue; String wasteLine; List<(String, String)> rows; String specLine; String footer; double tileWmm, tileHmm, groutMm; LayoutPattern pattern; }`
  - `Future<Uint8List> renderShareCardPng(ShareCardData data)`（1080×1350 PNG，浅色主题固定）
  - `Future<void> shareResultCard(ShareCardData data)`（写临时文件 + 系统分享面板；抛错交由调用方兜 SnackBar）

- [ ] **Step 1: 加依赖**

`pubspec.yaml` dependencies 追加两行后：

Run: `fvm flutter pub get`
Expected: 成功解析（若 share_plus ^10 与 SDK 冲突，取 `fvm flutter pub add share_plus path_provider` 解出的兼容版本）

- [ ] **Step 2: 写失败测试**

```dart
// test/share/share_card_renderer_test.dart
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/tile_calculation.dart';
import 'package:tilemath/share/share_card_renderer.dart';

ShareCardData sample({List<(String, String)>? rows}) => ShareCardData(
      appName: 'TileMath',
      date: 'Aug 6, 2026',
      tilesLabel: 'TILES NEEDED',
      tilesValue: '141',
      wasteLine: '128 tiles + 10% waste',
      rows: rows ??
          const [
            ('Total area', '129.33 ft²'),
            ('Boxes to buy', '17'),
            ('Estimated cost', r'$425.00'),
            ('Grout', '≈ 4.3 lb (2.0 kg)'),
            ('Thinset', '≈ 3 bags · 50 lb'),
          ],
      specLine: '12×12″ tile · 1/16″ grout · Straight · 10% waste',
      footer: 'TileMath — tile calculator with a fraction-inch keyboard',
      tileWmm: 304.8,
      tileHmm: 304.8,
      groutMm: 1.5875,
      pattern: LayoutPattern.straight,
    );

void main() {
  test('输出 1080×1350 PNG', () async {
    final bytes = await renderShareCardPng(sample());
    expect(bytes, isNotEmpty);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 1080);
    expect(frame.image.height, 1350);
  });

  test('行数不同也能渲染（未填箱规的短列表）', () async {
    final bytes = await renderShareCardPng(sample(rows: const [
      ('Total area', '129.33 ft²'),
      ('Grout', '≈ 4.3 lb (2.0 kg)'),
      ('Thinset', '≈ 3 bags · 50 lb'),
    ]));
    expect(bytes, isNotEmpty);
  });
}
```

- [ ] **Step 3: 跑测试确认失败**

Run: `fvm flutter test test/share/share_card_renderer_test.dart`
Expected: FAIL（文件不存在）

- [ ] **Step 4: 实现渲染器与服务**

`lib/share/share_card_renderer.dart` 全文：

```dart
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
```

`lib/share/share_service.dart` 全文：

```dart
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'share_card_renderer.dart';

/// 渲染分享卡 → 临时文件 → 系统分享面板。异常向上抛，由 UI 兜 SnackBar。
Future<void> shareResultCard(ShareCardData data) async {
  final bytes = await renderShareCardPng(data);
  final dir = await getTemporaryDirectory();
  final file = File(
      '${dir.path}/tilemath-share-${DateTime.now().millisecondsSinceEpoch}.png');
  await file.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')]);
}
```

`home_page.dart` `_ResultsSection.build` 改为 kicker 行 + 分享按钮（`materialsResult`/结果非空才显示），并组装 `ShareCardData`：

```dart
final r = calc.result;
final locale = Localizations.localeOf(context).toString();
return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        Expanded(child: _Kicker(l10n.sectionResults)),
        if (r != null)
          IconButton(
            key: const ValueKey('share-result'),
            icon: const Icon(Icons.ios_share, size: 22),
            tooltip: l10n.shareResult,
            onPressed: () => _share(context),
          ),
      ],
    ),
    ResultCard(
      result: calc.result,
      materials: calc.materialsResult,
      tileWidth: calc.tileWidth,
      tileHeight: calc.tileHeight,
      grout: calc.grout,
      pattern: calc.pattern,
      previewSize: twoPane ? 120 : 84,
      unitSystem: calc.unitSystem,
      currencySymbol: settings.currencySymbol,
      wastePct: (calc.wasteRate * 100).round(),
    ),
  ],
);
```

（`_Kicker` 原有 `Padding(bottom: 12)` 与 `IconButton` 同行会撑高——kicker 行用 `Row(crossAxisAlignment: CrossAxisAlignment.center)` 即可，视觉按设计稿 10a。）

`_ResultsSection` 内新增（转成 StatelessWidget 上的方法）：

```dart
Future<void> _share(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toString();
  final r = calc.result;
  final m = calc.materialsResult;
  final tw = calc.tileWidth;
  final th = calc.tileHeight;
  if (r == null || tw == null || th == null) return;

  final imperial = calc.unitSystem == UnitSystem.imperial;
  String patternName() => switch (calc.pattern) {
        LayoutPattern.straight => l10n.patternStraight,
        LayoutPattern.diagonal => l10n.patternDiagonal,
        LayoutPattern.herringbone => l10n.patternHerringbone,
        LayoutPattern.custom => l10n.patternCustom,
      };
  final data = ShareCardData(
    appName: 'TileMath',
    date: DateFormat.yMMMd(locale.startsWith('ar') ? 'en_US' : locale)
        .format(DateTime.now()),
    tilesLabel: l10n.tilesNeededLabel(r.tilesNeeded).toUpperCase(),
    tilesValue: '${r.tilesNeeded}',
    wasteLine: l10n.wasteLine(r.baseTiles, (calc.wasteRate * 100).round()),
    rows: [
      (l10n.totalArea, formatArea(r.netAreaSqM, calc.unitSystem, locale)),
      if (r.boxes != null) (l10n.boxesToBuy, '${r.boxes}'),
      if (r.cost != null)
        (l10n.estimatedCost,
            formatCost(r.cost!, settings.currencySymbol, locale)),
      if (m != null)
        (l10n.groutNeeded,
            formatGroutAmount(m.groutKg, calc.unitSystem, locale)),
      if (m != null)
        (l10n.thinsetNeeded,
            l10n.thinsetBagsLine(
                imperial ? m.thinsetBags50Lb : m.thinsetBags20Kg,
                imperial ? '50 lb' : '20 kg')),
    ],
    specLine:
        '${formatLength(tw, calc.unitSystem, MetricUnit.cm, locale)} × '
        '${formatLength(th, calc.unitSystem, MetricUnit.cm, locale)} · '
        '${l10n.previewCaption(patternName(), formatLength(calc.grout, calc.unitSystem, MetricUnit.mm, locale))}',
    footer: l10n.shareCardFooter,
    tileWmm: tw.mm,
    tileHmm: th.mm,
    groutMm: calc.grout.mm,
    pattern: calc.pattern,
  );
  try {
    await shareResultCard(data);
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
  }
}
```

（import 追加：`package:intl/intl.dart`、`../share/share_card_renderer.dart`、`../share/share_service.dart`。）

- [ ] **Step 5: 跑测试确认通过**

Run: `fvm flutter test test/share/ test/ui/`
Expected: PASS；另加一条 widget 断言进 `test/ui/result_card_materials_test.dart` 同目录任一主页测试：有结果时 `find.byKey(ValueKey('share-result'))` findsOneWidget、空表单时 findsNothing

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/share/ lib/ui/home_page.dart test/share/ test/ui/
git commit -m "feat: 结果分享——Canvas 离屏渲染分享卡走系统分享面板"
```

---

### Task 12: iPad 恢复 + 版本号

**Files:**
- Modify: `ios/Runner.xcodeproj/project.pbxproj`（3 处 TARGETED_DEVICE_FAMILY）
- Modify: `ios/Runner/Info.plist`（iPad 方向）
- Modify: `pubspec.yaml:4`（版本号）

- [ ] **Step 1: 确认现状**

Run: `grep -n 'TARGETED_DEVICE_FAMILY' ios/Runner.xcodeproj/project.pbxproj`
Expected: 3 行，当前值为 `1`（行号约 367/494/547）

- [ ] **Step 2: 解锁 iPad 设备族**

3 处均改为：

```
TARGETED_DEVICE_FAMILY = "1,2";
```

- [ ] **Step 3: iPad 方向（iPhone 保持仅竖屏不动）**

`ios/Runner/Info.plist` 在既有 `UISupportedInterfaceOrientations`（含注释）之后追加：

```xml
<key>UISupportedInterfaceOrientations~ipad</key>
<array>
	<string>UIInterfaceOrientationPortrait</string>
	<string>UIInterfaceOrientationPortraitUpsideDown</string>
	<string>UIInterfaceOrientationLandscapeLeft</string>
	<string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

（不加 `UIRequiresFullScreen`——支持分屏，窄分屏由 ≥600dp 判定自动退化单栏。）

- [ ] **Step 4: 版本号**

`pubspec.yaml`：`version: 1.0.0+6` → `version: 1.1.0+7`

- [ ] **Step 5: 构建验证**

Run: `fvm flutter build ios --no-codesign`
Expected: 构建成功（无签名产物）；`grep -c '"1,2"' ios/Runner.xcodeproj/project.pbxproj` 输出 3

- [ ] **Step 6: Commit**

```bash
git add ios/Runner.xcodeproj/project.pbxproj ios/Runner/Info.plist pubspec.yaml
git commit -m "feat: 恢复 iPad 支持（device family 1,2 + iPad 全方向），版本 1.1.0+7"
```

---

### Task 13: 全量回归 + 重提材料

**Files:**
- Create: `docs/release/review-notes-1.1.0.md`
- Test: 全量

- [ ] **Step 1: 全量静态检查与测试**

```bash
fvm flutter analyze
fvm flutter test
```

Expected: analyze 无 issue；测试全绿。任何失败先修再继续。

- [ ] **Step 2: iPad/iPhone 手测清单（模拟器，逐项确认）**

- iPad Pro 11″/13″ 模拟器：竖屏双栏、横屏双栏、分屏 1/3 宽退化单栏、键盘 56dp 常驻可输入
- iPhone 模拟器：维持竖屏锁定，单栏布局与 v1.0 一致
- 三语（en/zh/ar）：Materials 区块、结果卡材料行、分享卡文案正确；ar 全屏 RTL 下数字/尺寸恒 LTR
- 分享：生成图片并弹出系统分享面板；取消分享无异常
- 历史：v1.0 老记录可读、可恢复（模拟：手工构造无材料字段的 JSON 写入 shared_preferences 或复用 Task 4 单测结论）

- [ ] **Step 3: 写 Review Notes 草稿**

`docs/release/review-notes-1.1.0.md`（英文，提交 ASC 时粘贴），内容要点——针对上次 4.2 拒审逐条对应：

```markdown
# App Review Notes — 1.1.0 (7)

Thank you for the feedback on our previous submission (4.2 Minimum
Functionality). This update substantially expands the app's functionality:

1. **Live layout preview** — the results card now renders a to-scale tiling
   preview driven by the user's tile size, grout width and pattern.
2. **Materials estimation suite** — beyond tile count/boxes/cost, the app now
   estimates grout (by joint geometry) and thinset mortar (by trowel notch
   coverage), with adjustable tile thickness, joint depth and trowel size.
3. **Share/export** — results export as an image via the system share sheet.
4. **Native iPad support** — dedicated two-pane iPad layout (form + persistent
   keyboard left, live results right), all orientations, Split View supported.

Core differentiation: a purpose-built fraction-inch keyboard (1/16″ precision,
ft/in segments) for US contractors and DIYers reading tape measures — enter
12′ 3-1/2″ directly. The app is fully offline, collects no data, and shows no
ads.

How to test: enter room length/width (e.g. 12 ft × 10 ft), pick a tile size
chip, choose a pattern — results, preview and material estimates update live.
Tap the share icon next to RESULTS to export.
```

- [ ] **Step 4: Commit**

```bash
git add docs/release/review-notes-1.1.0.md
git commit -m "docs: 1.1.0 重提审核 Review Notes 草稿"
```

- [ ] **Step 5: 人工收尾（用户操作，计划外）**

- TestFlight 上传 1.1.0(7)，iPhone + iPad 真机/模拟器过一遍
- 截图流水线补拍 iPad 13″（2064×2752）并上传 ASC
- ASC 重新提交审核；（可选）Resolution Center 回复说明以功能更新回应
