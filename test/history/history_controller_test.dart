import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilemath/history/history_controller.dart';
import 'package:tilemath/history/history_entry.dart';
import 'package:tilemath/state/settings_controller.dart';

HistoryEntry entryWith({
  required DateTime time,
  double lengthMm = 3657.6,
  double widthMm = 3048.0,
  int tilesNeeded = 132,
}) {
  return HistoryEntry(
    id: time.microsecondsSinceEpoch,
    timestamp: time,
    unitSystem: UnitSystem.imperial,
    rows: [
      HistoryRow(lengthMm: lengthMm, widthMm: widthMm, isCutout: false),
    ],
    tileWidthMm: 304.8,
    tileHeightMm: 304.8,
    groutMm: 0,
    tileThicknessMm: 7.9375,
    jointDepthMm: null,
    trowelName: null,
    patternName: 'straight',
    customWastePct: 10,
    tilesPerBox: null,
    pricePerBox: null,
    netAreaSqM: 11.15,
    tilesNeeded: tilesNeeded,
    boxes: null,
  );
}

Future<HistoryController> freshController() async {
  final prefs = await SharedPreferences.getInstance();
  return HistoryController(prefs);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('记录与排序', () {
    test('新记录插到最前（倒序列表）', () async {
      final c = await freshController();
      final t = DateTime(2026, 7, 24, 10);
      c.record(entryWith(time: t));
      c.record(entryWith(time: t.add(const Duration(hours: 1)), lengthMm: 5000));
      expect(c.entries.length, 2);
      expect(c.entries.first.rows.first.lengthMm, 5000);
    });

    test('与最新一条输入相同：不加新条目，只刷新时间戳', () async {
      final c = await freshController();
      final t = DateTime(2026, 7, 24, 10);
      c.record(entryWith(time: t));
      c.record(entryWith(time: t.add(const Duration(minutes: 5))));
      expect(c.entries.length, 1);
      expect(c.entries.first.timestamp, t.add(const Duration(minutes: 5)));
    });

    test('与最新一条不同（哪怕只差缝宽）：加新条目', () async {
      final c = await freshController();
      final t = DateTime(2026, 7, 24, 10);
      c.record(entryWith(time: t));
      final changed = HistoryEntry(
        id: 999,
        timestamp: t.add(const Duration(minutes: 5)),
        unitSystem: UnitSystem.imperial,
        rows: [
          HistoryRow(lengthMm: 3657.6, widthMm: 3048.0, isCutout: false),
        ],
        tileWidthMm: 304.8,
        tileHeightMm: 304.8,
        groutMm: 3, // 缝宽不同
        tileThicknessMm: 7.9375,
        jointDepthMm: null,
        trowelName: null,
        patternName: 'straight',
        customWastePct: 10,
        tilesPerBox: null,
        pricePerBox: null,
        netAreaSqM: 11.15,
        tilesNeeded: 135,
        boxes: null,
      );
      c.record(changed);
      expect(c.entries.length, 2);
    });
  });

  group('持久化', () {
    test('写入后新实例能读回', () async {
      final c1 = await freshController();
      c1.record(entryWith(time: DateTime(2026, 7, 24, 10)));
      final c2 = await freshController();
      expect(c2.entries.length, 1);
      expect(c2.entries.first.tilesNeeded, 132);
      expect(c2.entries.first.unitSystem, UnitSystem.imperial);
    });

    test('损坏的 JSON 静默丢弃，不崩', () async {
      SharedPreferences.setMockInitialValues({'history_v1': '{[broken'});
      final c = await freshController();
      expect(c.entries, isEmpty);
    });
  });

  group('删除', () {
    test('按 id 删除单条', () async {
      final c = await freshController();
      final t = DateTime(2026, 7, 24, 10);
      c.record(entryWith(time: t));
      c.record(entryWith(time: t.add(const Duration(hours: 1)), lengthMm: 5000));
      final idToRemove = c.entries.first.id;
      c.remove(idToRemove);
      expect(c.entries.length, 1);
      expect(c.entries.first.rows.first.lengthMm, 3657.6);
    });

    test('清空全部', () async {
      final c = await freshController();
      c.record(entryWith(time: DateTime(2026, 7, 24, 10)));
      c.clear();
      expect(c.entries, isEmpty);
      // 持久化也清了
      final c2 = await freshController();
      expect(c2.entries, isEmpty);
    });
  });

  group('HistoryEntry JSON 往返', () {
    test('全字段（含可空箱规/成本/未完成行）无损', () {
      final entry = HistoryEntry(
        id: 42,
        timestamp: DateTime(2026, 7, 24, 12, 30),
        unitSystem: UnitSystem.metric,
        rows: [
          HistoryRow(lengthMm: 5000, widthMm: 4000, isCutout: false),
          HistoryRow(lengthMm: 2000, widthMm: 1000, isCutout: true),
          HistoryRow(lengthMm: 1000, widthMm: null, isCutout: false),
        ],
        tileWidthMm: 300,
        tileHeightMm: 600,
        groutMm: 2,
        tileThicknessMm: 7.9375,
        jointDepthMm: null,
        trowelName: null,
        patternName: 'custom',
        customWastePct: 12,
        tilesPerBox: 8,
        pricePerBox: 25.5,
        netAreaSqM: 18,
        tilesNeeded: 109,
        boxes: 14,
      );
      final back = HistoryEntry.fromJson(entry.toJson());
      expect(back.id, 42);
      expect(back.timestamp, DateTime(2026, 7, 24, 12, 30));
      expect(back.unitSystem, UnitSystem.metric);
      expect(back.rows.length, 3);
      expect(back.rows[1].isCutout, isTrue);
      expect(back.rows[2].widthMm, isNull);
      expect(back.patternName, 'custom');
      expect(back.customWastePct, 12);
      expect(back.tilesPerBox, 8);
      expect(back.pricePerBox, 25.5);
      expect(back.boxes, 14);
    });
  });
}
