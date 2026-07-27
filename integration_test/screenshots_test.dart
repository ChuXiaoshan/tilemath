import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilemath/main.dart';

/// App Store 截图生成。不是断言测试，目的是把 app 驱动到若干目标画面，
/// 每到一处就通过 takeScreenshot 通知宿主机用 simctl 抓图（见
/// test_driver/integration_test.dart）。
///
/// 跑法（模拟器需已启动并设为目标语言/地区）：
///   fvm flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/screenshots_test.dart \
///     -d `simulator-udid`
///
/// 产物在 build/screenshots/，脚本会校验像素尺寸并剥离 alpha 通道。
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'TileMath',
      packageName: 'com.tilemath.calculator',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('生成商店截图', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(TileMathApp(prefs: prefs));
    await tester.pumpAndSettle();

    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    Future<void> tapText(String label) async {
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
    }

    // ---- 01 分数键盘：唯一的硬差异化，必须占住前三张之一 ----
    // 录入 12′ 3-1/2″，停在分数键选中态，让键盘和实时回显同框
    await tester.tap(find.byKey(const ValueKey('field-areaLength-0')));
    await tester.pumpAndSettle();
    await tapText('1');
    await tapText('2');
    await tapText('ft');
    await tapText('3');
    await tapText('1/2');
    await shot('01-fraction-keypad');

    // ---- 02 结果卡：补齐宽度与瓷砖规格，出片数/损耗 ----
    await tapText('Next');
    await tapText('1');
    await tapText('0');
    await tapText('ft');
    await tapText('Done');
    await tapText('12×12');
    await shot('02-results');

    // ---- 03 铺贴方式：人字铺 20% 损耗 ----
    await tapText('Herringbone');
    await shot('03-layout-pattern');

    // ---- 04 多区域：一单多房间 ----
    await tapText('Straight');
    await tapText('Add area');
    await tester.tap(find.byKey(const ValueKey('field-areaLength-1')));
    await tester.pumpAndSettle();
    await tapText('8');
    await tapText('ft');
    await tapText('Next');
    await tapText('6');
    await tapText('ft');
    await tapText('Done');
    // 两个区域把内容撑长了，不滚动的话结果卡会被屏幕下沿切断
    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await shot('04-multiple-areas');

    // ---- 05 历史记录 ----
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    await shot('05-history');
  });
}
