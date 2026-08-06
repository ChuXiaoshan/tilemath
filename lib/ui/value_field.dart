import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../domain/length.dart';
import '../keyboard/metric_editor.dart';
import '../state/calculator_controller.dart';
import '../theme/app_dimens.dart';
import 'format.dart';

/// 可点值字段：编辑态显示编辑器实时文本 + secondary 描边。
/// 激活（点击 / Next 推进 / addRow 自动聚焦）后 post-frame 自动滚入视口，
/// 保证不被展开的键盘遮挡（brief §3.2 硬性要求）。
class ValueField extends StatefulWidget {
  final CalculatorController calc;
  final FieldId id;
  final String label;
  final Length? value;
  final MetricUnit metricUnit;
  final bool accent;

  const ValueField({
    super.key,
    required this.calc,
    required this.id,
    required this.label,
    required this.value,
    required this.metricUnit,
    this.accent = false,
  });

  @override
  State<ValueField> createState() => _ValueFieldState();
}

class _ValueFieldState extends State<ValueField> {
  bool _wasActive = false;

  /// 非激活 → 激活的瞬间，帧后把字段滚进视口（此时键盘已参与布局）。
  void _revealIfActivated(bool active) {
    if (active && !_wasActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reveal();
      });
    }
    _wasActive = active;
  }

  /// 仅在字段确实越出视口时滚动，上下各留 12dp 余量（8–16dp 区间内）。
  void _reveal() {
    final scrollable = Scrollable.maybeOf(context);
    final object = context.findRenderObject();
    if (scrollable == null || object == null || !object.attached) return;
    final viewport = RenderAbstractViewport.maybeOf(object);
    if (viewport == null) return;

    const margin = AppDimens.space12;
    final position = scrollable.position;
    final topOffset = viewport.getOffsetToReveal(object, 0).offset - margin;
    final bottomOffset = viewport.getOffsetToReveal(object, 1).offset + margin;
    var target = position.pixels;
    if (target > topOffset) {
      target = topOffset; // 字段顶部越出视口上沿
    } else if (target < bottomOffset) {
      target = bottomOffset; // 字段底部被键盘/视口下沿遮挡
    }
    target = target
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((target - position.pixels).abs() < 0.5) return;
    position.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final calc = widget.calc;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final active = calc.editing == widget.id;
    _revealIfActivated(active);

    final String display;
    if (active) {
      display =
          calc.imperialEditor?.displayText ??
          (calc.metricEditor == null
              ? ''
              : calc.metricEditor!.isEmpty
              ? ''
              : '${calc.metricEditor!.text} ${calc.metricEditor!.unit.name}');
    } else if (widget.value != null) {
      display = formatLength(
        widget.value!,
        calc.unitSystem,
        widget.metricUnit,
        locale,
      );
    } else {
      display = '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.labelSmall!.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        InkWell(
          key: ValueKey('field-${widget.id.kind.name}-${widget.id.row}'),
          onTap: () {
            // 先收起系统 IME，避免系统键盘与自定义键盘同屏堆叠
            FocusManager.instance.primaryFocus?.unfocus();
            calc.startEditing(widget.id);
          },
          borderRadius: BorderRadius.circular(AppDimens.radius2),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppDimens.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space12,
              vertical: AppDimens.space8,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimens.radius2),
              border: Border.all(
                color: active
                    ? scheme.secondary
                    : widget.accent
                    ? scheme.tertiary
                    : scheme.outline,
                width: active ? 1.5 : 1,
              ),
            ),
            alignment: AlignmentDirectional.centerStart,
            // 降级只缩不换行：12′ 11-7/8″ 的固有宽度约 181dp，而字段可用宽
            // 只有 95–123dp，不加约束会折成 2–3 行、字段高度随输入跳动。
            // 与 _PatternSelector 同一策略。
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                display,
                textDirection: TextDirection.ltr, // 尺寸表达式恒 LTR
                maxLines: 1,
                softWrap: false,
                style: text.bodyLarge,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
