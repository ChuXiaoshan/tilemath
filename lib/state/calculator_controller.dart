import 'package:flutter/foundation.dart';

import '../domain/length.dart';
import '../domain/tile_calculation.dart';
import '../history/history_entry.dart';
import '../keyboard/imperial_editor.dart';
import '../keyboard/metric_editor.dart';
import 'settings_controller.dart';

/// 可编辑字段的种类。
enum FieldKind { areaLength, areaWidth, tileWidth, tileHeight, grout }

/// 字段标识：种类 + 所属区域行（非区域字段 row = -1）。
@immutable
class FieldId {
  final FieldKind kind;
  final int row;

  const FieldId(this.kind, [this.row = -1]);

  @override
  bool operator ==(Object other) =>
      other is FieldId && other.kind == kind && other.row == row;

  @override
  int get hashCode => Object.hash(kind, row);
}

/// 一行区域输入（普通或扣除）。
class AreaRowData {
  Length? length;
  Length? width;
  final bool isCutout;

  AreaRowData({this.isCutout = false});

  bool get isComplete => length != null && width != null;

  double? get areaSqM => isComplete
      ? (length!.mm * width!.mm / 1e6) * (isCutout ? -1 : 1)
      : null;
}

/// 主计算页状态：区域列表、瓷砖参数、铺贴方式、箱规成本、编辑焦点。
/// 值一律以 Length（mm 基准）落地，单位制只影响输入键盘与显示。
class CalculatorController extends ChangeNotifier {
  static const maxRows = 20; // brief §3：区域列表上限

  UnitSystem _unitSystem;

  final List<AreaRowData> rows = [AreaRowData()];

  Length? tileWidth;
  Length? tileHeight;
  late Length grout;
  bool _groutTouched = false;

  LayoutPattern pattern = LayoutPattern.straight;

  /// Custom 滑块值（百分比 0–30），仅 pattern == custom 时生效。
  int customWastePct = 10;

  int? tilesPerBox;
  double? pricePerBox;

  /// 当前编辑焦点；null = 键盘收起。
  FieldId? editing;
  ImperialEditor? imperialEditor;
  MetricEditor? metricEditor;

  CalculatorController(this._unitSystem) {
    grout = _defaultGrout(_unitSystem);
  }

  UnitSystem get unitSystem => _unitSystem;

  /// 默认缝宽：英制 1/16″（brief §3），公制 2 mm。
  static Length _defaultGrout(UnitSystem system) =>
      system == UnitSystem.imperial
          ? Length.imperial(sixteenths: 1)
          : Length.ofMm(2);

  /// 单位制切换：已录入的 Length 值保留（mm 基准），未动过的缝宽换成新默认。
  set unitSystem(UnitSystem system) {
    if (system == _unitSystem) return;
    _unitSystem = system;
    if (!_groutTouched) grout = _defaultGrout(system);
    _stopEditing();
    notifyListeners();
  }

  double get wasteRate => pattern == LayoutPattern.custom
      ? customWastePct / 100
      : pattern.wasteRate!;

  /// 输入不足或非法（瓷砖尺寸 ≤0）时为 null（结果卡空态），
  /// 保证 build 期读取永不抛错。
  TileCalcResult? get result {
    final tw = tileWidth;
    final th = tileHeight;
    final hasArea =
        rows.any((r) => !r.isCutout && r.isComplete);
    if (tw == null || th == null || !hasArea) return null;
    if (tw.mm <= 0 || th.mm <= 0) return null;
    return calculateTiles(TileCalcInput(
      areas: [
        for (final r in rows)
          if (r.isComplete)
            AreaEntry(length: r.length!, width: r.width!, isCutout: r.isCutout),
      ],
      tileWidth: tw,
      tileHeight: th,
      grout: grout,
      wasteRate: wasteRate,
      tilesPerBox: tilesPerBox,
      pricePerBox: pricePerBox,
    ));
  }

  // ---- 区域行 ----

  void addRow({bool isCutout = false}) {
    if (rows.length >= maxRows) return;
    rows.add(AreaRowData(isCutout: isCutout));
    startEditing(FieldId(FieldKind.areaLength, rows.length - 1));
  }

  void removeRow(int index) {
    // 越界防护：多点触控可能对同一行触发两次删除
    if (index < 0 || index >= rows.length) return;
    rows.removeAt(index);
    if (rows.isEmpty) rows.add(AreaRowData());
    _stopEditing();
    notifyListeners();
  }

  // ---- 铺贴/箱规参数 ----

  void setPattern(LayoutPattern p) {
    pattern = p;
    notifyListeners();
  }

  void setCustomWaste(int pct) {
    customWastePct = pct.clamp(0, 30);
    notifyListeners();
  }

  void setTilePreset(Length w, Length h) {
    tileWidth = w;
    tileHeight = h;
    _stopEditing();
    notifyListeners();
  }

  void setBoxInfo({int? tilesPerBox, double? pricePerBox}) {
    this.tilesPerBox = tilesPerBox;
    this.pricePerBox = pricePerBox;
    notifyListeners();
  }

  // ---- History 快照与恢复 ----

  /// 当前状态的历史快照；无有效结果时返回 null（不记没算完的东西）。
  HistoryEntry? snapshot({DateTime? now}) {
    final r = result;
    if (r == null) return null;
    final time = now ?? DateTime.now();
    return HistoryEntry(
      id: time.microsecondsSinceEpoch,
      timestamp: time,
      unitSystem: _unitSystem,
      rows: [
        for (final row in rows)
          HistoryRow(
            lengthMm: row.length?.mm,
            widthMm: row.width?.mm,
            isCutout: row.isCutout,
          ),
      ],
      tileWidthMm: tileWidth!.mm,
      tileHeightMm: tileHeight!.mm,
      groutMm: grout.mm,
      patternName: pattern.name,
      customWastePct: customWastePct,
      tilesPerBox: tilesPerBox,
      pricePerBox: pricePerBox,
      netAreaSqM: r.netAreaSqM,
      tilesNeeded: r.tilesNeeded,
      boxes: r.boxes,
    );
  }

