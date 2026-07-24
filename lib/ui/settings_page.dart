import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/settings_controller.dart';
import '../theme/app_dimens.dart';

/// 设置页（brief §3.6）：Units / Language / Currency / Appearance /
/// Privacy policy / Rate / Version。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsController>();
    // 地区判断必须用设备原始 locale——supportedLocales 解析后会丢 countryCode
    // （en_US → en），导致美国设备选中态误显 Metric。与 home_page 同一处理。
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.space16),
        children: [
          // 上下结构：标题一行 + SegmentedButton 占满下一行。
          // 塞进 ListTile.trailing 会在中文/阿语等长文案下挤爆窄屏。
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimens.space8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.units,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppDimens.space8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<UnitSystem>(
                    segments: [
                      ButtonSegment(
                        value: UnitSystem.imperial,
                        label: Text(
                          l10n.unitImperial,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      ButtonSegment(
                        value: UnitSystem.metric,
                        label: Text(
                          l10n.unitMetric,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    selected: {settings.effectiveUnitSystem(deviceLocale)},
                    onSelectionChanged: (s) => settings.setUnitSystem(s.first),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.language),
            trailing: DropdownButton<String>(
              // 'system' 哨兵 = 跟随系统；其余为语言码
              value: settings.localeOverride?.languageCode ?? 'system',
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(l10n.languageSystem),
                ),
                const DropdownMenuItem(value: 'en', child: Text('English')),
                const DropdownMenuItem(value: 'zh', child: Text('中文')),
                const DropdownMenuItem(value: 'ar', child: Text('العربية')),
              ],
              onChanged: (v) => settings.setLocaleOverride(
                v == null || v == 'system' ? null : Locale(v),
              ),
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.themeMode),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(l10n.themeSystem),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(l10n.themeLight),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(l10n.themeDark),
                ),
              ],
              onChanged: (v) =>
                  v == null ? null : settings.setThemeMode(v),
            ),
          ),
          const Divider(),
          // TODO: 上架前接隐私政策 URL 与商店评分（url_launcher / in_app_review）
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.privacyPolicy),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () {},
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.rateApp),
            onTap: () {},
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.versionLabel),
            trailing: const Text('0.1.0'), // TODO: 接 package_info_plus
          ),
        ],
      ),
    );
  }
}
