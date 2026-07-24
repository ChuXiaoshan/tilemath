import '../state/settings_controller.dart';

/// 历史记录条目：完整输入快照（mm 基准，可跨单位制恢复）
/// + 结果摘要（列表渲染直读，不重算——算法将来变了也不改写历史）。
class HistoryEntry {
  final int id;
  final DateTime timestamp;
  final UnitSystem unitSystem;
  final List<HistoryRow> rows;
  final double tileWidthMm;
  final double tileHeightMm;
  final double groutMm;

  /// LayoutPattern.name 序列化形态，向前兼容未知值。
  final String patternName;
  final int customWastePct;
  final int? tilesPerBox;
  final double? pricePerBox;

  // 结果摘要
  final double netAreaSqM;
  final int tilesNeeded;
  final int? boxes;

  const HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.unitSystem,
    required this.rows,
    required this.tileWidthMm,
    required this.tileHeightMm,
    required this.groutMm,
    required this.patternName,
    required this.customWastePct,
    required this.tilesPerBox,
    required this.pricePerBox,
    required this.netAreaSqM,
    required this.tilesNeeded,
    required this.boxes,
  });

  /// 输入是否与另一条完全一致（忽略 id/时间戳/结果摘要）。
  /// 用于"连续 Done 微调不刷屏"的去重判定。
  bool sameInputs(HistoryEntry other) {
    if (unitSystem != other.unitSystem ||
        tileWidthMm != other.tileWidthMm ||
        tileHeightMm != other.tileHeightMm ||
        groutMm != other.groutMm ||
        patternName != other.patternName ||
        customWastePct != other.customWastePct ||
        tilesPerBox != other.tilesPerBox ||
        pricePerBox != other.pricePerBox ||
        rows.length != other.rows.length) {
      return false;
    }
    for (var i = 0; i < rows.length; i++) {
      final a = rows[i];
      final b = other.rows[i];
      if (a.lengthMm != b.lengthMm ||
          a.widthMm != b.widthMm ||
          a.isCutout != b.isCutout) {
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ts': timestamp.millisecondsSinceEpoch,
        'unit': unitSystem.name,
        'rows': [for (final r in rows) r.toJson()],
        'tileW': tileWidthMm,
        'tileH': tileHeightMm,
        'grout': groutMm,
        'pattern': patternName,
        'customWaste': customWastePct,
        'tilesPerBox': tilesPerBox,
        'pricePerBox': pricePerBox,
        'netArea': netAreaSqM,
        'tiles': tilesNeeded,
        'boxes': boxes,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as int,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
        unitSystem: json['unit'] == 'metric'
            ? UnitSystem.metric
            : UnitSystem.imperial,
        rows: [
          for (final r in json['rows'] as List)
            HistoryRow.fromJson(r as Map<String, dynamic>),
        ],
        tileWidthMm: (json['tileW'] as num).toDouble(),
        tileHeightMm: (json['tileH'] as num).toDouble(),
        groutMm: (json['grout'] as num).toDouble(),
        patternName: json['pattern'] as String,
        customWastePct: json['customWaste'] as int,
        tilesPerBox: json['tilesPerBox'] as int?,
        pricePerBox: (json['pricePerBox'] as num?)?.toDouble(),
        netAreaSqM: (json['netArea'] as num).toDouble(),
        tilesNeeded: json['tiles'] as int,
        boxes: json['boxes'] as int?,
      );
}

/// 一行区域快照；未完成的行允许空维度。
class HistoryRow {
  final double? lengthMm;
  final double? widthMm;
  final bool isCutout;

  const HistoryRow({
    required this.lengthMm,
    required this.widthMm,
    required this.isCutout,
  });

  Map<String, dynamic> toJson() =>
      {'l': lengthMm, 'w': widthMm, 'cut': isCutout};

  factory HistoryRow.fromJson(Map<String, dynamic> json) => HistoryRow(
        lengthMm: (json['l'] as num?)?.toDouble(),
        widthMm: (json['w'] as num?)?.toDouble(),
        isCutout: json['cut'] as bool? ?? false,
      );
}
