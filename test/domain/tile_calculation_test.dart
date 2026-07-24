import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/length.dart';
import 'package:tilemath/domain/tile_calculation.dart';

/// brief §3.4 黄金用例：120 ft² / 12×12 in / 无缝 / 10% 损耗
/// → 120 片 → 132 片 → 8 片/箱 = 17 箱 → $25/箱 = $425.00
TileCalcInput goldenInput({int? tilesPerBox, double? pricePerBox}) {
  return TileCalcInput(
    areas: [
      AreaEntry(
        length: Length.imperial(feet: 12),
        width: Length.imperial(feet: 10),
      ),
    ],
    tileWidth: Length.ofInches(12),
    tileHeight: Length.ofInches(12),
    grout: Length.ofMm(0),
    wasteRate: 0.10,
    tilesPerBox: tilesPerBox,
    pricePerBox: pricePerBox,
  );
}

void main() {
  group('黄金用例（brief §3.4）', () {
    test('120 ft² → 120 片基数 → 132 片含损耗', () {
      final r = calculateTiles(goldenInput());
      expect(r.baseTiles, 120);
      expect(r.tilesNeeded, 132);
      expect(r.netAreaSqM, closeTo(120 * 0.3048 * 0.3048, 1e-6));
    });

    test('箱数与成本：17 箱 / \$425.00', () {
      final r = calculateTiles(goldenInput(tilesPerBox: 8, pricePerBox: 25));
      expect(r.boxes, 17);
      expect(r.cost, closeTo(425.00, 1e-9));
    });

    test('未填箱规时 boxes/cost 为 null（结果卡整行隐藏）', () {
      final r = calculateTiles(goldenInput());
      expect(r.boxes, isNull);
      expect(r.cost, isNull);
    });

    test('只填箱规未填单价：有箱数无成本', () {
      final r = calculateTiles(goldenInput(tilesPerBox: 8));
      expect(r.boxes, 17);
      expect(r.cost, isNull);
    });
  });

  group('缝宽参与铺贴节距', () {
    test('300×300 砖 + 3mm 缝：10 m² → ceil(1e7/303²) = 109', () {
      final r = calculateTiles(TileCalcInput(
        areas: [
          AreaEntry(
            length: Length.ofMeters(5),
            width: Length.ofMeters(2),
          ),
        ],
        tileWidth: Length.ofCm(30),
        tileHeight: Length.ofCm(30),
        grout: Length.ofMm(3),
        wasteRate: 0,
      ));
      expect(r.baseTiles, 109);
      expect(r.tilesNeeded, 109);
    });
  });

  group('扣除区域（cutout）', () {
    test('净面积 = 区域和 − 扣除和', () {
      final r = calculateTiles(TileCalcInput(
        areas: [
          AreaEntry(
            length: Length.ofMeters(5),
            width: Length.ofMeters(4),
          ),
          AreaEntry(
            length: Length.ofMeters(2),
            width: Length.ofMeters(1),
            isCutout: true,
          ),
        ],
        tileWidth: Length.ofMeters(1),
        tileHeight: Length.ofMeters(1),
        grout: Length.ofMm(0),
        wasteRate: 0,
      ));
      expect(r.netAreaSqM, closeTo(18, 1e-9));
      expect(r.baseTiles, 18);
    });

    test('扣除超过区域：净面积钳到 0，0 片', () {
      final r = calculateTiles(TileCalcInput(
        areas: [
          AreaEntry(
            length: Length.ofMeters(1),
            width: Length.ofMeters(1),
          ),
          AreaEntry(
            length: Length.ofMeters(3),
            width: Length.ofMeters(3),
            isCutout: true,
          ),
        ],
        tileWidth: Length.ofCm(30),
        tileHeight: Length.ofCm(30),
        grout: Length.ofMm(0),
        wasteRate: 0.1,
      ));
      expect(r.netAreaSqM, 0);
      expect(r.baseTiles, 0);
      expect(r.tilesNeeded, 0);
    });
  });

  group('小面积提示（< 2 m²）', () {
    test('1.5 m² 触发；2.5 m² 不触发', () {
      TileCalcInput at(double sqm) => TileCalcInput(
            areas: [
              AreaEntry(
                length: Length.ofMeters(sqm),
                width: Length.ofMeters(1),
              ),
            ],
            tileWidth: Length.ofCm(30),
            tileHeight: Length.ofCm(30),
            grout: Length.ofMm(0),
            wasteRate: 0,
          );
      expect(calculateTiles(at(1.5)).smallAreaHint, isTrue);
      expect(calculateTiles(at(2.5)).smallAreaHint, isFalse);
    });
  });

  group('输入校验', () {
    test('瓷砖尺寸为 0 抛错', () {
      expect(
        () => calculateTiles(TileCalcInput(
          areas: [
            AreaEntry(
              length: Length.ofMeters(1),
              width: Length.ofMeters(1),
            ),
          ],
          tileWidth: Length.ofMm(0),
          tileHeight: Length.ofCm(30),
          grout: Length.ofMm(0),
          wasteRate: 0,
        )),
        throwsArgumentError,
      );
    });

    test('损耗率越界抛错（合法域 0–0.30）', () {
      TileCalcInput at(double rate) => TileCalcInput(
            areas: [
              AreaEntry(
                length: Length.ofMeters(1),
                width: Length.ofMeters(1),
              ),
            ],
            tileWidth: Length.ofCm(30),
            tileHeight: Length.ofCm(30),
            grout: Length.ofMm(0),
            wasteRate: rate,
          );
      expect(() => calculateTiles(at(-0.01)), throwsArgumentError);
      expect(() => calculateTiles(at(0.31)), throwsArgumentError);
      // 边界合法
      expect(calculateTiles(at(0)).tilesNeeded, greaterThan(0));
      expect(calculateTiles(at(0.30)).tilesNeeded, greaterThan(0));
    });
  });

  group('LayoutPattern 预设损耗率', () {
    test('Straight 10% / Diagonal 15% / Herringbone 20%', () {
      expect(LayoutPattern.straight.wasteRate, 0.10);
      expect(LayoutPattern.diagonal.wasteRate, 0.15);
      expect(LayoutPattern.herringbone.wasteRate, 0.20);
    });
  });
}
