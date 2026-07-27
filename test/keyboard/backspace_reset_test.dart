import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/keyboard/imperial_editor.dart';

/// 退格清空后必须与 clear() 落到同一状态。否则字段看着是空的，
/// 激活段却仍停在 inch，用户重新输入的 12 会被当成 12″ 而非 12′——
/// 每个维度差 12 倍，且屏上只有 ′ / ″ 一撇之差，极难察觉。
void main() {
  ImperialEditor feetAndInches() =>
      ImperialEditor(kind: ImperialFieldKind.feetAndInches);

  test('经 ft 标注后退格到空，重新输入仍归 feet 段', () {
    final e = feetAndInches()
      ..digit(1)
      ..digit(2)
      ..pressFt()
      ..backspace()
      ..backspace();
    expect(e.isEmpty, isTrue);

    e
      ..digit(1)
      ..digit(2);
    final fresh = feetAndInches()
      ..digit(1)
      ..digit(2);
    expect(e.value?.mm, fresh.value?.mm);
    expect(e.displayText, fresh.displayText);
  });

  test('经 in 改判后退格到空，重新输入必须回到 feet 段而非继续算英寸', () {
    // 12 → in（改判到英寸段）→ 退格清空 → 再输 12
    final e = feetAndInches()
      ..digit(1)
      ..digit(2)
      ..pressIn()
      ..backspace()
      ..backspace();
    expect(e.isEmpty, isTrue);

    e
      ..digit(1)
      ..digit(2);
    final fresh = feetAndInches()
      ..digit(1)
      ..digit(2);
    expect(
      e.value?.mm,
      fresh.value?.mm,
      reason: '字段看着是空的，重新输入却被当英寸，结果每维差 12 倍',
    );
  });

  test('经分数键改判后退格到空，重新输入回到 feet 段', () {
    final e = feetAndInches()
      ..digit(3)
      ..toggleFraction(KeyFraction.half)
      ..backspace() // 去掉分数
      ..backspace(); // 去掉 3
    expect(e.isEmpty, isTrue);

    e.digit(3);
    final fresh = feetAndInches()..digit(3);
    expect(e.value?.mm, fresh.value?.mm);
  });

  test('退格清空与 clear 落到同一状态', () {
    final viaBackspace = feetAndInches()
      ..digit(9)
      ..pressFt()
      ..backspace()
      ..digit(8);
    final viaClear = feetAndInches()
      ..digit(9)
      ..pressFt()
      ..clear()
      ..digit(8);
    expect(viaBackspace.value?.mm, viaClear.value?.mm);
    expect(viaBackspace.displayText, viaClear.displayText);
  });

  test('仅英寸字段退格到空后仍停在 inch 段', () {
    final e = ImperialEditor(kind: ImperialFieldKind.inchesOnly)
      ..digit(7)
      ..backspace();
    expect(e.isEmpty, isTrue);
    e.digit(7);
    final fresh = ImperialEditor(kind: ImperialFieldKind.inchesOnly)..digit(7);
    expect(e.value?.mm, fresh.value?.mm);
  });
}
