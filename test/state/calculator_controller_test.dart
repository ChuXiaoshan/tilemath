import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/length.dart';
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
