import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilemath/history/history_controller.dart';
import 'package:tilemath/history/history_entry.dart';
import 'package:tilemath/l10n/app_localizations.dart';
import 'package:tilemath/state/calculator_controller.dart';
import 'package:tilemath/state/settings_controller.dart';
import 'package:tilemath/ui/history_page.dart';

HistoryEntry entryAt(DateTime time, {double lengthMm = 3657.6}) => HistoryEntry(
      id: time.microsecondsSinceEpoch,
      timestamp: time,
      unitSystem: UnitSystem.imperial,
      rows: [HistoryRow(lengthMm: lengthMm, widthMm: 3048.0, isCutout: false)],
      tileWidthMm: 304.8,
      tileHeightMm: 304.8,
      groutMm: 0,
      tileThicknessMm: 7.9375,
      jointDepthMm: null,
      trowelName: null,
      patternName: 'diagonal',
      customWastePct: 10,
      tilesPerBox: 8,
      pricePerBox: 25,
      netAreaSqM: 11.1483648,
      tilesNeeded: 132,
      boxes: 17,
    );

void main() {
  late HistoryController history;
  late CalculatorController calc;

  Future<void> pumpHistoryPage(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    history = HistoryController(prefs);
    calc = CalculatorController(UnitSystem.imperial);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: history),
          ChangeNotifierProvider.value(value: calc),
          ChangeNotifierProvider(create: (_) => SettingsController(prefs)),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: HistoryPage(),
        ),
      ),
    );
  }

  testWidgets('空态 → 有记录 → 点击恢复表单并返回', (tester) async {
    await pumpHistoryPage(tester);
    expect(find.text('Your calculations will appear here.'), findsOneWidget);

    history.record(entryAt(DateTime(2026, 7, 24, 10)));
    await tester.pump();

    // 主行：面积 · 片数；次行：箱数 · 成本 · 砖规+铺法（设计稿 5a 两行结构）
    expect(find.textContaining('120.00 ft²'), findsOneWidget);
    expect(find.textContaining('132 tiles'), findsOneWidget);
    expect(find.textContaining('17 boxes'), findsOneWidget);
    expect(find.textContaining(r'$425.00'), findsOneWidget);
    expect(find.textContaining('12×12'), findsOneWidget);
    // 定位注脚在列表尾部
    expect(
      find.text('Every calculation is saved — free, no limit.'),
      findsOneWidget,
    );

    await tester.tap(find.textContaining('132 tiles'));
    await tester.pumpAndSettle();

    // 表单已恢复
    expect(calc.rows.single.length!.mm, closeTo(3657.6, 1e-9));
    expect(calc.pattern.name, 'diagonal');
    expect(calc.tilesPerBox, 8);
    expect(calc.result!.tilesNeeded, greaterThan(0));
  });

  testWidgets('左滑删除单条', (tester) async {
    await pumpHistoryPage(tester);
    history.record(entryAt(DateTime(2026, 7, 24, 10)));
    history.record(entryAt(DateTime(2026, 7, 24, 11), lengthMm: 5000));
    await tester.pump();
    expect(history.entries.length, 2);

    await tester.drag(
      find.textContaining('132 tiles').first,
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(history.entries.length, 1);
  });

  testWidgets('清空全部需二次确认', (tester) async {
    await pumpHistoryPage(tester);
    history.record(entryAt(DateTime(2026, 7, 24, 10)));
    await tester.pump();

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    expect(find.text('Delete all history?'), findsOneWidget);

    // 先取消：不删
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(history.entries.length, 1);

    // 再确认：清空回到空态
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(history.entries, isEmpty);
    expect(find.text('Your calculations will appear here.'), findsOneWidget);
    // 设计稿 5a：空态 Clear all 置灰不隐藏
    expect(find.text('Clear all'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(
            find.ancestor(
              of: find.text('Clear all'),
              matching: find.byType(TextButton),
            ),
          )
          .onPressed,
      isNull,
    );
  });

  group('相对时间', () {
    test('分桶：刚刚/分钟/小时/天/日期', () async {
      SharedPreferences.setMockInitialValues({});
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final now = DateTime(2026, 7, 24, 12);
      String at(Duration ago) =>
          formatRelativeTime(now.subtract(ago), l10n, 'en', now: now);
      expect(at(const Duration(seconds: 30)), 'Just now');
      expect(at(const Duration(minutes: 2)), '2 minutes ago');
      expect(at(const Duration(hours: 1)), '1 hour ago');
      expect(at(const Duration(days: 3)), '3 days ago');
      expect(at(const Duration(days: 30)), 'Jun 24, 2026');
    });
  });
}
