import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../domain/tile_calculation.dart';
import '../history/history_controller.dart';
import '../history/history_entry.dart';
import '../l10n/app_localizations.dart';
import '../state/calculator_controller.dart';
import '../state/settings_controller.dart';
import '../theme/app_dimens.dart';
import 'banner_footer.dart';
import 'format.dart';

/// 历史记录页（brief §3.5 / 设计稿 5a）：倒序两行摘要列表、左滑删除、
/// 右上角文字 Clear all（空态置灰不隐藏）、点击整条恢复表单。
/// 定位提醒：历史无限免费（针对竞品"免费限 10 条"的打法），永不加数量限制 UI。
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final history = context.watch<HistoryController>();
    final entries = history.entries;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        actions: [
          // 设计稿 5a：文字按钮，空态置灰而非隐藏
          TextButton(
            onPressed: entries.isEmpty
                ? null
                : () => _confirmClearAll(context, history),
            child: Text(l10n.clearAll),
          ),
        ],
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppDimens.space16),
                  Text(
                    l10n.historyEmpty,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : ListView.builder(
              // 末尾多一项：定位注脚
              itemCount: entries.length + 1,
              itemBuilder: (context, index) {
                if (index == entries.length) {
                  return Padding(
                    padding: const EdgeInsets.all(AppDimens.space16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.all_inclusive,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppDimens.space8),
                        Expanded(
                          child: Text(
                            l10n.historyFooterNote,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return _HistoryTile(entry: entries[index]);
              },
            ),
      bottomNavigationBar: const BannerFooter(),
    );
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    HistoryController history,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) history.clear();
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;

  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final currency = context.watch<SettingsController>().currencySymbol;

    // 主行：面积 · 片数（设计稿 5a）
    final mainLine = [
      formatArea(entry.netAreaSqM, entry.unitSystem, locale),
      l10n.tilesCount(entry.tilesNeeded),
    ].join(' · ');

    // 次行：箱数 · 成本 · 砖规+铺法 · 损耗，最多取 3 段（对齐设计稿排布）
    final boxes = entry.boxes;
    final cost = (boxes != null && entry.pricePerBox != null)
        ? boxes * entry.pricePerBox!
        : null;
    final segments = <String>[
      if (boxes != null) l10n.boxesCount(boxes),
      if (cost != null) formatCost(cost, currency, locale),
      '${_tileSize(entry)} ${_patternLabel(l10n, entry.patternName)}',
      l10n.wasteShort(_wastePct(entry)),
    ].take(3).toList();

    return Dismissible(
      key: ValueKey('history-${entry.id}'),
      direction: DismissDirection.endToStart,
      // 设计稿 5a：error 主色块 + 垃圾桶 + Delete 文字（非 cutout 品红）
      background: Container(
        color: scheme.error,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: AppDimens.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: scheme.onError, size: 20),
            Text(
              l10n.delete,
              style: text.labelMedium!.copyWith(color: scheme.onError),
            ),
          ],
        ),
      ),
      onDismissed: (_) => context.read<HistoryController>().remove(entry.id),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space4,
        ),
        title: Text(
          mainLine,
          textDirection: TextDirection.ltr, // 数字/单位表达式恒 LTR
          style: text.bodyLarge,
        ),
        subtitle: Text(
          segments.join(' · '),
          textDirection: TextDirection.ltr,
          style: text.bodySmall!.copyWith(color: scheme.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatRelativeTime(entry.timestamp, l10n, locale),
              style:
                  text.bodySmall!.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: AppDimens.space4),
            Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
        onTap: () {
          context.read<CalculatorController>().restoreFrom(entry);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// 砖规显示：英制取英寸、公制取厘米，整数去尾（12×12 / 30×60）。
  /// 判整带容差：304.8/25.4 的浮点结果是 12.000000000000002。
  String _tileSize(HistoryEntry e) {
    String fmt(double mm) {
      final v = e.unitSystem == UnitSystem.imperial ? mm / 25.4 : mm / 10;
      final rounded = v.round();
      return (v - rounded).abs() < 0.05 ? '$rounded' : v.toStringAsFixed(1);
    }

    return '${fmt(e.tileWidthMm)}×${fmt(e.tileHeightMm)}';
  }

  String _patternLabel(AppLocalizations l10n, String name) => switch (name) {
        'diagonal' => l10n.patternDiagonal,
        'herringbone' => l10n.patternHerringbone,
        'custom' => l10n.patternCustom,
        _ => l10n.patternStraight,
      };

  /// 记录当时生效的损耗率：预设按铺法反查，custom 用存档值。
  int _wastePct(HistoryEntry e) {
    final preset = LayoutPattern.values
        .where((p) => p.name == e.patternName)
        .firstOrNull
        ?.wasteRate;
    return preset != null ? (preset * 100).round() : e.customWastePct;
  }
}

/// 相对时间："2 hours ago"；超过 7 天退化为本地化日期。
String formatRelativeTime(
  DateTime timestamp,
  AppLocalizations l10n,
  String locale, {
  DateTime? now,
}) {
  final diff = (now ?? DateTime.now()).difference(timestamp);
  if (diff.inMinutes < 1) return l10n.justNow;
  if (diff.inHours < 1) return l10n.minutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.hoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
  return DateFormat.yMMMd(locale).format(timestamp);
}
