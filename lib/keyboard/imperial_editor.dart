import '../domain/length.dart';

/// 分数快捷键八键面板，顺序即 brief §3.2 键盘布局（两行）：
/// 1/16 1/8 1/4 1/2 / 3/16 3/8 3/4 7/8
enum KeyFraction {
  sixteenth(1, 16),
  eighth(1, 8),
  quarter(1, 4),
  half(1, 2),
  threeSixteenths(3, 16),
  threeEighths(3, 8),
  threeQuarters(3, 4),
  sevenEighths(7, 8);

  final int numerator;
  final int denominator;

  const KeyFraction(this.numerator, this.denominator);

  int get sixteenths => numerator * 16 ~/ denominator;

  String get label => '$numerator/$denominator';
}

enum ImperialSegment { feet, inches }

/// 字段形态：房间尺寸用 ft+in 双段；瓷砖尺寸/缝宽只有 inch 段。
enum ImperialFieldKind { feetAndInches, inchesOnly }

/// 英制分数键盘状态机（brief §3.2）。
///
/// 核心语义：
/// - 数字进当前激活段；单位键采用"后置标注"——先打数字再按 ft/in，
///   数字会被改判到对应段（工人口述顺序：`30 → in` 即 30 英寸）
/// - 分数键是切换态：再点同键取消，点其他键替换；分数永远属于 inch 段
/// - 退格逐级回退：分数 → inch 数字 → feet 数字
class ImperialEditor {
  static const _feetMaxDigits = 3;
  static const _inchMaxDigits = 2;

  final ImperialFieldKind kind;

  String _feet = '';
  String _inches = '';
  KeyFraction? _fraction;
  ImperialSegment _active;

  /// feet 值是否已被 ft 键确认。已确认的值不参与 pressIn 改判，
  /// 防止纯导航序列（12→ft→ft→in）静默把 12′ 变成 12″。
  bool _feetLabeled = false;

  ImperialEditor({this.kind = ImperialFieldKind.feetAndInches})
      : _active = kind == ImperialFieldKind.inchesOnly
            ? ImperialSegment.inches
            : ImperialSegment.feet;

  ImperialSegment get activeSegment => _active;
  String get feetText => _feet;
  String get inchText => _inches;
  KeyFraction? get selectedFraction => _fraction;

  bool get isEmpty => _feet.isEmpty && _inches.isEmpty && _fraction == null;

  void digit(int d) {
    assert(d >= 0 && d <= 9);
    if (_active == ImperialSegment.feet) {
      _feet = _append(_feet, d, _feetMaxDigits);
    } else {
      _inches = _append(_inches, d, _inchMaxDigits);
    }
  }

  static String _append(String buffer, int d, int maxDigits) {
    if (buffer == '0') return '$d'; // 前导零替换
    if (buffer.length >= maxDigits) return buffer; // 超出忽略
    return '$buffer$d';
  }

  /// ft 键：inch 段有孤立数字时改判为英尺；否则在两段间移动激活态
  /// （feet 段按下 = 确认并推进到 inch 段）。
  void pressFt() {
    if (kind == ImperialFieldKind.inchesOnly) return;
    if (_active == ImperialSegment.inches) {
      if (_inches.isNotEmpty && _feet.isEmpty && _fraction == null) {
        _feet = _inches;
        _inches = '';
        _feetLabeled = true;
        // 改判后保持 inch 段激活，接续 "12 ft 3 in" 口述顺序
      } else {
        _active = ImperialSegment.feet;
      }
    } else {
      // 确认当前 feet 缓冲并推进
      _feetLabeled = _feet.isNotEmpty;
      _active = ImperialSegment.inches;
    }
  }

  /// in 键：feet 段有孤立数字时改判为英寸；激活态落到 inch 段。
  /// 改判护栏（与 pressFt 对称）：已确认值、有分数、超 inch 位数上限时只移动激活态。
  void pressIn() {
    if (_active == ImperialSegment.feet) {
      final canReassign = _feet.isNotEmpty &&
          _inches.isEmpty &&
          !_feetLabeled &&
          _fraction == null &&
          _feet.length <= _inchMaxDigits;
      if (canReassign) {
        _inches = _feet;
        _feet = '';
      }
      _active = ImperialSegment.inches;
    }
    // inch 段已激活时为无操作
  }

  void toggleFraction(KeyFraction f) {
    // 分数属于 inch 段：feet 段的孤立数字同样改判（"12 → ½" 读作 12-1/2″）
    if (_active == ImperialSegment.feet) pressIn();
    _fraction = _fraction == f ? null : f;
  }

  void backspace() {
    if (_active == ImperialSegment.inches) {
      if (_fraction != null) {
        _fraction = null;
      } else if (_inches.isNotEmpty) {
        _inches = _dropLast(_inches);
      } else if (kind != ImperialFieldKind.inchesOnly && _feet.isNotEmpty) {
        _active = ImperialSegment.feet;
        _feet = _dropLast(_feet);
        if (_feet.isEmpty) _feetLabeled = false;
      }
    } else {
      if (_feet.isNotEmpty) {
        _feet = _dropLast(_feet);
        if (_feet.isEmpty) _feetLabeled = false;
      } else if (_fraction != null) {
        _fraction = null;
      } else if (_inches.isNotEmpty) {
        _inches = _dropLast(_inches);
      }
    }
  }

  static String _dropLast(String s) => s.substring(0, s.length - 1);

  void clear() {
    _feet = '';
    _inches = '';
    _fraction = null;
    _feetLabeled = false;
    _active = kind == ImperialFieldKind.inchesOnly
        ? ImperialSegment.inches
        : ImperialSegment.feet;
  }

  /// 空态返回 null（字段显示占位符）。
  Length? get value {
    if (isEmpty) return null;
    return Length.imperial(
      feet: int.tryParse(_feet) ?? 0,
      inches: int.tryParse(_inches) ?? 0,
      sixteenths: _fraction?.sixteenths ?? 0,
    );
  }

  /// 编辑态实时显示，直接由缓冲区拼装（真撇号 U+2032/U+2033）。
  String get displayText {
    final feetPart = _feet.isNotEmpty ? '$_feet′' : null;
    final f = _fraction;
    String? inchPart;
    if (_inches.isNotEmpty && f != null) {
      inchPart = '$_inches-${f.label}″';
    } else if (_inches.isNotEmpty) {
      inchPart = '$_inches″';
    } else if (f != null) {
      inchPart = '${f.label}″';
    }
    return [feetPart, inchPart].whereType<String>().join(' ');
  }
}
