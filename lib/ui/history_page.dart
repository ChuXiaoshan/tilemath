import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// 历史记录页（brief §3.5）。骨架版：空态占位，持久化列表后续迭代。
/// 定位提醒：历史无限免费（针对竞品"免费限 10 条"的打法），永不加数量限制 UI。
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: Center(
        child: Text(
          l10n.historyEmpty,
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
