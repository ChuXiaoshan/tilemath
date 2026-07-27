import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'history_entry.dart';

/// 历史记录：倒序、无上限（产品定位：打竞品"免费限 10 条"的付费点）。
/// 存储为 shared_preferences 里的一条 JSON 串。
class HistoryController extends ChangeNotifier {
  static const _kKey = 'history_v1';

  final SharedPreferences _prefs;
  final List<HistoryEntry> _entries = [];

  HistoryController(this._prefs) {
    final raw = _prefs.getString(_kKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _entries.addAll([
        for (final e in list) HistoryEntry.fromJson(e as Map<String, dynamic>),
      ]);
    } catch (_) {
      // 损坏数据静默丢弃：历史是便利功能，不能拖垮启动
      _entries.clear();
    }
  }

  /// 倒序（最新在前）。
  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  /// 记录一次计算。输入完全相同的旧记录不新增，只刷新并上移到最前。
  ///
  /// 去重必须比对整张表而非仅最新一条：存档点有三个（Done / 打开 History 前 /
  /// 退后台），只比第一条会让"从历史恢复某条后再打开 History"重复入库；
  /// 清空后列表为空更是直接把当前计算又写回去，看起来就像删除没生效。
  /// [explicit] 区分用户主动按 Done 与被动存档（打开 History 前 / 退后台）。
  /// 用户刚删过东西时，被动存档必须闭嘴，否则屏上那次计算会立刻被写回去，
  /// 看起来就像"删除没生效"。下一次主动 Done 解除抑制。
  void record(HistoryEntry entry, {bool explicit = false}) {
    if (!explicit && _suppressPassiveRecord) return;
    if (explicit) _suppressPassiveRecord = false;
    final existing = _entries.indexWhere((e) => e.sameInputs(entry));
    if (existing >= 0) {
      _entries.removeAt(existing);
    }
    _entries.insert(0, entry);
    _persist();
    notifyListeners();
  }

  void remove(int id) {
    _suppressPassiveRecord = true;
    _entries.removeWhere((e) => e.id == id);
    _persist();
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    _suppressPassiveRecord = true;
    _persist();
    notifyListeners();
  }

  /// 仅本次会话有效，不持久化——重启 app 后恢复正常存档。
  bool _suppressPassiveRecord = false;

  void _persist() {
    _prefs.setString(
      _kKey,
      jsonEncode([for (final e in _entries) e.toJson()]),
    );
  }
}
