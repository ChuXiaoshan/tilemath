import 'package:flutter/material.dart';

import '../../ads/interstitial_manager.dart';
import '../../keyboard/imperial_editor.dart';
import '../../keyboard/metric_editor.dart';
import '../../l10n/app_localizations.dart';
import '../../state/calculator_controller.dart';
import '../../state/settings_controller.dart';
import '../../theme/app_dimens.dart';
import '../format.dart';

/// 自定义键盘托盘（brief §3.2 / §3.2b）。
/// RTL 硬规则：键位顺序与数字永不镜像，整个网格包在 LTR Directionality 里。
/// 与 banner 的 16-18dp 隔离带由页面布局负责，不在本 widget 内。
class TileKeyboard extends StatelessWidget {
  final CalculatorController controller;

  const TileKeyboard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imperial = controller.unitSystem == UnitSystem.imperial;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: scheme.surfaceContainerLow,
        padding: const EdgeInsets.all(AppDimens.space16),
        child: imperial ? _imperialGrid(context) : _metricGrid(context),
      ),
    );
  }

  /// Done：提交并收起；产生了有效结果就记一次插屏频控计数
  /// （自然断点低频策略，不改 CalculatorController）。
  void _handleDone() {
    controller.commitAndClose();
    if (controller.result != null) {
      InterstitialManager.instance.recordCalculation();
    }
  }

  Widget _imperialGrid(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final e = controller.imperialEditor;
    final ftActive = e?.activeSegment == ImperialSegment.feet;
    final canFt = e?.kind == ImperialFieldKind.feetAndInches;

    Widget fractionKey(KeyFraction f) => _Key.fraction(
          label: f.label,
          selected: e?.selectedFraction == f,
          onTap: () => controller.keyFraction(f),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row([for (final f in KeyFraction.values.take(4)) fractionKey(f)]),
        _row([for (final f in KeyFraction.values.skip(4)) fractionKey(f)]),
        _row([
          _digit(7),
          _digit(8),
          _digit(9),
          _Key.fn(
            onTap: controller.keyBackspace,
            onLongPress: controller.keyClear,
            child: const Icon(Icons.backspace_outlined, size: 22),
          ),
        ]),
        _row([
          _digit(4),
          _digit(5),
          _digit(6),
          _Key.segment(
            label: 'ft',
            active: canFt && ftActive,
            enabled: canFt,
            onTap: controller.keyFt,
          ),
        ]),
        _row([
          _digit(1),
          _digit(2),
          _digit(3),
          _Key.segment(
            label: 'in',
            active: e != null && !ftActive,
            enabled: true,
            onTap: controller.keyIn,
          ),
        ]),
        _row([
          _digit(0),
          _Key.fn(label: l10n.keyClear, onTap: controller.keyClear),
          _Key.fn(label: l10n.keyNext, onTap: controller.commitAndNext),
          _Key.done(label: l10n.keyDone, onTap: _handleDone),
        ]),
      ],
    );
  }

  Widget _metricGrid(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = controller.metricEditor?.unit;
    final separator =
        decimalSeparatorOf(Localizations.localeOf(context).toString());
    // 单位键按字段自适应（brief §3.2b 两键布局不变）：
    // 缝宽字段惯用 mm，两键给 cm/mm；其余字段维持 m/cm。
    final isGrout = controller.editing?.kind == FieldKind.grout;
    final upperUnit = isGrout ? MetricUnit.cm : MetricUnit.m;
    final lowerUnit = isGrout ? MetricUnit.mm : MetricUnit.cm;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row([
          _digit(7),
          _digit(8),
          _digit(9),
          // Clear 收进长按 ⌫（brief §3.2b 允许的安排）
          _Key.fn(
            onTap: controller.keyBackspace,
            onLongPress: controller.keyClear,
            child: const Icon(Icons.backspace_outlined, size: 22),
          ),
        ]),
        _row([
          _digit(4),
          _digit(5),
          _digit(6),
          _Key.segment(
            label: upperUnit.name,
            active: unit == upperUnit,
            enabled: true,
            onTap: () => controller.keyMetricUnit(upperUnit),
          ),
        ]),
        _row([
          _digit(1),
          _digit(2),
          _digit(3),
          _Key.segment(
            label: lowerUnit.name,
            active: unit == lowerUnit,
            enabled: true,
            onTap: () => controller.keyMetricUnit(lowerUnit),
          ),
        ]),
        _row([
          _digit(0),
          // 键帽按 locale 显示 . 或 ,（brief §3.2b）
          _Key.digit(label: separator, onTap: controller.keyDecimal),
          _Key.fn(label: l10n.keyNext, onTap: controller.commitAndNext),
          _Key.done(label: l10n.keyDone, onTap: _handleDone),
        ]),
      ],
    );
  }

  Widget _digit(int d) =>
      _Key.digit(label: '$d', onTap: () => controller.keyDigit(d));

  Widget _row(List<Widget> keys) => Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.space8),
        child: Row(
          children: [
            for (var i = 0; i < keys.length; i++) ...[
              if (i > 0) const SizedBox(width: AppDimens.space8),
              Expanded(child: keys[i]),
            ],
          ],
        ),
      );
}

