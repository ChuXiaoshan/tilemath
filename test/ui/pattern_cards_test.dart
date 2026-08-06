import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/tile_calculation.dart';
import 'test_harness.dart';

void main() {
  testWidgets('四张图案卡且高度一致（量尺寸）', (tester) async {
    await pumpHome(tester);
    final cards = find.byKey(const ValueKey('pattern-card-straight'))
        .evaluate()
        .toList();
    expect(cards, hasLength(1));
    final keys = ['straight', 'diagonal', 'herringbone', 'custom'];
    final heights = <double>{};
    for (final k in keys) {
      final f = find.byKey(ValueKey('pattern-card-$k'));
      expect(f, findsOneWidget);
      heights.add(tester.getSize(f).height);
    }
    expect(heights, hasLength(1)); // 四卡等高不跳动
  });

  testWidgets('点卡切换铺法；custom 出滑块', (tester) async {
    final calc = await pumpHome(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('pattern-card-herringbone')));
    await tester.tap(find.byKey(const ValueKey('pattern-card-herringbone')));
    await tester.pump();
    expect(calc.pattern, LayoutPattern.herringbone);
    expect(find.byType(Slider), findsNothing);

    await tester.tap(find.byKey(const ValueKey('pattern-card-custom')));
    await tester.pump();
    expect(calc.pattern, LayoutPattern.custom);
    expect(find.byType(Slider), findsOneWidget);
  });
}
