import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilemath/main.dart';

/// 自定义损耗滑块每跨一个刻度给一次轻触反馈。
/// 关键是**判重**：Slider 在同一刻度内会连续回调 onChanged，
/// 不判重就会变成拖动期间的持续震动。
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

  testWidgets('损耗滑块跨刻度才震动，同刻度内重复回调不震', (tester) async {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(TileMathApp(prefs: prefs));
    await tester.pump();

    // 滑块只在 Custom 铺法下出现
    // 分段控件内的名称 Text 外面套了 FittedBox，会命中两个同名 Text
    await tester.tap(find.text('Custom').last);
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);

    Slider slider() => tester.widget<Slider>(find.byType(Slider));

    slider().onChanged!(15.0);
    await tester.pumpAndSettle();
    expect(haptics.length, 1);
    expect(haptics.single, 'HapticFeedbackType.selectionClick');

    // 同一刻度内的连续回调不得再震
    slider().onChanged!(15.2);
    slider().onChanged!(14.8);
    await tester.pumpAndSettle();
    expect(haptics.length, 1, reason: '同刻度内重复回调会造成持续震动');

    // 跨到下一刻度才再震一次
    slider().onChanged!(16.0);
    await tester.pumpAndSettle();
    expect(haptics.length, 2);
  });
}