  /// 从历史条目回填表单。只回填数值（mm 基准跨单位制通用），
  /// 不切换当前单位制——英制记录在公制模式下显示换算值。
  void restoreFrom(HistoryEntry entry) {
    rows
      ..clear()
      ..addAll([
        for (final r in entry.rows)
          AreaRowData(isCutout: r.isCutout)
            ..length = r.lengthMm == null ? null : Length.ofMm(r.lengthMm!)
            ..width = r.widthMm == null ? null : Length.ofMm(r.widthMm!),
      ]);
    if (rows.isEmpty) rows.add(AreaRowData());
    tileWidth = Length.ofMm(entry.tileWidthMm);
    tileHeight = Length.ofMm(entry.tileHeightMm);
    grout = Length.ofMm(entry.groutMm);
    _groutTouched = true;
    // 未知 pattern 名（老版本读新数据）回退 straight
    pattern = LayoutPattern.values
        .where((p) => p.name == entry.patternName)
        .firstOrNull ??
        LayoutPattern.straight;
    customWastePct = entry.customWastePct;
    tilesPerBox = entry.tilesPerBox;
    pricePerBox = entry.pricePerBox;
    _stopEditing();
    notifyListeners();
  }

  // ---- 编辑焦点与键盘事件 ----

  /// 点击字段开始编辑：新开空编辑器（替换式录入），Done/Next 提交。
  void startEditing(FieldId field) {
    editing = field;
    if (_unitSystem == UnitSystem.imperial) {
      imperialEditor = ImperialEditor(
        kind: field.kind == FieldKind.areaLength ||
                field.kind == FieldKind.areaWidth
            ? ImperialFieldKind.feetAndInches
            : ImperialFieldKind.inchesOnly,
      );
      metricEditor = null;
    } else {
      metricEditor = MetricEditor(defaultUnit: _metricDefaultFor(field.kind));
      imperialEditor = null;
    }
    notifyListeners();
  }

  /// 字段默认单位：房间 m / 瓷砖 cm / 缝宽 mm（brief §3.2b）。
  static MetricUnit _metricDefaultFor(FieldKind kind) => switch (kind) {
        FieldKind.areaLength || FieldKind.areaWidth => MetricUnit.m,
        FieldKind.tileWidth || FieldKind.tileHeight => MetricUnit.cm,
        FieldKind.grout => MetricUnit.mm,
      };

  void _stopEditing() {
    editing = null;
    imperialEditor = null;
    metricEditor = null;
  }

  /// 把当前编辑器的值提交回字段；空编辑器不覆盖已有值。
  void _commit() {
    final field = editing;
    if (field == null) return;
    final value = imperialEditor?.value ?? metricEditor?.value;
    if (value == null) return;
    switch (field.kind) {
      case FieldKind.areaLength:
        rows[field.row].length = value;
      case FieldKind.areaWidth:
        rows[field.row].width = value;
      // 瓷砖尺寸提交 0 会使计算无意义（除以 0 面积），忽略提交保留旧值
      case FieldKind.tileWidth:
        if (value.mm > 0) tileWidth = value;
      case FieldKind.tileHeight:
        if (value.mm > 0) tileHeight = value;
      case FieldKind.grout:
        grout = value;
        _groutTouched = true;
    }
  }

  /// Done 键：提交并收起键盘。
  void commitAndClose() {
    _commit();
    _stopEditing();
    notifyListeners();
  }

  /// Next 键：提交并沿遍历顺序推进（行内 L→W → 下一行 → 瓷砖宽/长 → 缝宽 → 收起）。
  void commitAndNext() {
    final field = editing;
    if (field == null) return;
    _commit();
    final next = _nextField(field);
    if (next == null) {
      _stopEditing();
      notifyListeners();
    } else {
      startEditing(next);
    }
  }

  FieldId? _nextField(FieldId field) {
    switch (field.kind) {
      case FieldKind.areaLength:
        return FieldId(FieldKind.areaWidth, field.row);
      case FieldKind.areaWidth:
        if (field.row + 1 < rows.length) {
          return FieldId(FieldKind.areaLength, field.row + 1);
        }
        return const FieldId(FieldKind.tileWidth);
      case FieldKind.tileWidth:
        return const FieldId(FieldKind.tileHeight);
      case FieldKind.tileHeight:
        return const FieldId(FieldKind.grout);
      case FieldKind.grout:
        return null;
    }
  }

  // 键盘事件代理：转给当前活跃编辑器并刷新 UI。
  void keyDigit(int d) => _forward(() {
        imperialEditor?.digit(d);
        metricEditor?.digit(d);
      });
  void keyBackspace() => _forward(() {
        imperialEditor?.backspace();
        metricEditor?.backspace();
      });
  void keyClear() => _forward(() {
        imperialEditor?.clear();
        metricEditor?.clear();
      });
  void keyFt() => _forward(() => imperialEditor?.pressFt());
  void keyIn() => _forward(() => imperialEditor?.pressIn());
  void keyFraction(KeyFraction f) =>
      _forward(() => imperialEditor?.toggleFraction(f));
  void keyDecimal() => _forward(() => metricEditor?.decimal());
  void keyMetricUnit(MetricUnit u) =>
      _forward(() => metricEditor?.setUnit(u));

  void _forward(VoidCallback action) {
    if (editing == null) return;
    action();
    notifyListeners();
  }
}
