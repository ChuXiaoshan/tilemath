import 'dart:math' as math;

import 'length.dart';

/// 铺贴方式与预设损耗率（brief §3：10% / 15% / 20% / 自定义 0–30%）。
enum LayoutPattern {
  straight(0.10),
  diagonal(0.15),
  herringbone(0.20),
  custom(null);

  /// custom 为 null，实际损耗率由滑块提供。
  final double? wasteRate;

  const LayoutPattern(this.wasteRate);
}

/// 一行区域输入；isCutout 为 true 时是扣除区域（门、橱柜等不铺部分）。
class AreaEntry {
  final Length length;
  final Length width;
  final bool isCutout;

  AreaEntry({required this.length, required this.width, this.isCutout = false});

  double get areaSqM => length.mm * width.mm / 1e6;
}

class TileCalcInput {
  final List<AreaEntry> areas;
  final Length tileWidth;
  final Length tileHeight;

  /// 缝宽，参与铺贴节距：有效砖尺寸 = 砖 + 缝。
  final Length grout;

  /// 损耗率，合法域 0–0.30。
  final double wasteRate;

  /// 箱规/单价均可不填（结果卡对应行整行隐藏）。
  final int? tilesPerBox;
  final double? pricePerBox;

  TileCalcInput({
    required this.areas,
    required this.tileWidth,
    required this.tileHeight,
    required this.grout,
    required this.wasteRate,
    this.tilesPerBox,
    this.pricePerBox,
  });
}

class TileCalcResult {
  /// 净面积 = 区域和 − 扣除和，下限 0。
  final double netAreaSqM;

  /// 未计损耗的片数（结果卡次要说明行 "120 tiles + 10% waste" 用）。
  final int baseTiles;

  /// 含损耗最终片数（结果卡主数字）。
  final int tilesNeeded;

  /// 未填箱规/单价时为 null。
  final int? boxes;
  final double? cost;

  /// 净面积 < 2 m² 时建议 +5% 损耗（brief §3.4，建议非警告）。
  final bool smallAreaHint;

  const TileCalcResult({
    required this.netAreaSqM,
    required this.baseTiles,
    required this.tilesNeeded,
    required this.boxes,
    required this.cost,
    required this.smallAreaHint,
  });
}

/// 带浮点护栏的向上取整：120.000000000001 不得进位成 121。
int ceilGuarded(double value) => (value - 1e-9).ceil();

TileCalcResult calculateTiles(TileCalcInput input) {
  if (input.tileWidth.mm <= 0 || input.tileHeight.mm <= 0) {
    throw ArgumentError('瓷砖尺寸必须大于 0');
  }
  if (input.wasteRate < 0 || input.wasteRate > 0.30) {
    throw ArgumentError('损耗率合法域为 0–0.30，实际 ${input.wasteRate}');
  }
  final tilesPerBox = input.tilesPerBox;
  if (tilesPerBox != null && tilesPerBox <= 0) {
    throw ArgumentError('箱规必须大于 0');
  }
  final pricePerBox = input.pricePerBox;
  if (pricePerBox != null && pricePerBox < 0) {
    throw ArgumentError('单价不得为负');
  }

  var grossSqM = 0.0;
  var cutoutSqM = 0.0;
  for (final area in input.areas) {
    if (area.isCutout) {
      cutoutSqM += area.areaSqM;
    } else {
      grossSqM += area.areaSqM;
    }
  }
  final netSqM = math.max(0.0, grossSqM - cutoutSqM);

  // 铺贴节距 = 砖 + 缝（每片砖摊到一条缝）
  final pitchAreaSqM =
      (input.tileWidth.mm + input.grout.mm) *
      (input.tileHeight.mm + input.grout.mm) /
      1e6;

  final baseTiles = netSqM <= 0 ? 0 : ceilGuarded(netSqM / pitchAreaSqM);
  final tilesNeeded = ceilGuarded(baseTiles * (1 + input.wasteRate));
  final boxes =
      tilesPerBox == null ? null : ceilGuarded(tilesNeeded / tilesPerBox);
  final cost =
      (boxes != null && pricePerBox != null) ? boxes * pricePerBox : null;

  return TileCalcResult(
    netAreaSqM: netSqM,
    baseTiles: baseTiles,
    tilesNeeded: tilesNeeded,
    boxes: boxes,
    cost: cost,
    smallAreaHint: netSqM > 0 && netSqM < 2.0,
  );
}
