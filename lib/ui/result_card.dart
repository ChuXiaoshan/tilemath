import 'package:flutter/material.dart';

import '../domain/length.dart';
import '../domain/materials_calculation.dart';
import '../domain/tile_calculation.dart';
import '../keyboard/metric_editor.dart';
import '../l10n/app_localizations.dart';
import '../state/settings_controller.dart';
import '../theme/app_dimens.dart';
import 'format.dart';
import 'pattern_preview.dart';

/// 结果卡（brief §3.4）：空态提示 / 完整态分层展示。
/// 箱数与成本未填参数时整行隐藏；小面积提示用普通色，不用错误色。
/// v1.1：大数字旁嵌铺贴预览，材料估算行（灰浆/薄贴）随 materials 显隐。
class ResultCard extends StatelessWidget {
  final TileCalcResult? result;
  final UnitSystem unitSystem;
  final String currencySymbol;

  /// 当前生效损耗百分比（说明行用，来自 controller，不反推）。
  final int wastePct;

  /// 材料估算结果；null 时灰浆/薄贴行与免责声明整体隐藏。
  final MaterialsResult? materials;

  /// 预览所需的砖尺寸/缝宽/铺法；四者全非空才画预览。
  final Length? tileWidth;
  final Length? tileHeight;
  final Length? grout;
  final LayoutPattern? pattern;

  /// 预览边长（dp）：单栏 84，双栏 120。
  final double previewSize;

  const ResultCard({
    super.key,
    required this.result,
    required this.unitSystem,
    required this.currencySymbol,
    required this.wastePct,
    this.materials,
    this.tileWidth,
    this.tileHeight,
    this.grout,
    this.pattern,
    this.previewSize = 84,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppDimens.space8),
                        decoration: BoxDecoration(
                          // 大数字区轻层次（2026-08-06 视觉增强拍板）：
                          // primaryContainer 半透明底，纸面纹理透出，
                          // 不抢数字对比度。
                          color: scheme.primaryContainer.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppDimens.radius2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                    ),
                    if (tileWidth != null &&
                        tileHeight != null &&
                        grout != null &&
                        pattern != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppDimens.space8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PatternPreview(
                              tileWidth: tileWidth!,
                              tileHeight: tileHeight!,
                              grout: grout!,
                              pattern: pattern!,
                              size: previewSize,
                            ),
                            const SizedBox(height: AppDimens.space4),
                            Text(
                              l10n.previewCaption(
                                _patternName(l10n, pattern!),
                                formatLength(
                                  grout!,
                                  unitSystem,
                                  MetricUnit.mm,
                                  locale,
                                ),
                              ),
                              style: text.bodySmall!.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
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
                if (materials != null) ...[
                  const SizedBox(height: AppDimens.space8),
                  KeyedSubtree(
                    key: const ValueKey('grout-row'),
                    child: _labeledRow(
                      context,
                      l10n.groutNeeded,
                      formatGroutAmount(
                        materials!.groutKg,
                        unitSystem,
                        locale,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space8),
                  KeyedSubtree(
                    key: const ValueKey('thinset-row'),
                    child: _labeledRow(
                      context,
                      l10n.thinsetNeeded,
                      l10n.thinsetBagsLine(
                        unitSystem == UnitSystem.imperial
                            ? materials!.thinsetBags50Lb
                            : materials!.thinsetBags20Kg,
                        unitSystem == UnitSystem.imperial ? '50 lb' : '20 kg',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space8),
                  Row(
                    key: const ValueKey('materials-disclaimer'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppDimens.space8),
                      Expanded(
                        child: Text(
                          l10n.materialsDisclaimer,
                          style: text.bodySmall!
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
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

  /// 铺法名称本地化（同 home_page.dart `_PatternSelector.nameOf`，此处独立
  /// 一份避免跨文件耦合私有方法）。
  String _patternName(AppLocalizations l10n, LayoutPattern p) => switch (p) {
        LayoutPattern.straight => l10n.patternStraight,
        LayoutPattern.diagonal => l10n.patternDiagonal,
        LayoutPattern.herringbone => l10n.patternHerringbone,
        LayoutPattern.custom => l10n.patternCustom,
      };

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
        // 材料行的值文案比原有面积/箱数/成本长（如 "≈ 4.3 lb (2.0 kg)"），
        // 窄屏（iPhone SE 等）不加 Flexible 会横向溢出；换行优于裁切/溢出。
        Flexible(
          child: Text(
            value,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.end,
            style: text.titleMedium,
          ),
        ),
      ],
    );
  }
}
