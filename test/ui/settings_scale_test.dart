import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilemath/main.dart';
import 'package:tilemath/state/settings_controller.dart';

/// 设置页的 Units 行原本把整个 SegmentedButton 塞进 ListTile.trailing，
/// trailing 会吃满整行宽度，标题被挤成负宽 → 布局链断裂。
/// 375dp 机型（SE / 13 mini）配 iOS 标准最大字号档（约 1.35）即可触发，
/// 不需要开启辅助功能。
void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'TileMath',
      packageName: 'com.tilemath.calculator',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  for (final width in [375.0, 393.0]) {
    for (final scale in [1.0, 1.35, 1.6]) {
      for (final lang in ['en', 'ar']) {
        testWidgets('设置页 ${width.toInt()}dp × 字号 $scale × $lang 不破版', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 812);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);
          tester.platformDispatcher.localesTestValue = [Locale(lang)];
          addTearDown(tester.platformDispatcher.clearLocalesTestValue);

          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: TileMathApp(prefs: prefs),
            ),
          );
          await tester.pump();

          await tester.tap(find.byIcon(Icons.settings_outlined));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          // 单位分段控件必须真实占位，不能被挤成 0 宽
          final seg = find.byType(SegmentedButton<UnitSystem>);
          expect(seg, findsOneWidget);
          expect(tester.getSize(seg).width, greaterThan(0));
        });
      }
    }
  }
}
