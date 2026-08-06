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

  test('restoreFrom 遇损坏数据（厚度 0 / 越界 waste）回退默认且 result 可安全读取', () {
    final c = filledController();
    final entry = c.snapshot()!;

    // pattern 强制 custom：customWastePct 只在 custom 铺法下才会经 wasteRate
    // 传导进 domain 层（其它铺法用固定 wasteRate），不这样设护栏就测不出来。
    final corrupted = HistoryEntry.fromJson(
      entry.toJson()
        ..['thick'] = 0
        ..['customWaste'] = 99
        ..['pattern'] = 'custom',
    );

    final fresh = CalculatorController(UnitSystem.imperial);
    fresh.restoreFrom(corrupted);

    // 厚度 ≤0 回退当前单位制默认值（英制 5/16"），不接受损坏数据
    expect(fresh.tileThickness.mm, closeTo(7.9375, 1e-9));
    // customWastePct 越界回退 clamp(0, 30) 上限
    expect(fresh.customWastePct, 30);

    // 契约核心：materialsResult/result 在 build 期读取不得抛错
    expect(() => fresh.result, returnsNormally);
    expect(() => fresh.materialsResult, returnsNormally);
    expect(fresh.result, isNotNull);
    expect(fresh.materialsResult, isNotNull);
  });
}
