import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/length.dart';

void main() {
  group('Length 构造与换算（mm 基准）', () {
    test('公制构造', () {
      expect(Length.ofMm(1).mm, 1);
      expect(Length.ofCm(1).mm, 10);
      expect(Length.ofMeters(1).mm, 1000);
      expect(Length.ofMeters(2.5).mm, 2500);
    });

    test('英制构造：1 in = 25.4 mm 精确', () {
      expect(Length.ofInches(1).mm, 25.4);
      expect(Length.imperial(feet: 1).mm, closeTo(304.8, 1e-9));
      // 5′ 3-1/2″ = 63.5 in = 1612.9 mm
      expect(
        Length.imperial(feet: 5, inches: 3, sixteenths: 8).mm,
        closeTo(1612.9, 1e-9),
      );
    });

    test('反向读数', () {
      expect(Length.ofMeters(2.5).meters, closeTo(2.5, 1e-9));
      expect(Length.ofCm(30).cm, closeTo(30, 1e-9));
      expect(Length.ofMm(25.4).inches, closeTo(1, 1e-9));
    });

    test('负长度构造抛错', () {
      expect(() => Length.ofMm(-1), throwsArgumentError);
      expect(() => Length.imperial(feet: -1), throwsArgumentError);
    });
  });

  group('toImperialParts：就近取 1/16 并归约', () {
    test('精确值往返：5′ 3-1/2″', () {
      final p = Length.imperial(feet: 5, inches: 3, sixteenths: 8)
          .toImperialParts();
      expect(p.feet, 5);
      expect(p.inches, 3);
      expect(p.numerator, 1);
      expect(p.denominator, 2);
    });

    test('分数归约：4/16 → 1/4，6/16 → 3/8', () {
      final quarter =
          Length.imperial(inches: 0, sixteenths: 4).toImperialParts();
      expect((quarter.numerator, quarter.denominator), (1, 4));
      final threeEighths =
          Length.imperial(sixteenths: 6).toImperialParts();
      expect((threeEighths.numerator, threeEighths.denominator), (3, 8));
    });

    test('mm 输入吸附到最近 1/16', () {
      // 1612.93 mm ≈ 63.5012 in → 仍是 5′ 3-1/2″
      final p = Length.ofMm(1612.93).toImperialParts();
      expect((p.feet, p.inches, p.numerator, p.denominator), (5, 3, 1, 2));
    });

    test('进位：15.97/16″ 吸附后进到整寸、12 in 进到 1 ft', () {
      // 11 in + 15.9/16 in ≈ 靠近 12 in → 1 ft 整
      final nearFoot = Length.ofInches(11 + 15.9 / 16).toImperialParts();
      expect((nearFoot.feet, nearFoot.inches), (1, 0));
      expect(nearFoot.numerator, 0);
    });

    test('零值', () {
      final p = Length.ofMm(0).toImperialParts();
      expect((p.feet, p.inches, p.numerator), (0, 0, 0));
    });
  });

  group('formatImperial：真撇号 U+2032/U+2033', () {
    test('全段：12′ 3-1/2″', () {
      final l = Length.imperial(feet: 12, inches: 3, sixteenths: 8);
      expect(formatImperial(l), '12′ 3-1/2″');
    });

    test('无英尺段：3-1/2″', () {
      final l = Length.imperial(inches: 3, sixteenths: 8);
      expect(formatImperial(l), '3-1/2″');
    });

    test('整英尺：12′', () {
      expect(formatImperial(Length.imperial(feet: 12)), '12′');
    });

    test('纯分数：1/16″（默认缝宽的显示形态）', () {
      expect(formatImperial(Length.imperial(sixteenths: 1)), '1/16″');
    });

    test('零：0″', () {
      expect(formatImperial(Length.ofMm(0)), '0″');
    });
  });
}
