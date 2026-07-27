import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'history/history_controller.dart';
import 'l10n/app_localizations.dart';
import 'state/calculator_controller.dart';
import 'state/settings_controller.dart';
import 'theme/app_theme.dart';
import 'ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(TileMathApp(prefs: prefs));
}

class TileMathApp extends StatelessWidget {
  final SharedPreferences prefs;

  const TileMathApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController(prefs)),
        ChangeNotifierProvider(create: (_) => HistoryController(prefs)),
        // 初始单位制给英制占位，HomePage 首帧按地区/设置同步
        ChangeNotifierProvider(
          create: (_) => CalculatorController(UnitSystem.imperial),
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          locale: settings.localeOverride,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomePage(),
        ),
      ),
    );
  }
}
