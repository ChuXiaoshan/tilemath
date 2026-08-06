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
