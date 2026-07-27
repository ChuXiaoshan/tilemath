import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/length.dart';
import 'package:tilemath/state/calculator_controller.dart';
import 'package:tilemath/state/settings_controller.dart';

/// 空编辑器有两种语义，必须分开：没动过这个字段（保留旧值），
/// 与用户按 C / 退格把它清空了（真的清掉）。
/// 此前一律按前者处理 → 已录入的字段清不掉：按 C 看着空了，按 Done 旧值又回来。
void main() {
  CalculatorController imperial() {
    final c = CalculatorController(UnitSystem.imperial);
    c.rows[0]
      ..length = Length.imperial(feet: 12)
      ..width = Length.imperial(feet: 10);
    c.tileWidth = Length.imperial(inches: 12);
    c.tileHeight = Length.imperial(inches: 12);
    return c;
  }

  test('按 C 清空后提交，字段真的被清掉', () {
    final c = imperial();
    c.startEditing(const FieldId(FieldKind.areaLength, 0));
    c.keyClear();
    c.commitAndClose();
    expect(c.rows[0].length, isNull);
  });

  test('退格到空后提交，字段真的被清掉', () {
    final c = imperial();
    c.startEditing(const FieldId(FieldKind.areaWidth, 0));
    c.keyBackspace();
    c.keyBackspace();
    c.keyBackspace();
    c.commitAndClose();
    expect(c.rows[0].width, isNull);
  });

  test('只是聚焦没动过，提交后旧值保留', () {
    final c = imperial();
    final before = c.rows[0].length;
    c.startEditing(const FieldId(FieldKind.areaLength, 0));
    c.commitAndClose();
    expect(c.rows[0].length, before);
    expect(c.rows[0].length, isNotNull);
  });

  test('清空后又输入新值，提交的是新值而非 null', () {
    final c = imperial();
    c.startEditing(const FieldId(FieldKind.areaLength, 0));
    c.keyClear();
    c.keyDigit(8);
    c.keyFt();
    c.commitAndClose();
    expect(c.rows[0].length?.mm, Length.imperial(feet: 8).mm);
  });

  test('瓷砖尺寸同样可清空，且清空后 result 不抛错', () {
    final c = imperial();
    c.startEditing(const FieldId(FieldKind.tileWidth));
    c.keyClear();
    c.commitAndClose();
    expect(c.tileWidth, isNull);
    expect(() => c.result, returnsNormally);
    expect(c.result, isNull);
  });

  test('缝宽是非空字段，清空不生效（模型上无空态）', () {
    final c = imperial();
    final before = c.grout.mm;
    c.startEditing(const FieldId(FieldKind.grout));
    c.keyClear();
    c.commitAndClose();
    expect(c.grout.mm, before);
  });

  test('公制编辑器同样区分"没动过"与"清空"', () {
    final c = CalculatorController(UnitSystem.metric);
    c.rows[0].length = Length.ofMeters(3);

    c.startEditing(const FieldId(FieldKind.areaLength, 0));
    c.commitAndClose();
    expect(c.rows[0].length, isNotNull, reason: '没动过应保留');

    c.startEditing(const FieldId(FieldKind.areaLength, 0));
    c.keyClear();
    c.commitAndClose();
    expect(c.rows[0].length, isNull, reason: '显式清空应清掉');
  });
}
