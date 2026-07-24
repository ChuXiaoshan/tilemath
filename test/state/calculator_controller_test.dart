import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/length.dart';
import 'package:tilemath/domain/tile_calculation.dart';
import 'package:tilemath/history/history_entry.dart';
import 'package:tilemath/state/calculator_controller.dart';
import 'package:tilemath/state/settings_controller.dart';

void main() {
  group('零尺寸护栏（review 确认缺陷回归）', () {
    test('瓷砖宽输入 0 提交：忽略提交，result 不抛错', () {
      final c = CalculatorController(UnitSystem.imperial);
      c.startEditing(const FieldId(FieldKind.tileWidth));
      c.keyDigit(0);
      c.commitAndClose(); // 0″ 不得写入
      expect(c.tileWidth, isNull);
      expect(() => c.result, returnsNormally);
    });

    test('tileWidth 被直接置 0 时 result 返回 null 而非抛 ArgumentError', () {
      final c = CalculatorController(UnitSystem.metric);
      c.rows[0]
        ..length = Length.ofMeters(2)
        ..width = Length.ofMeters(2);
      c.tileWidth = Length.ofMm(0);
      c.tileHeight = Length.ofCm(30);
      expect(c.result, isNull);
    });

    test('正常输入仍然出结果', () {
      final c = CalculatorController(UnitSystem.metric);
      c.rows[0]
        ..length = Length.ofMeters(2)
        ..width = Length.ofMeters(2);
      c.tileWidth = Length.ofCm(30);
      c.tileHeight = Length.ofCm(30);
      expect(c.result, isNotNull);
    });
  });

  group('History 快照与恢复', () {
    CalculatorController filled() {
      final c = CalculatorController(UnitSystem.metric);
      c.rows[0]
        ..length = Length.ofMeters(5)
        ..width = Length.ofMeters(2);
      c.tileWidth = Length.ofCm(30);
      c.tileHeight = Length.ofCm(30);
      c.grout = Length.ofMm(3);
      c.setPattern(LayoutPattern.diagonal);
      c.setBoxInfo(tilesPerBox: 8, pricePerBox: 25);
      return c;
    }

    test('snapshot：结果非空时产出完整快照', () {
      final c = filled();
      final s = c.snapshot(now: DateTime(2026, 7, 24, 15))!;
      expect(s.unitSystem, UnitSystem.metric);
      expect(s.rows.single.lengthMm, 5000);
      expect(s.tileWidthMm, 300);
      expect(s.groutMm, 3);
      expect(s.patternName, 'diagonal');
      expect(s.tilesPerBox, 8);
      expect(s.tilesNeeded, c.result!.tilesNeeded);
      expect(s.timestamp, DateTime(2026, 7, 24, 15));
    });

    test('snapshot：无结果时返回 null', () {
      final c = CalculatorController(UnitSystem.metric);
      expect(c.snapshot(now: DateTime(2026, 7, 24)), isNull);
    });

    test('restore：回填全部输入并复算出同样结果', () {
      final source = filled();
      final snap = source.snapshot(now: DateTime(2026, 7, 24, 15))!;

      final target = CalculatorController(UnitSystem.metric);
      target.restoreFrom(snap);
      expect(target.rows.single.length!.mm, 5000);
      expect(target.tileWidth!.cm, closeTo(30, 1e-9));
      expect(target.grout.mm, 3);
      expect(target.pattern, LayoutPattern.diagonal);
      expect(target.tilesPerBox, 8);
      expect(target.result!.tilesNeeded, source.result!.tilesNeeded);
    });

    test('restore：未知 pattern 名回退 straight（向前兼容）', () {
      final snap = filled().snapshot(now: DateTime(2026, 7, 24))!;
      final tampered = HistoryEntry.fromJson(
        snap.toJson()..['pattern'] = 'zigzag',
      );
      final target = CalculatorController(UnitSystem.metric);
      target.restoreFrom(tampered);
      expect(target.pattern, LayoutPattern.straight);
    });
  });

  group('切换焦点隐式提交（用户实测缺陷回归：切字段丢值）', () {
    test('长度输 20 → 直接点宽度：长度已提交不丢失', () {
      final c = CalculatorController(UnitSystem.metric);
      c.startEditing(const FieldId(FieldKind.areaLength, 0));
      c.keyDigit(2);
      c.keyDigit(0);
      c.startEditing(const FieldId(FieldKind.areaWidth, 0)); // 不按 Done/Next
      expect(c.rows[0].length, isNotNull);
      expect(c.rows[0].length!.meters, closeTo(20, 1e-9));
      expect(c.editing, const FieldId(FieldKind.areaWidth, 0));
    });

    test('英制同样成立：20 → 点宽度 → 20′ 已落', () {
      final c = CalculatorController(UnitSystem.imperial);
      c.startEditing(const FieldId(FieldKind.areaLength, 0));
      c.keyDigit(2);
      c.keyDigit(0);
      c.startEditing(const FieldId(FieldKind.areaWidth, 0));
      expect(c.rows[0].length!.feet, closeTo(20, 1e-9));
    });

    test('空编辑器切走不覆盖已有值', () {
      final c = CalculatorController(UnitSystem.metric);
      c.rows[0].length = Length.ofMeters(5);
      c.startEditing(const FieldId(FieldKind.areaLength, 0)); // 打开但不输入
      c.startEditing(const FieldId(FieldKind.areaWidth, 0));
      expect(c.rows[0].length!.meters, closeTo(5, 1e-9));
    });

    test('编辑缝宽时点预设 chip：缝宽先提交再收键盘', () {
      final c = CalculatorController(UnitSystem.metric);
      c.startEditing(const FieldId(FieldKind.grout));
      c.keyDigit(5);
      c.setTilePreset(Length.ofCm(30), Length.ofCm(30));
      expect(c.grout.mm, closeTo(5, 1e-9));
      expect(c.editing, isNull);
    });

    test('编辑中切单位制：先提交再切', () {
      final c = CalculatorController(UnitSystem.metric);
      c.startEditing(const FieldId(FieldKind.areaLength, 0));
      c.keyDigit(3);
      c.unitSystem = UnitSystem.imperial;
      expect(c.rows[0].length!.meters, closeTo(3, 1e-9)); // mm 基准跨制保值
      expect(c.editing, isNull);
    });

    test('编辑 0 行时删除 1 行：编辑值先提交', () {
      final c = CalculatorController(UnitSystem.metric);
      c.addRow(); // 自动聚焦新行，先切回 0 行
      c.startEditing(const FieldId(FieldKind.areaLength, 0));
      c.keyDigit(7);
      c.removeRow(1);
      expect(c.rows[0].length!.meters, closeTo(7, 1e-9));
    });
  });

  group('removeRow 越界防护', () {
    test('越界 index 静默忽略（多点触控连删场景）', () {
      final c = CalculatorController(UnitSystem.metric);
      c.addRow();
      expect(c.rows.length, 2);
      c.removeRow(1);
      expect(c.rows.length, 1);
      expect(() => c.removeRow(1), returnsNormally); // 已删过，越界
      expect(() => c.removeRow(-1), returnsNormally);
      expect(c.rows.length, 1);
    });
  });
}
