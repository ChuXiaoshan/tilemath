import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilemath/domain/tile_calculation.dart';
import 'package:tilemath/history/history_controller.dart';
import 'package:tilemath/history/history_entry.dart';
import 'package:tilemath/state/settings_controller.dart';

/// 上架前评估发现：去重只比最新一条，且删除后被动存档会立刻把记录写回去。
/// "历史无限免费"是本产品主打的功能，删了又回来是直接的信任损伤。
HistoryEntry _entry({required double lengthMm, int tiles = 100}) =>
    HistoryEntry(
      id: lengthMm.toInt(),
      timestamp: DateTime(2026, 7, 27),
      unitSystem: UnitSystem.imperial,
      rows: [
        HistoryRow(lengthMm: lengthMm, widthMm: 3000, isCutout: false),
      ],
      tileWidthMm: 304.8,
      tileHeightMm: 304.8,
      groutMm: 1.5875,
      patternName: LayoutPattern.straight.name,
      customWastePct: 10,
      tilesPerBox: null,
      pricePerBox: null,
      netAreaSqM: 11.15,
      tilesNeeded: tiles,
      boxes: null,
    );

Future<HistoryController> _fresh() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return HistoryController(prefs);
}

void main() {
  test('相同输入的旧记录不新增，只刷新并上移到最前', () async {
    final h = await _fresh();
    h.record(_entry(lengthMm: 1000), explicit: true);
    h.record(_entry(lengthMm: 2000), explicit: true);
    h.record(_entry(lengthMm: 3000), explicit: true);
    expect(h.entries.length, 3);

    // 再记一次最早那条（等同"从历史恢复后又打开 History"）
    h.record(_entry(lengthMm: 1000, tiles: 111), explicit: true);
    expect(h.entries.length, 3, reason: '整表去重，不能因为不是第一条就重复入库');
    expect(h.entries.first.rows.first.lengthMm, 1000);
    expect(h.entries.first.tilesNeeded, 111);
  });

  test('清空后被动存档不得把记录写回来', () async {
    final h = await _fresh();
    h.record(_entry(lengthMm: 1000), explicit: true);
    h.clear();
    expect(h.entries, isEmpty);

    // 打开 History 前 / 退后台的被动存档
    h.record(_entry(lengthMm: 1000));
    expect(h.entries, isEmpty, reason: '刚清空就复活，用户会认为删除没生效');
  });

  test('删除单条后被动存档不得把它写回来', () async {
    final h = await _fresh();
    h.record(_entry(lengthMm: 1000), explicit: true);
    final id = h.entries.first.id;
    h.remove(id);
    expect(h.entries, isEmpty);

    h.record(_entry(lengthMm: 1000));
    expect(h.entries, isEmpty);
  });

  test('清空后用户主动按 Done 仍能正常记录，并解除抑制', () async {
    final h = await _fresh();
    h.record(_entry(lengthMm: 1000), explicit: true);
    h.clear();

    h.record(_entry(lengthMm: 2000), explicit: true);
    expect(h.entries.length, 1);

    // 抑制已解除，后续被动存档恢复正常
    h.record(_entry(lengthMm: 3000));
    expect(h.entries.length, 2);
  });
}
