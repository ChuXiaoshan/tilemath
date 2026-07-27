import 'package:flutter/material.dart';

import '../domain/tile_calculation.dart';
import '../l10n/app_localizations.dart';
import '../state/settings_controller.dart';
import '../theme/app_dimens.dart';
import 'format.dart';

/// 结果卡（brief §3.4）：空态提示 / 完整态分层展示。
/// 箱数与成本未填参数时整行隐藏；小面积提示用普通色，不用错误色。
class ResultCard extends StatelessWidget {
  final TileCalcResult? result;
  final UnitSystem unitSystem;
  final String currencySymbol;

  /// 当前生效损耗百分比（说明行用，来自 controller，不反推）。
  final int wastePct;

  const ResultCard({
    super.key,
    required this.result,
    required this.unitSystem,
    required this.currencySymbol,
    required this.wastePct,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final r = result;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimens.radius4),
      ),
      child: r == null
          ? Text(
              l10n.resultEmptyPrompt,
              style: text.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _labeledRow(
                  context,
                  l10n.totalArea,
                  formatArea(r.netAreaSqM, unitSystem, locale),
                ),
                const SizedBox(height: AppDimens.space8),
                Center(
                  child: Column(
                    children: [
                      // 主数字：一臂距离可读，数字恒 LTR
                      Text(
                        '${r.tilesNeeded}',
                        textDirection: TextDirection.ltr,
                        style: text.displayLarge,
                      ),
                      Text(
                        l10n.tilesNeededLabel(r.tilesNeeded),
                        style: text.bodySmall!
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                      Text(
                        l10n.wasteLine(r.baseTiles, wastePct),
                        style: text.bodySmall!
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (r.boxes != null) ...[
                  const SizedBox(height: AppDimens.space8),
                  _labeledRow(context, l10n.boxesToBuy, '${r.boxes}'),
                ],
                if (r.cost != null) ...[
                  const SizedBox(height: AppDimens.space8),
                  _labeledRow(
                    context,
                    l10n.estimatedCost,
                    formatCost(r.cost!, currencySymbol, locale),
                  ),
                ],
                if (r.smallAreaHint) ...[
                  const SizedBox(height: AppDimens.space8),
                  Text(
                    l10n.smallAreaHint,
                    style: text.bodySmall!
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _labeledRow(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: text.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
        ),
        Text(value, textDirection: TextDirection.ltr, style: text.titleMedium),
      ],
    );
  }
}
