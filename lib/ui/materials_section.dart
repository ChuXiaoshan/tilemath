import 'package:flutter/material.dart';

import '../domain/materials_calculation.dart';
import '../keyboard/metric_editor.dart';
import '../l10n/app_localizations.dart';
import '../state/calculator_controller.dart';
import '../theme/app_dimens.dart';
import 'format.dart';
import 'value_field.dart';

/// 辅料参数区（设计稿 10a/10b）：可折叠但有默认值——收起 ≠ 不参与，
/// 结果卡的材料行始终按当前参数计算。
class MaterialsSection extends StatelessWidget {
  final CalculatorController calc;

  const MaterialsSection({super.key, required this.calc});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    // 收起态摘要：厚度 · 镘刀（Auto 显示本地化「自动」）
    final thicknessText = formatLength(
        calc.tileThickness, calc.unitSystem, MetricUnit.mm, locale);
    final trowelText = calc.trowel?.label ?? l10n.trowelAuto;

    return ExpansionTile(
      key: const ValueKey('materials-header'),
      title: Text(l10n.sectionMaterials),
      subtitle: Text(
        l10n.materialsDefaults,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Text(
        '$thicknessText · $trowelText',
        key: const ValueKey('materials-summary'),
        textDirection: TextDirection.ltr,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      childrenPadding: const EdgeInsets.only(bottom: AppDimens.space8),
      onExpansionChanged: (open) {
        // 收起时若正在编辑本区块字段：提交并收键盘——与箱规区系统键盘
        // 随子树移除自动收起的行为对齐，避免键盘残留盲敲改值。
        final kind = calc.editing?.kind;
        if (!open &&
            (kind == FieldKind.tileThickness || kind == FieldKind.jointDepth)) {
          calc.commitAndClose();
        }
      },
      children: [
        Row(
          children: [
            Expanded(
              child: ValueField(
                calc: calc,
                id: const FieldId(FieldKind.tileThickness),
                label: l10n.tileThickness,
                value: calc.tileThickness,
                metricUnit: MetricUnit.mm,
              ),
            ),
            const SizedBox(width: AppDimens.space12),
            Expanded(
              child: calc.jointDepth == null &&
                      calc.editing?.kind != FieldKind.jointDepth
                  ? _followField(context, l10n)
                  : ValueField(
                      calc: calc,
                      id: const FieldId(FieldKind.jointDepth),
                      label: l10n.jointDepth,
                      value: calc.jointDepth,
                      metricUnit: MetricUnit.mm,
                    ),
            ),
            const SizedBox(width: AppDimens.space12),
            const Spacer(),
          ],
        ),
        const SizedBox(height: AppDimens.space12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            l10n.trowelLabel,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(height: AppDimens.space4),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Wrap(
            spacing: AppDimens.space8,
            runSpacing: AppDimens.space8,
            children: [
              ChoiceChip(
                key: const ValueKey('trowel-chip-auto'),
                label: Text(calc.trowel == null && calc.tileWidth != null
                    ? '${l10n.trowelAuto} · ${recommendTrowel(calc.tileWidth!, calc.tileHeight ?? calc.tileWidth!).label}'
                    : l10n.trowelAuto,
                    textDirection: TextDirection.ltr),
                selected: calc.trowel == null,
                onSelected: (_) => calc.setTrowel(null),
              ),
              for (final t in Trowel.values)
                ChoiceChip(
                  key: ValueKey('trowel-chip-${t.name}'),
                  label: Text(t.label, textDirection: TextDirection.ltr),
                  selected: calc.trowel == t,
                  onSelected: (_) => calc.setTrowel(t),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.space4),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            l10n.trowelAutoCaption,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  /// 缝深「= 砖厚」占位：点击即开始编辑缝深（转成真实字段）。
  Widget _followField(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.jointDepth,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.labelSmall!.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        InkWell(
          key: const ValueKey('field-jointDepth-follow'),
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            calc.startEditing(const FieldId(FieldKind.jointDepth));
          },
          borderRadius: BorderRadius.circular(AppDimens.radius2),
          child: Container(
            constraints:
                const BoxConstraints(minHeight: AppDimens.minTouchTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space12,
              vertical: AppDimens.space8,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimens.radius2),
              border: Border.all(color: scheme.outline),
            ),
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.jointDepthFollows,
              textDirection: TextDirection.ltr,
              style: text.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}
