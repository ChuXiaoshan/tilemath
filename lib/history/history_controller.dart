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

  /// 记录一次计算。与最新一条输入完全相同时只刷新该条
  /// （连续 Done 微调同一次计算不刷屏）。
  void record(HistoryEntry entry) {
    if (_entries.isNotEmpty && _entries.first.sameInputs(entry)) {
      _entries[0] = entry;
    } else {
      _entries.insert(0, entry);
    }
    _persist();
    notifyListeners();
  }

  void remove(int id) {
    _entries.removeWhere((e) => e.id == id);
    _persist();
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    _persist();
    notifyListeners();
  }

  void _persist() {
    _prefs.setString(
      _kKey,
      jsonEncode([for (final e in _entries) e.toJson()]),
    );
  }
}
