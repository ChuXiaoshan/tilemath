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
