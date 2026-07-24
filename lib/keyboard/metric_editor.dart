import '../domain/length.dart';

/// 公制单位键。字段默认：房间 m / 瓷砖 cm / 缝宽 mm（brief §3.2b）。
enum MetricUnit { m, cm, mm }

/// 公制键盘状态机（brief §3.2b）。
///
/// - 单位键是"改标签不换算"：250 cm → 按 m → 250 m
/// - 小数分隔符内部恒用 '.'，locale 形态（. / ,）是显示层的事
class MetricEditor {
  static const _intMaxDigits = 5;
  static const _decimalMaxDigits = 2;

  final MetricUnit defaultUnit;

  MetricUnit _unit;
  String _text = '';

  MetricEditor({required this.defaultUnit}) : _unit = defaultUnit;

  MetricUnit get unit => _unit;
  String get text => _text;
  bool get isEmpty => _text.isEmpty;

  void digit(int d) {
    assert(d >= 0 && d <= 9);
    if (_text == '0') {
      _text = '$d'; // 前导零替换
      return;
    }
    final dotIndex = _text.indexOf('.');
    if (dotIndex < 0) {
      if (_text.length >= _intMaxDigits) return;
    } else {
      if (_text.length - dotIndex - 1 >= _decimalMaxDigits) return;
    }
    _text = '$_text$d';
  }

  void decimal() {
    if (_text.contains('.')) return;
    _text = _text.isEmpty ? '0.' : '$_text.';
  }

  /// 临时覆盖字段默认单位；数字不换算。
  void setUnit(MetricUnit u) => _unit = u;

  void backspace() {
    if (_text.isEmpty) return;
    _text = _text.substring(0, _text.length - 1);
  }

  void clear() {
    _text = '';
    _unit = defaultUnit;
  }

  /// 空态返回 null；结尾悬空的 '.' 按整数取值。
  Length? get value {
    final normalized =
        _text.endsWith('.') ? _text.substring(0, _text.length - 1) : _text;
    if (normalized.isEmpty) return null;
    final number = double.parse(normalized);
    return switch (_unit) {
      MetricUnit.m => Length.ofMeters(number),
      MetricUnit.cm => Length.ofCm(number),
      MetricUnit.mm => Length.ofMm(number),
    };
  }
}
