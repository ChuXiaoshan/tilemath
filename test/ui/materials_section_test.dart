import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/materials_calculation.dart';
import 'package:tilemath/ui/keyboard/tile_keyboard.dart';
import 'test_harness.dart';

void main() {
  testWidgets('默认收起，回显「厚度 · Auto」摘要；展开出三组控件', (tester) async {
    await pumpHome(tester);
    expect(find.byKey(const ValueKey('materials-summary')), findsOneWidget);
    expect(find.byKey(const ValueKey('field-tileThickness--1')), findsNothing);

    await tester.ensureVisible(find.byKey(const ValueKey('materials-header')));
    // ensureVisible 默认 duration=zero 走 jumpTo，需要一帧 pump 才能让新滚动
    // 位置反映到渲染树，否则 tap() 命中的还是滚动前的旧坐标。
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('materials-header')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('field-tileThickness--1')), findsOneWidget);
    // jointDepth 默认 null（跟随砖厚，calculator_controller.dart 注释），
    // 展开态渲染的是「= 砖厚」占位而非可编辑字段，key 是 field-jointDepth-follow。
    expect(find.byKey(const ValueKey('field-jointDepth-follow')), findsOneWidget);
    // 5 个档位 chip：Auto + 4 档
    expect(find.byKey(const ValueKey('trowel-chip-auto')), findsOneWidget);
    for (final t in Trowel.values) {
      expect(find.byKey(ValueKey('trowel-chip-${t.name}')), findsOneWidget);
    }

    // 量尺寸：Auto + 4 档共 5 个 chip，触摸高度 ≥44
    final chipFinders = [
      find.byKey(const ValueKey('trowel-chip-auto')),
      for (final t in Trowel.values) find.byKey(ValueKey('trowel-chip-${t.name}')),
    ];
    expect(chipFinders, hasLength(5));
    for (final f in chipFinders) {
      expect(tester.getSize(f).height, greaterThanOrEqualTo(44));
    }
  });

  testWidgets('点档位 chip 改 controller；再点 Auto 回推荐', (tester) async {
    final calc = await pumpHome(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('materials-header')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('materials-header')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('trowel-chip-square12')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('trowel-chip-square12')));
    await tester.pump();
    expect(calc.trowel, Trowel.square12);
    await tester.tap(find.byKey(const ValueKey('trowel-chip-auto')));
    await tester.pump();
    expect(calc.trowel, isNull);
  });

  testWidgets('展开态编辑砖厚后收起 Materials：提交并清编辑态，键盘随之消失', (tester) async {
    final calc = await pumpHome(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('materials-header')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('materials-header')));
    await tester.pumpAndSettle();

    // 点砖厚字段开始编辑，此时自定义键盘应出现。
    await tester.ensureVisible(find.byKey(const ValueKey('field-tileThickness--1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('field-tileThickness--1')));
    await tester.pump();
    expect(calc.editing, isNotNull);
    expect(find.byType(TileKeyboard), findsOneWidget);

    // 收起 Materials：应等价于系统键盘随子树移除——提交并清编辑态。
    // 展开态下 'materials-header' 匹配的是整个 ExpansionTile（含子项），
    // tap() 取其包围盒中心会落在展开的子内容区而非头部行；改用头部行内
    // 恒可见的 'materials-summary' 作为点击目标，确保命中折叠触发区。
    await tester.ensureVisible(find.byKey(const ValueKey('materials-summary')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('materials-summary')));
    await tester.pumpAndSettle();
    expect(calc.editing, isNull);
    expect(find.byType(TileKeyboard), findsNothing);
  });
}
