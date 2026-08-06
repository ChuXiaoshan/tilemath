import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/length.dart';
import 'package:tilemath/domain/materials_calculation.dart';

/// 设计稿 10a 黄金用例：净面积 129.3333 ft²（12.01555 m²）、12×12″ 砖、
/// 1/16″ 缝、5/16″ 厚、直铺 10% 损耗。
/// 手算：(304.8+304.8)/(304.8×304.8)×7.9375×1.5875×1.8×12.01555×1.1 ≈ 1.967 kg
MaterialsInput goldenInput({Length? jointDepth, Trowel? trowel}) => MaterialsInput(
      tileWidth: Length.ofInches(12),
      tileHeight: Length.ofInches(12),
      grout: Length.imperial(sixteenths: 1),
      tileThickness: Length.imperial(sixteenths: 5),
      jointDepth: jointDepth,
      trowel: trowel,
      netAreaSqM: 129.3333 * 0.3048 * 0.3048,
      wasteRate: 0.10,
    );

void main() {
  group('填缝剂', () {
    test('黄金用例 ≈1.967 kg / 4.34 lb', () {
      final r = calculateMaterials(goldenInput());
      expect(r.groutKg, closeTo(1.967, 0.005));
      expect(r.groutLb, closeTo(r.groutKg * 2.20462, 1e-9));
    });
    test('缝宽 0 → 0 kg', () {
      final input = MaterialsInput(
        tileWidth: Length.ofInches(12),
        tileHeight: Length.ofInches(12),
        grout: Length.ofMm(0),
        tileThickness: Length.ofMm(8),
        jointDepth: null,
        trowel: null,
        netAreaSqM: 10,
        wasteRate: 0.10,
      );
      expect(calculateMaterials(input).groutKg, 0);
    });
    test('缝深默认跟随砖厚，超过砖厚被 clamp', () {
      final follow = calculateMaterials(goldenInput());
      expect(follow.jointDepth.mm, closeTo(7.9375, 1e-9));
      final over = calculateMaterials(goldenInput(jointDepth: Length.ofMm(20)));
      expect(over.jointDepth.mm, closeTo(7.9375, 1e-9)); // clamp 到砖厚
      final under = calculateMaterials(goldenInput(jointDepth: Length.ofMm(4)));
      expect(under.groutKg, closeTo(1.967 * 4 / 7.9375, 0.005));
    });
  });

  group('胶粘剂', () {
    test('黄金用例 Auto → 1/4″×3/8″ → 142.27 ft² / 60 = 3 袋（50 lb）', () {
      final r = calculateMaterials(goldenInput());
      expect(r.trowel, Trowel.notch1438);
      expect(r.thinsetBags50Lb, 3);
      // 公制袋规：13.217 m² / 4.9 = 2.697 → 3 袋
      expect(r.thinsetBags20Kg, 3);
    });
    test('手动选大齿档覆盖率变小', () {
      final r = calculateMaterials(goldenInput(trowel: Trowel.square12));
      expect(r.trowel, Trowel.square12);
      expect(r.thinsetBags50Lb, 4); // 142.27 / 45 = 3.16 → 4
    });
    test('净面积 0 → 全 0', () {
      final input = MaterialsInput(
        tileWidth: Length.ofInches(12),
        tileHeight: Length.ofInches(12),
        grout: Length.imperial(sixteenths: 1),
        tileThickness: Length.ofMm(8),
        jointDepth: null,
        trowel: null,
        netAreaSqM: 0,
        wasteRate: 0.10,
      );
      final r = calculateMaterials(input);
      expect(r.groutKg, 0);
      expect(r.thinsetBags50Lb, 0);
      expect(r.thinsetBags20Kg, 0);
    });
  });

  group('Auto 镘刀档位边界（max 边判定）', () {
    Trowel rec(double wMm, double hMm) =>
        recommendTrowel(Length.ofMm(wMm), Length.ofMm(hMm));
    test('≤100mm → 3/16″ V', () {
      expect(rec(100, 50), Trowel.vNotch316);
    });
    test('100–220mm → 1/4″×1/4″', () {
      expect(rec(101, 50), Trowel.square14);
      expect(rec(152, 152), Trowel.square14); // 6×6″
      expect(rec(220, 100), Trowel.square14);
    });
    test('220–420mm → 1/4″×3/8″', () {
      expect(rec(221, 100), Trowel.notch1438);
      expect(rec(305, 305), Trowel.notch1438); // 12×12″
      expect(rec(420, 100), Trowel.notch1438);
    });
    test('>420mm → 1/2″×1/2″', () {
      expect(rec(421, 100), Trowel.square12);
      expect(rec(305, 610), Trowel.square12); // 12×24″ 按 max 边
    });
  });

  group('参数断言', () {
    test('砖厚 ≤0 抛 ArgumentError', () {
      expect(
        () => calculateMaterials(MaterialsInput(
          tileWidth: Length.ofInches(12),
          tileHeight: Length.ofInches(12),
          grout: Length.ofMm(2),
          tileThickness: Length.ofMm(0),
          jointDepth: null,
          trowel: null,
          netAreaSqM: 10,
          wasteRate: 0.10,
        )),
        throwsArgumentError,
      );
    });
  });
}
