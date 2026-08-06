import 'package:flutter/foundation.dart';

import '../domain/length.dart';
import '../domain/materials_calculation.dart';
import '../domain/tile_calculation.dart';
import '../history/history_entry.dart';
import '../keyboard/imperial_editor.dart';
import '../keyboard/metric_editor.dart';
import 'settings_controller.dart';

/// 可编辑字段的种类。
enum FieldKind {
  areaLength,
  areaWidth,
  tileWidth,
  tileHeight,
  grout,
  tileThickness,
  jointDepth,
}

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

  /// 瓷砖厚度（材料估算用），默认英制 5/16″ / 公制 8mm，同 grout 的默认策略。
  late Length tileThickness;
  bool _thicknessTouched = false;

  /// 缝深：null = 跟随砖厚（spec §2.1）。
  Length? jointDepth;

  /// 镘刀：null = Auto 按砖尺寸推荐。
  Trowel? trowel;

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
    tileThickness = _defaultThickness(_unitSystem);
  }

  UnitSystem get unitSystem => _unitSystem;

  /// 默认缝宽：英制 1/16″（brief §3），公制 2 mm。
  static Length _defaultGrout(UnitSystem system) =>
      system == UnitSystem.imperial
          ? Length.imperial(sixteenths: 1)
          : Length.ofMm(2);

  /// 默认瓷砖厚度：英制 5/16″，公制 8mm。
  static Length _defaultThickness(UnitSystem system) =>
      system == UnitSystem.imperial
          ? Length.imperial(sixteenths: 5)
          : Length.ofMm(8);

  /// 单位制切换：已录入的 Length 值保留（mm 基准），未动过的缝宽/厚度换成新默认。
  /// 正在编辑的值先提交，不丢输入。
  set unitSystem(UnitSystem system) {
    if (system == _unitSystem) return;
    _commit();
    _unitSystem = system;
    if (!_groutTouched) grout = _defaultGrout(system);
    if (!_thicknessTouched) tileThickness = _defaultThickness(system);
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

  /// 材料估算派生结果；无有效结果或净面积为 0 时为 null（材料行整体隐藏）。
  /// 与 [result] 同契约：build 期读取永不抛错。
  MaterialsResult? get materialsResult {
    final r = result;
    final tw = tileWidth;
    final th = tileHeight;
    if (r == null || tw == null || th == null || r.netAreaSqM <= 0) {
      return null;
    }
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

  // ---- 区域行 ----

  void addRow({bool isCutout = false}) {
    if (rows.length >= maxRows) return;
    rows.add(AreaRowData(isCutout: isCutout));
    startEditing(FieldId(FieldKind.areaLength, rows.length - 1));
  }

  void removeRow(int index) {
    // 越界防护：多点触控可能对同一行触发两次删除
    if (index < 0 || index >= rows.length) return;
    // 删行前先提交在编辑的值（删的行本身被提交也无害，随行一起移除）
    _commit();
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
    _commit(); // 正在编辑的字段（如缝宽）先提交再收键盘
    tileWidth = w;
    tileHeight = h;
    _stopEditing();
    notifyListeners();
  }

  /// 箱规与单价来自系统数字键盘，没有 InputFormatter 约束，用户能直接打出 0
  /// （把 "10" 改成 "20" 的中间态也是 "0"）。非法值在此归一成"未填"，
  /// 否则会击穿 domain 层的参数断言，让 build 期读 [result] 抛错——
  /// 而 [result] 的契约正是"build 期读取永不抛错"。
  void setBoxInfo({int? tilesPerBox, double? pricePerBox}) {
    this.tilesPerBox = (tilesPerBox != null && tilesPerBox > 0)
        ? tilesPerBox
        : null;
    this.pricePerBox =
        (pricePerBox != null && pricePerBox.isFinite && pricePerBox >= 0)
        ? pricePerBox
        : null;
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
      tileThicknessMm: tileThickness.mm,
      jointDepthMm: jointDepth?.mm,
      trowelName: trowel?.name,
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
    tileThickness = Length.ofMm(entry.tileThicknessMm);
    _thicknessTouched = true;
    jointDepth =
        entry.jointDepthMm == null ? null : Length.ofMm(entry.jointDepthMm!);
    trowel = Trowel.values
        .where((t) => t.name == entry.trowelName)
        .firstOrNull; // 未知名回退 Auto（null）
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
  /// 从别的字段直接点过来 = 隐式确认当前输入（修：切字段丢值）。
  void startEditing(FieldId field) {
    _commit();
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
        FieldKind.tileThickness || FieldKind.jointDepth => MetricUnit.mm,
      };

  void _stopEditing() {
    editing = null;
    imperialEditor = null;
    metricEditor = null;
  }

  /// 把当前编辑器的值提交回字段。
  ///
  /// 空编辑器有两种语义，必须分开：没动过这个字段（保留旧值），
  /// 与用户按 C / 退格把它清空了（真的清掉）。此前一律按前者处理，
  /// 导致已录入的字段清不掉——按 C 看着空了，按 Done 旧值又回来。
  /// 缝宽是非空字段（模型上无空态，有单位制默认值），不参与清空。
  void _commit() {
    final field = editing;
    if (field == null) return;
    final value = imperialEditor?.value ?? metricEditor?.value;
    if (value == null) {
      final cleared =
          imperialEditor?.clearedByUser ?? metricEditor?.clearedByUser ?? false;
      if (!cleared) return;
      switch (field.kind) {
        case FieldKind.areaLength:
          rows[field.row].length = null;
        case FieldKind.areaWidth:
          rows[field.row].width = null;
        case FieldKind.tileWidth:
          tileWidth = null;
        case FieldKind.tileHeight:
          tileHeight = null;
        case FieldKind.grout:
          break; // 非空字段，无空态
        case FieldKind.tileThickness:
          break; // 非空字段（有默认值），不参与清空
        case FieldKind.jointDepth:
          jointDepth = null; // 清空 = 回到跟随砖厚
      }
      return;
    }
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
      case FieldKind.tileThickness:
        if (value.mm > 0) {
          tileThickness = value;
          _thicknessTouched = true;
        }
      case FieldKind.jointDepth:
        jointDepth = value;
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
      case FieldKind.tileThickness:
        return const FieldId(FieldKind.jointDepth);
      case FieldKind.jointDepth:
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
