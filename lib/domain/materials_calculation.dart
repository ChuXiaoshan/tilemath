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
