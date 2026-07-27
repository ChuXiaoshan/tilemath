import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilemath/domain/length.dart';
import 'package:tilemath/state/calculator_controller.dart';
import 'package:tilemath/keyboard/metric_editor.dart';
import 'package:tilemath/l10n/app_localizations.dart';
import 'package:tilemath/main.dart';
import 'package:tilemath/ui/format.dart';

/// 上架前评估"建议修"里与显示相关的几条回归（2026-07-27）。
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

  group('公制回显不丢精度', () {
    // 按 m 保两位小数只有 1cm 分辨率：cm 键输入的 12.5 会显示成 0.13 m，
    // 值错了 4%，用户会以为输入没被接收。
    test('不足 1 m 的值降级用 cm 显示', () {
      expect(formatMetric(Length.ofCm(12.5), MetricUnit.m, 'en_US'), '12.5 cm');
      expect(formatMetric(Length.ofCm(90), MetricUnit.m, 'en_US'), '90 cm');
    });

    test('1 m 及以上仍用 m', () {
      expect(formatMetric(Length.ofMeters(3), MetricUnit.m, 'en_US'), '3 m');
      expect(
        formatMetric(Length.ofMeters(3.25), MetricUnit.m, 'en_US'),
        '3.25 m',
      );
    });

    test('一位小数够用时不补第二位', () {
      expect(formatMetric(Length.ofCm(12.5), MetricUnit.cm, 'en_US'), '12.5 cm');
      expect(formatMetric(Length.ofCm(12), MetricUnit.cm, 'en_US'), '12 cm');
    });

    test('显式指定 cm/mm 的字段不受降级影响', () {
      expect(formatMetric(Length.ofMm(2), MetricUnit.mm, 'en_US'), '2 mm');
      expect(formatMetric(Length.ofCm(30), MetricUnit.cm, 'en_US'), '30 cm');
    });
  });

  testWidgets('所需瓷砖标签区分单复数', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SizedBox.shrink(),
      ),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(SizedBox)));
    expect(l10n.tilesNeededLabel(1), 'tile needed');
    expect(l10n.tilesNeededLabel(2), 'tiles needed');
  });

  // 12′ 11-7/8″ 的固有宽度约 181dp，而区域字段可用宽只有 95–123dp。
  // 不加约束会折成 2–3 行、字段高度随输入跳动。
  testWidgets('分数值不换行，字段高度不随输入跳动', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(TileMathApp(prefs: prefs));
    await tester.pump();

    final field = find.byKey(const ValueKey('field-areaLength-0'));
    final emptyHeight = tester.getSize(field).height;

    // 输入最长形态 12′ 11-7/8″
    await tester.tap(field);
    await tester.pump();
    for (final key in ['1', '2']) {
      await tester.tap(find.text(key));
    }
    await tester.tap(find.text('ft'));
    await tester.pump();
    for (final key in ['1', '1']) {
      await tester.tap(find.text(key));
    }
    await tester.tap(find.text('7/8'));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(field).height,
      emptyHeight,
      reason: '长值必须缩放而不是换行，否则字段高度会跳',
    );
  });

  // 从历史恢复等外部改值时，箱规/成本两个系统输入框此前不同步：
  // 屏上显示失效旧值，结果卡按恢复值算。
  testWidgets('外部改值时箱规输入框跟随更新', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(TileMathApp(prefs: prefs));
    await tester.pump();

    await tester.tap(find.text('Boxes & cost'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '10');
    await tester.pump();

    String tilesText() => tester
        .widget<TextField>(find.byType(TextField).first)
        .controller!
        .text;

    final calc = tester
        .element(find.byType(Scaffold).first)
        .read<CalculatorController>();

    // 输入框仍有焦点时不得被覆盖——那会打断正在打字的用户
    calc.setBoxInfo(tilesPerBox: 99, pricePerBox: null);
    await tester.pumpAndSettle();
    expect(tilesText(), '10', reason: '有焦点时不能抢用户正在输入的内容');

    // 真实场景：历史恢复发生在另一个页面，回来时字段没有焦点
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    calc.setBoxInfo(tilesPerBox: 25, pricePerBox: 40);
    await tester.pumpAndSettle();

    expect(tilesText(), '25', reason: '屏上显示的数必须与参与计算的数一致');
  });
}
