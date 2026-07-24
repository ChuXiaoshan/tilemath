/// 长度值对象，内部以毫米（double）为基准单位存储。
///
/// 单位制决策（2026-07-24 拍板）：UI 全局单套单位制（Imperial / Metric），
/// 底层统一 mm 存储，为将来混用留后路。
class Length {
  /// 毫米数，恒为非负有限值。
  final double mm;

  Length.ofMm(double mm) : mm = _validate(mm, 'mm');

  factory Length.ofMeters(double m) => Length.ofMm(m * 1000);

  factory Length.ofCm(double cm) => Length.ofMm(cm * 10);

  factory Length.ofInches(double inches) => Length.ofMm(inches * 25.4);

  /// 英制构造：feet/inches 整数段 + 以 1/16 英寸计的分数段。
  /// 例：5′ 3-1/2″ → feet: 5, inches: 3, sixteenths: 8
  factory Length.imperial({int feet = 0, int inches = 0, int sixteenths = 0}) {
    if (feet < 0 || inches < 0 || sixteenths < 0) {
      throw ArgumentError('英制各段不得为负: $feet ft $inches in $sixteenths/16');
    }
    return Length.ofInches((feet * 12 + inches) + sixteenths / 16);
  }

  static double _validate(double value, String label) {
    if (value.isNaN || value.isInfinite || value < 0) {
      throw ArgumentError('长度必须为非负有限值（$label = $value）');
    }
    return value;
  }

  double get meters => mm / 1000;
  double get cm => mm / 10;
  double get inches => mm / 25.4;
  double get feet => mm / 304.8;

  /// 吸附到最近 1/16 英寸并拆为英尺/英寸/归约分数三段。
  ImperialParts toImperialParts() {
    final totalSixteenths = (mm / 25.4 * 16).round();
    final feet = totalSixteenths ~/ (16 * 12);
    final remainder = totalSixteenths % (16 * 12);
    final inches = remainder ~/ 16;
    var numerator = remainder % 16;
    var denominator = 16;
    while (numerator != 0 && numerator.isEven) {
      numerator ~/= 2;
      denominator ~/= 2;
    }
    if (numerator == 0) denominator = 1;
    return ImperialParts(
      feet: feet,
      inches: inches,
      numerator: numerator,
      denominator: denominator,
    );
  }

  @override
  String toString() => 'Length(${mm}mm)';
}

/// 英制显示三段：feet + inches(0–11) + 归约分数（denominator ∈ {1,2,4,8,16}）。
class ImperialParts {
  final int feet;
  final int inches;

  /// 归约后的分子；0 表示无分数段。
  final int numerator;

  /// 归约后的分母；无分数段时为 1。
  final int denominator;

  const ImperialParts({
    required this.feet,
    required this.inches,
    required this.numerator,
    required this.denominator,
  });
}

/// 英制格式化，用真撇号：12′ 3-1/2″（U+2032 / U+2033，token 表硬规则）。
String formatImperial(Length length) {
  final p = length.toImperialParts();
  final feetPart = p.feet > 0 ? '${p.feet}′' : null;

  String? inchPart;
  if (p.inches > 0 && p.numerator > 0) {
    inchPart = '${p.inches}-${p.numerator}/${p.denominator}″';
  } else if (p.inches > 0) {
    inchPart = '${p.inches}″';
  } else if (p.numerator > 0) {
    inchPart = '${p.numerator}/${p.denominator}″';
  }

  if (feetPart == null && inchPart == null) return '0″';
  return [feetPart, inchPart].whereType<String>().join(' ');
}
