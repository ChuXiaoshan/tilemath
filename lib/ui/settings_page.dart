import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../state/settings_controller.dart';
import '../theme/app_dimens.dart';

/// 产品语言清单：语言码 → 母语自称（设计稿 5b，自称不翻译）。
/// 当前实现 en/zh/ar，其余语言随 ARB 落地逐个开放。
const _languageNames = {'en': 'English', 'zh': '中文（简体）', 'ar': 'العربية'};

/// 隐私政策托管地址。审核指南 5.1.1(i) 要求 app 内也能访问，
/// 必须与 App Store Connect 里填的是同一份。
const _privacyPolicyUrl = 'https://xs-albus.github.io/privacy.html';

/// App Store 条目 ID，用于跳转评分页。
const _appStoreId = '6795019764';


/// 打开外部链接，失败时给出可见反馈（静默失败等同于按钮没反应）。
Future<void> _openExternal(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = AppLocalizations.of(context).linkOpenFailed;
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok) messenger.showSnackBar(SnackBar(content: Text(message)));
}

/// 评分入口走 openStoreListing 而非 requestReview：后者有系统配额
/// （365 天内每用户至多 3 次）且不保证展示，用户主动点击却毫无反应
/// 比没有入口更糟。requestReview 留给将来的自然时机触发。
Future<void> _openStoreReview(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = AppLocalizations.of(context).linkOpenFailed;
  try {
    await InAppReview.instance.openStoreListing(appStoreId: _appStoreId);
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// 设置页（brief §3.6 / 设计稿 5b）：Units 行内紧凑分段（短标签）、
/// Language/Appearance 值+chevron 进子页、行间极细分隔线（组件内允许）。
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
      _UnitsRow(
        selected: settings.effectiveUnitSystem(deviceLocale),
        onChanged: settings.setUnitSystem,
      ),
      _ChevronRow(
        title: l10n.language,
        value: languageLabel,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LanguagePage())),
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
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AppearancePage())),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        // 显式 padding 会让 ListView 跳过 MediaQuery 底 inset 的自动补偿
        padding: EdgeInsets.fromLTRB(
          AppDimens.space16,
          AppDimens.space16,
          AppDimens.space16,
          AppDimens.space16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          // 行间极细分隔线（outlineVariant hairline，组件内允许）
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            rows[i],
          ],
          const SizedBox(height: AppDimens.space24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.privacyPolicy),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () =>
                _openExternal(context, Uri.parse(_privacyPolicyUrl)),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.rateApp),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openStoreReview(context),
          ),
          const Divider(height: 1),
          const _VersionRow(),
        ],
      ),
    );
  }
}

/// 单位制切换行（设计稿 5b：标题在左、紧凑分段在右）。
///
/// 默认维持设计稿的左右布局，但**不能**把分段控件塞进 `ListTile.trailing`
/// ——trailing 拿到的是松约束，控件会吃满整行、把标题挤成负宽，进而击穿
/// 整条布局链（375dp 机型配 iOS 标准最大字号 ≈1.35 即可触发）。
/// 这里用两端都带 flex 的 Row 保证双方宽度都有界；字号继续放大到左右排不下时，
/// 退化成上下堆叠——与铺法选择器"降级只缩不换行"的思路一致。
class _UnitsRow extends StatelessWidget {
  final UnitSystem selected;
  final ValueChanged<UnitSystem> onChanged;

  const _UnitsRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final stacked = scale > 1.15;

    final title = Text(l10n.units, style: Theme.of(context).textTheme.bodyLarge);
    final control = SegmentedButton<UnitSystem>(
      // 选中 ✓ 图标会在长本地化标签下挤压换行，选中态由填色表达
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        ButtonSegment(value: UnitSystem.imperial, label: Text(l10n.unitImperial)),
        ButtonSegment(value: UnitSystem.metric, label: Text(l10n.unitMetric)),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space12),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: AppDimens.space8),
                SizedBox(width: double.infinity, child: control),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 2, child: title),
                const SizedBox(width: AppDimens.space12),
                Expanded(flex: 3, child: control),
              ],
            ),
    );
  }
}

/// 版本号行：取自包信息，避免与 pubspec 手工同步而失配。
/// 刻意用 State 持有 Future 而非顶层 final —— 顶层 final 是整个 isolate
/// 共享的可变状态，一次解析失败就永久缓存，测试之间也会互相污染。
class _VersionRow extends StatefulWidget {
  const _VersionRow();

  @override
  State<_VersionRow> createState() => _VersionRowState();
}

class _VersionRowState extends State<_VersionRow> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _info,
      // 读取失败或未完成时留空而非占位符，避免版本号闪烁跳动
      builder: (context, snapshot) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(AppLocalizations.of(context).versionLabel),
        trailing: Text(snapshot.data?.version ?? ''),
      ),
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
            // height 置 1：正文行高是 1.5，字形贴基线而非在盒内居中，
            // 与图标按盒子居中对齐时视觉上会偏。单行内联值不需要段落行高。
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1,
            ),
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
        onTap: () =>
            settings.setLocaleOverride(code == null ? null : Locale(code)),
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
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
    );
  }
}
