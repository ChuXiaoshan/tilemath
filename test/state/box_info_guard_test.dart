import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/length.dart';
import 'package:tilemath/state/calculator_controller.dart';
import 'package:tilemath/state/settings_controller.dart';

/// 箱规/成本两个字段来自系统数字键盘，没有 InputFormatter 兜底，
/// 用户能直接打出 0（也可能是编辑 "10"→"20" 过程中的中间态）。
/// result getter 的契约是「build 期读取永不抛错」，必须在这里挡住非法值，
/// 否则整页会被 ErrorWidget 顶掉、History 按钮同时失效。
CalculatorController _withValidResult() {
  final c = CalculatorController(UnitSystem.imperial);
  c.rows[0]
    ..length = Length.imperial(feet: 12)
    ..width = Length.imperial(feet: 10);
  c.tileWidth = Length.imperial(inches: 12);
  c.tileHeight = Length.imperial(inches: 12);
  return c;
}

void main() {
  test('前置条件：基础输入能算出结果', () {
    expect(_withValidResult().result, isNotNull);
  });

  test('每箱片数为 0 不抛异常，按未填处理', () {
    final c = _withValidResult();
    c.setBoxInfo(tilesPerBox: 0, pricePerBox: null);
    expect(() => c.result, returnsNormally);
    expect(c.result!.boxes, isNull);
  });

  test('每箱片数为负不抛异常', () {
    final c = _withValidResult();
    c.setBoxInfo(tilesPerBox: -3, pricePerBox: null);
    expect(() => c.result, returnsNormally);
    expect(c.result!.boxes, isNull);
  });

  test('单价为负或非有限值不抛异常，不产生 Infinity 成本', () {
    final c = _withValidResult();
    c.setBoxInfo(tilesPerBox: 10, pricePerBox: -5);
    expect(() => c.result, returnsNormally);
    expect(c.result!.cost, isNull);

    c.setBoxInfo(tilesPerBox: 10, pricePerBox: double.infinity);
    expect(() => c.result, returnsNormally);
    expect(c.result!.cost, anyOf(isNull, predicate<double>((v) => v.isFinite)));
  });

  test('合法箱规仍正常参与计算', () {
    final c = _withValidResult();
    c.setBoxInfo(tilesPerBox: 10, pricePerBox: 20);
    final r = c.result!;
    expect(r.boxes, isNotNull);
    expect(r.cost, isNotNull);
  });
}
