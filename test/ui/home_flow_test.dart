import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilemath/history/history_controller.dart';
import 'package:tilemath/main.dart';
import 'package:tilemath/ui/keyboard/tile_keyboard.dart';

/// 端到端冒烟：英制键盘录入 12′ × 10′ + 12×12 预设 → 结果卡出数。
/// 测试环境 locale 为 en_US → 地区默认英制。
/// 预期：默认缝宽 1/16″ 参与节距 → base 119，+10%（Straight 默认）→ 131。
void main() {
  testWidgets('英制输入闭环冒烟', (tester) async {
    // 手机竖屏尺寸（单栏 + 键盘常驻可见）
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(TileMathApp(prefs: prefs));
    await tester.pump();

    // 空态提示在
    expect(find.text('Enter dimensions to see results'), findsOneWidget);

    // 先选瓷砖预设 12×12（这样最后 Done 时已有完整输入，验证历史落档）
    await tester.tap(find.text('12×12'));
    await tester.pump();

    // Length：12 → ft 键 → Done
    await tester.tap(find.byKey(const ValueKey('field-areaLength-0')));
    await tester.pump();
    // 滚动动画（激活字段自动滚入视口，若触发）
    await tester.pump(const Duration(milliseconds: 250));

    // brief §3.2 硬性要求：激活字段不被键盘遮挡（字段底沿在键盘上沿之上）
    final fieldRect =
        tester.getRect(find.byKey(const ValueKey('field-areaLength-0')));
    final keyboardRect = tester.getRect(find.byType(TileKeyboard));
    expect(fieldRect.bottom, lessThanOrEqualTo(keyboardRect.top));

    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('ft'));
    await tester.pump();
    expect(find.text('12′'), findsOneWidget); // 编辑态实时显示

    // Next 推进到 Width：10 → ft → Done 收起
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.tap(find.text('0'));
    await tester.tap(find.text('ft'));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pump();

    // 行尾实时面积
    expect(find.text('120.00 ft²'), findsWidgets);

    // 结果卡：131 片（119 base + 10%）
    expect(find.text('131'), findsOneWidget);
    expect(find.text('119 tiles + 10% waste'), findsOneWidget);
    // 未填箱规：无箱数/成本行
    expect(find.text('Boxes to buy'), findsNothing);

    // Done 产生有效结果 → 历史落一条
    final historyController = tester
        .element(find.byType(Scaffold).first)
        .read<HistoryController>();
    expect(historyController.entries.length, 1);
    expect(historyController.entries.single.tilesNeeded, 131);
  });
}
