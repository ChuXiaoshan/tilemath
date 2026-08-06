import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/domain/length.dart';
import 'package:tilemath/domain/materials_calculation.dart';
import 'package:tilemath/domain/tile_calculation.dart';
import 'package:tilemath/l10n/app_localizations.dart';
import 'package:tilemath/state/settings_controller.dart';
import 'package:tilemath/ui/format.dart';
import 'package:tilemath/ui/pattern_preview.dart';
import 'package:tilemath/ui/result_card.dart';

void main() {
  test('formatGroutAmount 主次单位随单位制', () {
    expect(formatGroutAmount(1.967, UnitSystem.imperial, 'en'),
        '≈ 4.3 lb (2.0 kg)');
    expect(formatGroutAmount(1.967, UnitSystem.metric, 'en'),
        '≈ 2.0 kg (4.3 lb)');
  });

  Widget host(ResultCard card) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: card)),
      );

  final result = calculateTiles(TileCalcInput(
    areas: [
      AreaEntry(
        length: Length.imperial(feet: 12),
        width: Length.imperial(feet: 10),
      ),
    ],
    tileWidth: Length.ofInches(12),
    tileHeight: Length.ofInches(12),
    grout: Length.imperial(sixteenths: 1),
    wasteRate: 0.10,
  ));
  final materials = calculateMaterials(MaterialsInput(
    tileWidth: Length.ofInches(12),
    tileHeight: Length.ofInches(12),
    grout: Length.imperial(sixteenths: 1),
    tileThickness: Length.imperial(sixteenths: 5),
    jointDepth: null,
    trowel: null,
    netAreaSqM: result.netAreaSqM,
    wasteRate: 0.10,
  ));

  testWidgets('完整态：预览 84dp + 材料两行 + 免责', (tester) async {
    await tester.pumpWidget(host(ResultCard(
      result: result,
      materials: materials,
      tileWidth: Length.ofInches(12),
      tileHeight: Length.ofInches(12),
      grout: Length.imperial(sixteenths: 1),
      pattern: LayoutPattern.straight,
      unitSystem: UnitSystem.imperial,
      currencySymbol: r'$',
      wastePct: 10,
    )));
    final preview = find.byType(PatternPreview);
    expect(preview, findsOneWidget);
    expect(tester.getSize(preview), const Size(84, 84)); // 量尺寸
    expect(find.byKey(const ValueKey('grout-row')), findsOneWidget);
    expect(find.byKey(const ValueKey('thinset-row')), findsOneWidget);
    expect(find.byKey(const ValueKey('materials-disclaimer')), findsOneWidget);
  });

  testWidgets('窄双栏(246dp)+120预览+herringbone：大数字防裁切，预览列不挤压', (tester) async {
    // 模拟 iPad 分屏窄双栏场景：卡片宽度收窄到 246dp，herringbone 的
    // 铺法名较长，caption 若不封顶列宽会把大数字挤裁切/溢出。
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 246,
            child: ResultCard(
              result: result,
              materials: materials,
              tileWidth: Length.ofInches(12),
              tileHeight: Length.ofInches(12),
              grout: Length.imperial(sixteenths: 1),
              pattern: LayoutPattern.herringbone,
              unitSystem: UnitSystem.imperial,
              currencySymbol: r'$',
              wastePct: 10,
              previewSize: 120,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // 无溢出异常：修复前预览列无界宽度会把 Row 挤出可用宽度。
    expect(tester.takeException(), isNull);

    // 预览列宽度封顶：无论 caption 多长，预览图恒为 120×120（不被撑宽）。
    final preview = find.byType(PatternPreview);
    expect(tester.getSize(preview), const Size(120, 120));

    // 大数字防裁切：FittedBox 缩小后仍落在其容器可用宽度内（量尺寸）。
    final fittedBox = find.byType(FittedBox);
    expect(fittedBox, findsOneWidget);
    final numberContainer = find
        .ancestor(of: fittedBox, matching: find.byType(Container))
        .first;
    final containerSize = tester.getSize(numberContainer);
    final fittedBoxSize = tester.getSize(fittedBox);
    expect(fittedBoxSize.width, lessThanOrEqualTo(containerSize.width));
  });

  testWidgets('materials 为 null 时材料行与免责整体隐藏', (tester) async {
    await tester.pumpWidget(host(ResultCard(
      result: result,
      materials: null,
      tileWidth: Length.ofInches(12),
      tileHeight: Length.ofInches(12),
      grout: Length.imperial(sixteenths: 1),
      pattern: LayoutPattern.straight,
      unitSystem: UnitSystem.imperial,
      currencySymbol: r'$',
      wastePct: 10,
    )));
    expect(find.byKey(const ValueKey('grout-row')), findsNothing);
    expect(find.byKey(const ValueKey('materials-disclaimer')), findsNothing);
  });

  testWidgets('空态不画预览', (tester) async {
    await tester.pumpWidget(host(const ResultCard(
      result: null,
      materials: null,
      tileWidth: null,
      tileHeight: null,
      grout: null,
      pattern: null,
      unitSystem: UnitSystem.imperial,
      currencySymbol: r'$',
      wastePct: 10,
    )));
    expect(find.byType(PatternPreview), findsNothing);
  });
}