enum _KeyStyle { digit, fraction, fn, segment, done }

/// 单个键帽：三类视觉层级（数字 / 分数-段键 / 功能），Done 为主操作。
class _Key extends StatelessWidget {
  final String? label;
  final Widget? child;
  final _KeyStyle style;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _Key._({
    this.label,
    this.child,
    required this.style,
    this.selected = false,
    this.enabled = true,
    required this.onTap,
    this.onLongPress,
  });

  factory _Key.digit({required String label, required VoidCallback onTap}) =>
      _Key._(label: label, style: _KeyStyle.digit, onTap: onTap);

  factory _Key.fraction({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      _Key._(
        label: label,
        style: _KeyStyle.fraction,
        selected: selected,
        onTap: onTap,
      );

  factory _Key.fn({
    String? label,
    Widget? child,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) =>
      _Key._(
        label: label,
        style: _KeyStyle.fn,
        onTap: onTap,
        onLongPress: onLongPress,
        child: child,
      );

  factory _Key.segment({
    required String label,
    required bool active,
    required bool enabled,
    required VoidCallback onTap,
  }) =>
      _Key._(
        label: label,
        style: _KeyStyle.segment,
        selected: active,
        enabled: enabled,
        onTap: onTap,
      );

  factory _Key.done({required String label, required VoidCallback onTap}) =>
      _Key._(label: label, style: _KeyStyle.done, onTap: onTap);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final (Color bg, Color fg, TextStyle? labelStyle) = switch (style) {
      _KeyStyle.digit => (
          scheme.surfaceContainerLowest,
          scheme.onSurface,
          text.headlineSmall,
        ),
      _KeyStyle.fraction => (
          selected ? scheme.primaryContainer : scheme.surfaceContainerLowest,
          selected ? scheme.onPrimaryContainer : scheme.onSurface,
          text.bodyLarge,
        ),
      _KeyStyle.segment => (
          selected ? scheme.primaryContainer : scheme.surfaceContainerLowest,
          selected ? scheme.onPrimaryContainer : scheme.onSurface,
          text.labelLarge,
        ),
      _KeyStyle.fn => (
          scheme.surfaceContainerLow,
          scheme.onSurface,
          text.labelLarge,
        ),
      _KeyStyle.done => (scheme.primary, scheme.onPrimary, text.labelLarge),
    };

    final radius = BorderRadius.circular(AppDimens.radius2);
    return Material(
      color: enabled ? bg : bg.withValues(alpha: 0.4),
      borderRadius: radius,
      child: InkWell(
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        borderRadius: radius,
        child: Container(
          constraints:
              const BoxConstraints(minHeight: AppDimens.minTouchTarget),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: style == _KeyStyle.done
                ? null
                : Border.all(color: scheme.outline, width: 1),
          ),
          alignment: Alignment.center,
          child: child != null
              ? IconTheme(
                  data: IconThemeData(color: fg),
                  child: child!,
                )
              : Text(label!, style: labelStyle?.copyWith(color: fg)),
        ),
      ),
    );
  }
}
