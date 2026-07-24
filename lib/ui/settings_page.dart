import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/settings_controller.dart';
import '../theme/app_dimens.dart';
import 'banner_footer.dart';

/// 产品语言清单：语言码 → 母语自称（设计稿 5b，自称不翻译）。
/// 当前实现 en/zh/ar，其余语言随 ARB 落地逐个开放。
const _languageNames = {
  'en': 'English',
  'zh': '中文（简体）',
  'ar': 'العربية',
};

/// 设置页（brief §3.6 / 设计稿 5b）：Units 行内紧凑分段（短标签）、
/// Language/Appearance 值+chevron 进子页、行间极细分隔线（组件内允许）、
/// 底部锚 banner。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsController>();
    // 地区判断必须用设备原始 locale——supportedLocales 解析后会丢 countryCode
    // （en_US → en），导致美国设备选中态误显 Metric。与 home_page 同一处理。
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;

    final themeLabel = switch (settings.themeMode) {
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
      ThemeMode.system => l10n.themeSystem,
    };
    final languageLabel = settings.localeOverride == null
        ? l10n.languageSystem
        : _languageNames[settings.localeOverride!.languageCode] ??
            settings.localeOverride!.languageCode;

    final rows = <Widget>[
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.units),
        trailing: SegmentedButton<UnitSystem>(
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: [
            ButtonSegment(
              value: UnitSystem.imperial,
              label: Text(l10n.unitImperial),
            ),
            ButtonSegment(
              value: UnitSystem.metric,
              label: Text(l10n.unitMetric),
            ),
          ],
          selected: {settings.effectiveUnitSystem(deviceLocale)},
          onSelectionChanged: (s) => settings.setUnitSystem(s.first),
        ),
      ),
      _ChevronRow(
        title: l10n.language,
        value: languageLabel,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LanguagePage()),
        ),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.currencySymbol),
        trailing: SizedBox(
          width: 72,
          child: TextFormField(
            initialValue: settings.currencySymbol,
            textAlign: TextAlign.center,
            maxLength: 3,
            decoration: const InputDecoration(counterText: ''),
            onChanged: settings.setCurrencySymbol,
          ),
        ),
      ),
      _ChevronRow(
        title: l10n.themeMode,
        value: themeLabel,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AppearancePage()),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.space16),
        children: [
          // 行间极细分隔线（outlineVariant hairline，组件内允许）
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            rows[i],
          ],
          const SizedBox(height: AppDimens.space24),
          // TODO: 上架前接隐私政策 URL 与商店评分（url_launcher / in_app_review）
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.privacyPolicy),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.rateApp),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.versionLabel),
            trailing: const Text('0.1.0'), // TODO: 接 package_info_plus
          ),
        ],
      ),
      bottomNavigationBar: const BannerFooter(),
    );
  }
}

/// `值 + ›` 行（设计稿 5b：Language / Appearance 的进入子页样式）。
class _ChevronRow extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  const _ChevronRow({
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: AppDimens.space4),
          Icon(Icons.chevron_right, size: 20, color: scheme.onSurfaceVariant),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// 语言子页（设计稿 5b 右屏）：System default + 母语自称列表，选中打勾。
class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsController>();
    final current = settings.localeOverride?.languageCode;

    Widget option(String? code, String label) {
      final selected = current == code;
      return ListTile(
        title: Text(label),
        trailing: selected
            ? Icon(Icons.check, color: scheme.primary, size: 20)
            : null,
        onTap: () => settings.setLocaleOverride(
          code == null ? null : Locale(code),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.language)),
      body: ListView(
        children: [
          option(null, l10n.languageSystem),
          for (final e in _languageNames.entries) ...[
            const Divider(height: 1),
            option(e.key, e.value),
          ],
          Padding(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Text(
              l10n.languagePageNote,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BannerFooter(),
    );
  }
}

/// 外观子页：System / Light / Dark 单选（与 Language 子页同构）。
class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsController>();

    Widget option(ThemeMode mode, String label) {
      final selected = settings.themeMode == mode;
      return ListTile(
        title: Text(label),
        trailing: selected
            ? Icon(Icons.check, color: scheme.primary, size: 20)
            : null,
        onTap: () => settings.setThemeMode(mode),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.themeMode)),
      body: ListView(
        children: [
          option(ThemeMode.system, l10n.themeSystem),
          const Divider(height: 1),
          option(ThemeMode.light, l10n.themeLight),
          const Divider(height: 1),
          option(ThemeMode.dark, l10n.themeDark),
        ],
      ),
      bottomNavigationBar: const BannerFooter(),
    );
  }
}
