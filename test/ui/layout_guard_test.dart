import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilemath/l10n/app_localizations.dart';
import 'package:tilemath/main.dart';

/// 上架前评估发现的两个布局/本地化缺陷回归（2026-07-27）。
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

  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(TileMathApp(prefs: prefs));
    await tester.pump();
  }

  // 双栏分支是为 ≥600dp 平板写的（键盘常驻左栏底部）。只判宽度的话，
  // iPhone 横屏（如 667×375）也会落进来，而横屏高度根本放不下常驻键盘：
  // 表单被压成 0 高、键盘下半截在屏幕外，既不能输入也不能收起。
  testWidgets('iPhone 横屏不得落入双栏常驻键盘布局', (tester) async {
    tester.view.physicalSize = const Size(667, 375);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);

    expect(tester.takeException(), isNull);
    // 区域行必须真实渲染出来（此前高度为 0、一个字段都不画）
    final field = find.byKey(const ValueKey('field-areaLength-0'));
    expect(field, findsOneWidget);
    expect(tester.getSize(field).height, greaterThan(0));
    // 未激活任何字段时键盘不应存在（双栏分支会无条件常驻）
    expect(find.text('Done'), findsNothing);
  });

  // gen-l10n 生成的 supportedLocales 按字母序排列，首项是 ar。设备语言若不在
  // en/zh/ar 之列（美区大量西班牙语用户），Flutter 的默认解析会回落到首项，
  // 首屏直接变成阿拉伯语 + 全屏 RTL。
  for (final locale in [
    const Locale('es', 'US'),
    const Locale('fr', 'FR'),
    const Locale('pt', 'BR'),
  ]) {
    testWidgets('设备语言 $locale 未受支持时回退英语而非阿拉伯语', (tester) async {
      tester.platformDispatcher.localesTestValue = [locale];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await pumpApp(tester);

      final resolved = Localizations.localeOf(
        tester.element(find.byType(Scaffold).first),
      );
      expect(resolved.languageCode, 'en');
      expect(find.text('AREAS'), findsOneWidget);
    });
  }

  testWidgets('设备语言受支持时仍按设备语言显示', (tester) async {
    tester.platformDispatcher.localesTestValue = [const Locale('zh', 'CN')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await pumpApp(tester);

    final context = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(context).languageCode, 'zh');
    expect(AppLocalizations.of(context).settings, isNotEmpty);
  });
}
