import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/length.dart';
import 'package:tilemath/keyboard/imperial_editor.dart';

void main() {
  group('流程 A：12 ft 3-1/2 in（口述顺序输入）', () {
    test('数字进 feet 段 → ft 键确认并推进到 inch 段 → 分数落 inch', () {
      final e = ImperialEditor();
      expect(e.activeSegment, ImperialSegment.feet);

      e.digit(1);
      e.digit(2);
      expect(e.feetText, '12');

      e.pressFt(); // 确认 feet，推进 inch 段
      expect(e.activeSegment, ImperialSegment.inches);

      e.digit(3);
      e.toggleFraction(KeyFraction.half);
      expect(e.inchText, '3');
      expect(e.selectedFraction, KeyFraction.half);

      expect(e.value!.mm, closeTo(Length.imperial(feet: 12, inches: 3, sixteenths: 8).mm, 1e-9));
      expect(e.displayText, '12′ 3-1/2″');
    });
  });

  group('流程 B：30 in（后置单位标注重新归段）', () {
    test('feet 段的数字被 in 键改判为英寸', () {
      final e = ImperialEditor();
      e.digit(3);
      e.digit(0);
      e.pressIn();
      expect(e.feetText, '');
      expect(e.inchText, '30');
      expect(e.activeSegment, ImperialSegment.inches);
      expect(e.value!.inches, closeTo(30, 1e-9));
    });

    test('对称：inch 段数字被 ft 键改判为英尺（无分数时）', () {
      final e = ImperialEditor(kind: ImperialFieldKind.feetAndInches);
      e.pressIn(); // 空切到 inch 段
      e.digit(1);
      e.digit(2);
      e.pressFt();
      expect(e.feetText, '12');
      expect(e.inchText, '');
      // 改判后推进到 inch 段，接续口述顺序
      expect(e.activeSegment, ImperialSegment.inches);
    });
  });

  group('分数键切换语义（brief §3.2：激活态，再点取消，点别的替换）', () {
    test('再点同一分数取消', () {
      final e = ImperialEditor();
      e.toggleFraction(KeyFraction.quarter);
      expect(e.selectedFraction, KeyFraction.quarter);
      e.toggleFraction(KeyFraction.quarter);
      expect(e.selectedFraction, isNull);
    });

    test('点其他分数替换而非叠加', () {
      final e = ImperialEditor();
      e.toggleFraction(KeyFraction.quarter);
      e.toggleFraction(KeyFraction.threeEighths);
      expect(e.selectedFraction, KeyFraction.threeEighths);
      expect(e.value!.mm, closeTo(Length.imperial(sixteenths: 6).mm, 1e-9));
    });

    test('按分数键自动把激活段带到 inch', () {
      final e = ImperialEditor();
      expect(e.activeSegment, ImperialSegment.feet);
      e.toggleFraction(KeyFraction.sixteenth);
      expect(e.activeSegment, ImperialSegment.inches);
    });

    test('纯分数值（默认缝宽 1/16″ 的输入形态）', () {
      final e = ImperialEditor(kind: ImperialFieldKind.inchesOnly);
      e.toggleFraction(KeyFraction.sixteenth);
      expect(e.displayText, '1/16″');
      expect(e.value!.mm, closeTo(25.4 / 16, 1e-9));
    });
  });

  group('退格逐段回退：分数 → inch 数字 → feet 数字', () {
    test('inch 段激活时：先删分数，再删 inch 数字，空了退到 feet', () {
      final e = ImperialEditor();
      e.digit(1);
      e.digit(2);
      e.pressFt();
      e.digit(3);
      e.toggleFraction(KeyFraction.half);

      e.backspace();
      expect(e.selectedFraction, isNull);
      expect(e.inchText, '3');

      e.backspace();
      expect(e.inchText, '');

      e.backspace(); // inch 段已空 → 落到 feet 段删
      expect(e.feetText, '1');
      expect(e.activeSegment, ImperialSegment.feet);
    });

    test('feet 段激活时删 feet，不动 inch', () {
      final e = ImperialEditor();
      e.digit(1);
      e.digit(2);
      e.pressFt();
      e.digit(3);
      e.pressFt(); // 回 feet 段再编辑
      expect(e.activeSegment, ImperialSegment.feet);
      e.backspace();
      expect(e.feetText, '1');
      expect(e.inchText, '3');
    });

    test('全空时退格无副作用', () {
      final e = ImperialEditor();
      e.backspace();
      expect(e.isEmpty, isTrue);
    });
  });

  group('ft 键在 feet 段 = 确认推进；in 键在 inch 段 = 无操作', () {
    test('ft/ft 连按不产生位移以外的副作用', () {
      final e = ImperialEditor();
      e.digit(5);
      e.pressFt();
      e.pressIn(); // inch 段无内容，仅保持
      expect(e.feetText, '5');
      expect(e.activeSegment, ImperialSegment.inches);
    });
  });

  group('inchesOnly 字段（瓷砖尺寸/缝宽）', () {
    test('默认激活 inch 段，ft 键无效', () {
      final e = ImperialEditor(kind: ImperialFieldKind.inchesOnly);
      expect(e.activeSegment, ImperialSegment.inches);
      e.digit(1);
      e.digit(2);
      e.pressFt();
      expect(e.feetText, '');
      expect(e.inchText, '12');
      expect(e.activeSegment, ImperialSegment.inches);
    });
  });

  group('输入护栏', () {
    test('feet 最多 3 位，inch 最多 2 位，超出忽略', () {
      final e = ImperialEditor();
      for (final d in [9, 9, 9, 9]) {
        e.digit(d);
      }
      expect(e.feetText, '999');
      e.pressFt();
      for (final d in [9, 9, 9]) {
        e.digit(d);
      }
      expect(e.inchText, '99');
    });

    test('前导零被替换：0 后按 5 → 5', () {
      final e = ImperialEditor();
      e.digit(0);
      e.digit(5);
      expect(e.feetText, '5');
    });
  });

  group('清除与空态', () {
    test('clear 全量复位', () {
      final e = ImperialEditor();
      e.digit(1);
      e.pressFt();
      e.digit(2);
      e.toggleFraction(KeyFraction.half);
      e.clear();
      expect(e.isEmpty, isTrue);
      expect(e.value, isNull);
      expect(e.activeSegment, ImperialSegment.feet);
    });

    test('空态 value 为 null（字段显示占位符）', () {
      expect(ImperialEditor().value, isNull);
    });
  });

  group('显示文本（编辑态实时拼装，真撇号）', () {
    test('只有 feet：12′', () {
      final e = ImperialEditor();
      e.digit(1);
      e.digit(2);
      expect(e.displayText, '12′');
    });

    test('feet + 整 inch：12′ 3″', () {
      final e = ImperialEditor();
      e.digit(1);
      e.digit(2);
      e.pressFt();
      e.digit(3);
      expect(e.displayText, '12′ 3″');
    });
  });

  group('改判护栏（review 确认缺陷回归）', () {
    test('已确认的 feet 不被纯导航改判：12→ft→ft→in 保持 12′', () {
      final e = ImperialEditor();
      e.digit(1);
      e.digit(2);
      e.pressFt(); // 确认 12′
      e.pressFt(); // 回 feet 段
      e.pressIn(); // 只是切回 inch 段，不得改判
      expect(e.feetText, '12');
      expect(e.inchText, '');
      expect(e.activeSegment, ImperialSegment.inches);
      expect(e.value!.mm, closeTo(Length.imperial(feet: 12).mm, 1e-9));
    });

    test('pressIn 改判与 pressFt 对称：有分数时不改判', () {
      final e = ImperialEditor();
      e.toggleFraction(KeyFraction.half); // 1/2″，active=inch
      e.pressFt(); // 切到 feet 段
      e.digit(1);
      e.digit(2); // feet 缓冲 12（未确认）
      e.pressIn(); // 分数在场：只移动激活态，不得把 12 并进 inch
      expect(e.feetText, '12');
      expect(e.inchText, '');
      expect(e.selectedFraction, KeyFraction.half);
      expect(e.activeSegment, ImperialSegment.inches);
    });

    test('3 位 feet 缓冲不绕过 inch 两位上限：999→in 不改判', () {
      final e = ImperialEditor();
      for (final d in [9, 9, 9]) {
        e.digit(d);
      }
      e.pressIn();
      expect(e.feetText, '999');
      expect(e.inchText, '');
      expect(e.activeSegment, ImperialSegment.inches);
    });

    test('退格清空 feet 后重新输入的数字恢复可改判', () {
      final e = ImperialEditor();
      e.digit(1);
      e.pressFt(); // 确认 1′
      e.pressFt(); // 回 feet 段
      e.backspace(); // feet 清空，确认标记应复位
      e.digit(3);
      e.digit(0);
      e.pressIn(); // 30 是新的孤立数字 → 应改判为 30″
      expect(e.feetText, '');
      expect(e.inchText, '30');
    });
  });

  group('KeyFraction 八键面板', () {
    test('sixteenths 值与键帽顺序（brief §3.2 布局）', () {
      expect(KeyFraction.values.map((f) => f.sixteenths).toList(),
          [1, 2, 4, 8, 3, 6, 12, 14]);
      expect(KeyFraction.half.label, '1/2');
      expect(KeyFraction.threeSixteenths.label, '3/16');
    });
  });
}
