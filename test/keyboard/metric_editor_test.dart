import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/keyboard/metric_editor.dart';

void main() {
  group('基本输入与取值', () {
    test('房间字段默认 m：2.5 → 2500 mm', () {
      final e = MetricEditor(defaultUnit: MetricUnit.m);
      e.digit(2);
      e.decimal();
      e.digit(5);
      expect(e.text, '2.5');
      expect(e.value!.mm, closeTo(2500, 1e-9));
    });

    test('瓷砖字段默认 cm：30 → 300 mm', () {
      final e = MetricEditor(defaultUnit: MetricUnit.cm);
      e.digit(3);
      e.digit(0);
      expect(e.value!.mm, closeTo(300, 1e-9));
    });

    test('缝宽字段默认 mm：3 → 3 mm', () {
      final e = MetricEditor(defaultUnit: MetricUnit.mm);
      e.digit(3);
      expect(e.value!.mm, closeTo(3, 1e-9));
    });
  });

  group('单位键 = 改标签不换算（brief §3.2b 临时覆盖）', () {
    test('250 cm → 按 m 键 → 250 m', () {
      final e = MetricEditor(defaultUnit: MetricUnit.cm);
      e.digit(2);
      e.digit(5);
      e.digit(0);
      e.setUnit(MetricUnit.m);
      expect(e.text, '250');
      expect(e.unit, MetricUnit.m);
      expect(e.value!.meters, closeTo(250, 1e-9));
    });
  });

  group('小数分隔符', () {
    test('只允许一个分隔符，重复按忽略', () {
      final e = MetricEditor(defaultUnit: MetricUnit.m);
      e.digit(1);
      e.decimal();
      e.decimal();
      e.digit(5);
      expect(e.text, '1.5');
    });

    test('空态按分隔符 → 0.', () {
      final e = MetricEditor(defaultUnit: MetricUnit.m);
      e.decimal();
      expect(e.text, '0.');
      e.digit(5);
      expect(e.value!.meters, closeTo(0.5, 1e-9));
    });

    test('结尾悬空分隔符可取值：12. → 12', () {
      final e = MetricEditor(defaultUnit: MetricUnit.m);
      e.digit(1);
      e.digit(2);
      e.decimal();
      expect(e.value!.meters, closeTo(12, 1e-9));
    });
  });

  group('退格与清除', () {
    test('逐字符回退', () {
      final e = MetricEditor(defaultUnit: MetricUnit.m);
      e.digit(1);
      e.decimal();
      e.digit(5);
      e.backspace();
      expect(e.text, '1.');
      e.backspace();
      expect(e.text, '1');
      e.backspace();
      expect(e.text, '');
      e.backspace(); // 空态无副作用
      expect(e.isEmpty, isTrue);
    });

    test('clear 复位但保留字段默认单位', () {
      final e = MetricEditor(defaultUnit: MetricUnit.cm);
      e.digit(3);
      e.setUnit(MetricUnit.m);
      e.clear();
      expect(e.isEmpty, isTrue);
      expect(e.value, isNull);
      expect(e.unit, MetricUnit.cm);
    });
  });

  group('输入护栏', () {
    test('整数部分最多 5 位，超出忽略', () {
      final e = MetricEditor(defaultUnit: MetricUnit.mm);
      for (final d in [9, 9, 9, 9, 9, 9]) {
        e.digit(d);
      }
      expect(e.text, '99999');
    });

    test('小数部分最多 2 位，超出忽略', () {
      final e = MetricEditor(defaultUnit: MetricUnit.m);
      e.digit(1);
      e.decimal();
      for (final d in [2, 3, 4]) {
        e.digit(d);
      }
      expect(e.text, '1.23');
    });

    test('前导零替换：0 后按 5 → 5；0 后按 . → 0.', () {
      final e = MetricEditor(defaultUnit: MetricUnit.m);
      e.digit(0);
      e.digit(5);
      expect(e.text, '5');

      final e2 = MetricEditor(defaultUnit: MetricUnit.m);
      e2.digit(0);
      e2.decimal();
      expect(e2.text, '0.');
    });
  });

  group('空态', () {
    test('空 buffer value 为 null', () {
      expect(MetricEditor(defaultUnit: MetricUnit.m).value, isNull);
    });
  });
}
