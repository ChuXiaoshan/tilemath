import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilemath/history/history_controller.dart';
import 'package:tilemath/l10n/app_localizations.dart';
import 'package:tilemath/state/calculator_controller.dart';
import 'package:tilemath/state/settings_controller.dart';
import 'package:tilemath/ui/home_page.dart';

/// 共用测试 harness：手动组装 provider 树并 pump HomePage。
/// 初始单位制固定英制（占位），与 main.dart 的 TileMathApp 行为一致——
/// HomePage 首帧会按地区/设置自动同步，SettingsController 本身不持有
/// 未经地区解析的 unitSystem getter。
Future<CalculatorController> pumpHome(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsController(prefs);
  final calc = CalculatorController(UnitSystem.imperial);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: calc),
      ChangeNotifierProvider(create: (_) => HistoryController(prefs)),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomePage(),
    ),
  ));
  return calc;
}
