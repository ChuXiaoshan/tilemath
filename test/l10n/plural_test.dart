import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilemath/l10n/app_localizations.dart';

/// 带计数的文案必须走 ICU 复数，不能拼字符串。
/// wasteLine 曾在真机上显示成 "1 tiles + 10% waste"（2026-07-27 实测发现）。
Future<AppLocalizations> _load(WidgetTester tester, String languageCode) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(languageCode),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SizedBox.shrink(),
    ),
  );
  return AppLocalizations.of(tester.element(find.byType(SizedBox)));
}

void main() {
  testWidgets('英文损耗行区分单复数', (tester) async {
    final l10n = await _load(tester, 'en');
    expect(l10n.wasteLine(1, 10), '1 tile + 10% waste');
    expect(l10n.wasteLine(2, 10), '2 tiles + 10% waste');
    expect(l10n.wasteLine(119, 10), '119 tiles + 10% waste');
  });

  testWidgets('中文损耗行无单复数变化', (tester) async {
    final l10n = await _load(tester, 'zh');
    expect(l10n.wasteLine(1, 10), '1 片 + 10% 损耗');
    expect(l10n.wasteLine(119, 10), '119 片 + 10% 损耗');
  });

  testWidgets('阿语损耗行按 6 种复数形式取词', (tester) async {
    final l10n = await _load(tester, 'ar');
    // 单数/双数用专门词形，不带数字；3-10 走 few，11+ 走 many
    expect(l10n.wasteLine(1, 10), contains('واحدة'));
    expect(l10n.wasteLine(2, 10), contains('بلاطتان'));
    expect(l10n.wasteLine(5, 10), contains('بلاطات'));
    expect(l10n.wasteLine(119, 10), contains('119'));
  });

  testWidgets('片数与箱数同样区分单复数', (tester) async {
    final l10n = await _load(tester, 'en');
    expect(l10n.tilesCount(1), '1 tile');
    expect(l10n.tilesCount(2), '2 tiles');
    expect(l10n.boxesCount(1), '1 box');
    expect(l10n.boxesCount(2), '2 boxes');
  });
}
