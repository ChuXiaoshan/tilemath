import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:provider/provider.dart';

import '../ads/interstitial_manager.dart';
import '../domain/length.dart';
import '../domain/tile_calculation.dart';
import '../history/history_controller.dart';
import '../keyboard/metric_editor.dart';
import '../l10n/app_localizations.dart';
import '../state/calculator_controller.dart';
import '../state/settings_controller.dart';
import '../theme/app_dimens.dart';
import 'banner_footer.dart';
import 'format.dart';
import 'history_page.dart';
import 'keyboard/tile_keyboard.dart';
import 'result_card.dart';
import 'settings_page.dart';

/// 主计算页（brief §3.1/3.3）：≥600dp 双栏（输入左 / 结果右），
/// 键盘 ↔ banner 间保留 16dp 非交互隔离带（AdMob 误触政策硬约束）。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 历史存档点之一：app 退后台时快照当前计算。
  /// 预设 chip 完成的计算没有后续 Done 事件，靠这里和"打开 History 前"兜底；
  /// HistoryController 对相同输入去重，多处存档不会刷屏。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _recordCurrentCalculation();
  }

  void _recordCurrentCalculation() {
    final snapshot = context.read<CalculatorController>().snapshot();
    if (snapshot != null) {
      context.read<HistoryController>().record(snapshot);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 单位制 = 显式设置 ?? 地区默认；build 期外同步给计算控制器。
    // 注意：地区判断必须用设备原始 locale——app 的 supportedLocales 是纯语言码，
    // 解析后的 Localizations.localeOf 会丢 countryCode（en_US → en），导致误判公制。
    final settings = context.read<SettingsController>();
    final calc = context.read<CalculatorController>();
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final system = settings.effectiveUnitSystem(deviceLocale);
    if (calc.unitSystem != system) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        calc.unitSystem = system;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final calc = context.watch<CalculatorController>();
    final settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.historyTitle,
            onPressed: () async {
              // 存档点：让当前算完的结果出现在即将打开的列表里
              _recordCurrentCalculation();
              // 自然断点低频插屏：进历史页前尝试展示（频控不满足时静默跳过）
              await InterstitialManager.instance.maybeShow();
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final twoPane = constraints.maxWidth >= 600;
                final form = _InputForm(calc: calc);
                final results = _ResultsSection(
                  calc: calc,
                  settings: settings,
                );
                if (!twoPane) {
                  return Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(AppDimens.space16),
                          children: [
                            form,
                            const SizedBox(height: 24),
                            results,
                          ],
                        ),
                      ),
                      if (calc.editing != null)
                        TileKeyboard(controller: calc),
                    ],
                  );
                }
                // 双栏：输入左 / 结果右（2026-07-24 拍板维持不镜像）；
                // 设计稿 4b：键盘在左栏底部常驻（56dp 键），无焦点时按键无效果
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView(
                              padding:
                                  const EdgeInsets.all(AppDimens.space16),
                              children: [form],
                            ),
                          ),
                          TileKeyboard(controller: calc, tablet: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimens.space32),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(AppDimens.space16),
                        children: [results],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const BannerFooter(),
        ],
      ),
    );
  }
}

/// 输入表单：区域列表 + 瓷砖参数 + 铺法 + 箱规成本。
class _InputForm extends StatelessWidget {
  final CalculatorController calc;

  const _InputForm({required this.calc});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Kicker(l10n.sectionAreas),
        for (var i = 0; i < calc.rows.length; i++) _AreaRow(calc: calc, row: i),
        // Wrap：窄双栏/德语等长文案下换行而不是溢出
        Wrap(
          spacing: AppDimens.space8,
          children: [
            TextButton.icon(
              onPressed: calc.rows.length < CalculatorController.maxRows
                  ? () => calc.addRow()
                  : null,
              icon: const Icon(Icons.add),
              label: Text(l10n.addArea),
            ),
            TextButton.icon(
              onPressed: calc.rows.length < CalculatorController.maxRows
                  ? () => calc.addRow(isCutout: true)
                  : null,
              icon: const Icon(Icons.remove),
              label: Text(l10n.addCutout),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.space24),
        _Kicker(l10n.sectionTile),
        _TileSection(calc: calc),
        const SizedBox(height: AppDimens.space24),
        _Kicker(l10n.layoutPattern),
        _PatternSelector(calc: calc),
        const SizedBox(height: AppDimens.space24),
        _BoxesAndCost(calc: calc),
      ],
    );
  }
}

class _ResultsSection extends StatelessWidget {
  final CalculatorController calc;
  final SettingsController settings;

  const _ResultsSection({required this.calc, required this.settings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Kicker(l10n.sectionResults),
        ResultCard(
          result: calc.result,
          unitSystem: calc.unitSystem,
          currencySymbol: settings.currencySymbol,
          wastePct: (calc.wasteRate * 100).round(),
        ),
      ],
    );
  }
}

/// 区域行：长 × 宽 + 实时面积 + 删除。cutout 行用 tertiary 色区分 + 负值面积。
class _AreaRow extends StatelessWidget {
  final CalculatorController calc;
  final int row;

  const _AreaRow({required this.calc, required this.row});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final data = calc.rows[row];
    final area = data.areaSqM;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _ValueField(
              calc: calc,
              id: FieldId(FieldKind.areaLength, row),
              label: data.isCutout
                  ? '${l10n.cutout} · ${l10n.length}'
                  : l10n.length,
              value: data.length,
              metricUnit: MetricUnit.m,
              accent: data.isCutout,
            ),
          ),
          const SizedBox(width: AppDimens.space8),
          Expanded(
            child: _ValueField(
              calc: calc,
              id: FieldId(FieldKind.areaWidth, row),
              label: l10n.width,
              value: data.width,
              metricUnit: MetricUnit.m,
              accent: data.isCutout,
            ),
          ),
          const SizedBox(width: AppDimens.space8),
          SizedBox(
            width: 88,
            child: Text(
              area == null
                  ? ''
                  : (data.isCutout
                      ? '−${formatArea(-area, calc.unitSystem, locale)}'
                      : formatArea(area, calc.unitSystem, locale)),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.end,
              style: text.bodyMedium!.copyWith(
                color: data.isCutout ? scheme.tertiary : scheme.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: l10n.delete,
            onPressed: () => calc.removeRow(row),
          ),
        ],
      ),
    );
  }
}

/// 可点值字段：编辑态显示编辑器实时文本 + secondary 描边。
/// 激活（点击 / Next 推进 / addRow 自动聚焦）后 post-frame 自动滚入视口，
/// 保证不被展开的键盘遮挡（brief §3.2 硬性要求）。
class _ValueField extends StatefulWidget {
  final CalculatorController calc;
  final FieldId id;
  final String label;
  final Length? value;
  final MetricUnit metricUnit;
  final bool accent;

  const _ValueField({
    required this.calc,
    required this.id,
    required this.label,
    required this.value,
    required this.metricUnit,
    this.accent = false,
  });

  @override
  State<_ValueField> createState() => _ValueFieldState();
}

class _ValueFieldState extends State<_ValueField> {
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
    target =
        target.clamp(position.minScrollExtent, position.maxScrollExtent)
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
      display = calc.imperialEditor?.displayText ??
          (calc.metricEditor == null
              ? ''
              : calc.metricEditor!.isEmpty
                  ? ''
                  : '${calc.metricEditor!.text} ${calc.metricEditor!.unit.name}');
    } else if (widget.value != null) {
      display =
          formatLength(widget.value!, calc.unitSystem, widget.metricUnit, locale);
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
            constraints:
                const BoxConstraints(minHeight: AppDimens.minTouchTarget),
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
            child: Text(
              display,
              textDirection: TextDirection.ltr, // 尺寸表达式恒 LTR
              style: text.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }
}

/// 瓷砖尺寸区（brief §3.1）：预设 chips + `Custom` 项；
/// W/H 输入框仅在 Custom 选中（或正被编辑）时展开，Grout 恒显（核心卖点不藏）。
/// Custom 文案复用 l10n.patternCustom（语义相同）。
class _TileSection extends StatefulWidget {
  final CalculatorController calc;

  const _TileSection({required this.calc});

  @override
  State<_TileSection> createState() => _TileSectionState();
}

class _TileSectionState extends State<_TileSection> {
  static const _imperialPresets = [
    (4, 4), (6, 6), (12, 12), (12, 24), (18, 18), (24, 24), (24, 48),
  ];
  // 公制常见规格（cm）；brief 未给清单，按市场惯例
  static const _metricPresets = [
    (20, 20), (30, 30), (30, 60), (45, 45), (60, 60), (60, 120),
  ];

  /// 用户显式选择了 Custom（点 chip 或手动编辑过 W/H）；点预设 chip 清除。
  bool _customChosen = false;

  @override
  Widget build(BuildContext context) {
    final calc = widget.calc;
    final l10n = AppLocalizations.of(context);
    final imperial = calc.unitSystem == UnitSystem.imperial;
    final presets = imperial ? _imperialPresets : _metricPresets;
    Length toLength(int v) =>
        imperial ? Length.ofInches(v.toDouble()) : Length.ofCm(v.toDouble());
    bool matches((int, int) p) =>
        calc.tileWidth?.mm == toLength(p.$1).mm &&
        calc.tileHeight?.mm == toLength(p.$2).mm;

    // 编辑焦点在 W/H 上（点击或 Next 推进）＝手动改动，粘性选中 Custom。
    // build 内直接赋值（不 setState）：本帧已按该值渲染，无需再触发重建。
    final editingSize = calc.editing?.kind == FieldKind.tileWidth ||
        calc.editing?.kind == FieldKind.tileHeight;
    if (editingSize) _customChosen = true;
    // Custom 选中 = 显式点选 / 手动编辑过 / 当前值不匹配任何预设（含未录入）
    final customSelected = _customChosen || !presets.any(matches);

    final groutField = _ValueField(
      calc: calc,
      id: const FieldId(FieldKind.grout),
      label: l10n.groutWidth,
      value: calc.grout,
      metricUnit: MetricUnit.mm,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final p in presets)
                Padding(
                  padding:
                      const EdgeInsetsDirectional.only(end: AppDimens.space8),
                  child: ChoiceChip(
                    label: Text(
                      '${p.$1}×${p.$2}',
                      textDirection: TextDirection.ltr,
                    ),
                    selected: !customSelected && matches(p),
                    onSelected: (_) {
                      setState(() => _customChosen = false);
                      calc.setTilePreset(toLength(p.$1), toLength(p.$2));
                    },
                  ),
                ),
              ChoiceChip(
                label: Text(l10n.patternCustom),
                selected: customSelected,
                onSelected: (_) => setState(() => _customChosen = true),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.space12),
        Row(
          children: [
            if (customSelected) ...[
              Expanded(
                child: _ValueField(
                  calc: calc,
                  id: const FieldId(FieldKind.tileWidth),
                  label: l10n.tileWidth,
                  value: calc.tileWidth,
                  metricUnit: MetricUnit.cm,
                ),
              ),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: _ValueField(
                  calc: calc,
                  id: const FieldId(FieldKind.tileHeight),
                  label: l10n.tileHeight,
                  value: calc.tileHeight,
                  metricUnit: MetricUnit.cm,
                ),
              ),
              const SizedBox(width: AppDimens.space12),
              Expanded(child: groutField),
            ] else ...[
              // 预设选中：只留缝宽小输入框，宽度与三列布局的单列对齐
              Expanded(child: groutField),
              const SizedBox(width: AppDimens.space12),
              const Spacer(flex: 2),
            ],
          ],
        ),
      ],
    );
  }
}

/// 铺贴方式四选一 + Custom 滑块（brief §3.1：10/15/20/自定义 0-30%）。
class _PatternSelector extends StatelessWidget {
  final CalculatorController calc;

  const _PatternSelector({required this.calc});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    String nameOf(LayoutPattern p) => switch (p) {
          LayoutPattern.straight => l10n.patternStraight,
          LayoutPattern.diagonal => l10n.patternDiagonal,
          LayoutPattern.herringbone => l10n.patternHerringbone,
          LayoutPattern.custom => l10n.patternCustom,
        };
    // 各铺法损耗百分比（brief §3.1：选项旁必须标注）；Custom 显示当前滑块值
    int pctOf(LayoutPattern p) => p == LayoutPattern.custom
        ? calc.customWastePct
        : (p.wasteRate! * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 撑满整行：紧约束下段宽均分，长文案（德语等）段内换行而不溢出
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<LayoutPattern>(
            style: const ButtonStyle(
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(
                  horizontal: AppDimens.space8,
                  vertical: AppDimens.space8,
                ),
              ),
            ),
            segments: [
              for (final p in LayoutPattern.values)
                ButtonSegment(
                  value: p,
                  // 两行 label：名称（可换行）+ 损耗百分比（恒 LTR）
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nameOf(p),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${pctOf(p)}%',
                        textDirection: TextDirection.ltr,
                        style: text.labelSmall!
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
            ],
            selected: {calc.pattern},
            onSelectionChanged: (s) => calc.setPattern(s.first),
          ),
        ),
        const SizedBox(height: AppDimens.space8),
        Text(
          '${l10n.wastePercent} ${(calc.wasteRate * 100).round()}%',
          textDirection: TextDirection.ltr,
          style: text.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (calc.pattern == LayoutPattern.custom)
          Slider(
            value: calc.customWastePct.toDouble(),
            min: 0,
            max: 30,
            divisions: 30,
            label: '${calc.customWastePct}%',
            onChanged: (v) => calc.setCustomWaste(v.round()),
          ),
      ],
    );
  }
}

/// 箱规与成本（可折叠，默认收起；数字输入走系统键盘）。
/// TextField 挂 controller 并从计算状态初始化：单/双栏切换或折叠重建后
/// 显示值与数据保持一致（不丢已录入内容）。
class _BoxesAndCost extends StatefulWidget {
  final CalculatorController calc;

  const _BoxesAndCost({required this.calc});

  @override
  State<_BoxesAndCost> createState() => _BoxesAndCostState();
}

class _BoxesAndCostState extends State<_BoxesAndCost> {
  late final TextEditingController _tilesCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    final calc = widget.calc;
    _tilesCtrl =
        TextEditingController(text: calc.tilesPerBox?.toString() ?? '');
    _priceCtrl = TextEditingController(text: _priceText(calc.pricePerBox));
  }

  /// 整数价格不带小数尾巴（12.0 → '12'）。
  static String _priceText(double? price) {
    if (price == null) return '';
    return price % 1 == 0 ? price.toStringAsFixed(0) : price.toString();
  }

  @override
  void dispose() {
    _tilesCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  /// 点系统输入框时若自定义键盘开着：提交当前编辑值并收起，避免两键盘堆叠。
  void _dismissCustomKeyboard() {
    if (widget.calc.editing != null) widget.calc.commitAndClose();
  }

  @override
  Widget build(BuildContext context) {
    final calc = widget.calc;
    final l10n = AppLocalizations.of(context);
    return ExpansionTile(
      title: Text(l10n.boxesAndCost),
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      childrenPadding: const EdgeInsets.only(bottom: AppDimens.space8),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tilesCtrl,
                decoration: InputDecoration(labelText: l10n.tilesPerBox),
                keyboardType: TextInputType.number,
                onTap: _dismissCustomKeyboard,
                onChanged: (v) => calc.setBoxInfo(
                  tilesPerBox: int.tryParse(v),
                  pricePerBox: calc.pricePerBox,
                ),
              ),
            ),
            const SizedBox(width: AppDimens.space12),
            Expanded(
              child: TextField(
                controller: _priceCtrl,
                decoration: InputDecoration(labelText: l10n.pricePerBox),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onTap: _dismissCustomKeyboard,
                onChanged: (v) => calc.setBoxInfo(
                  tilesPerBox: calc.tilesPerBox,
                  pricePerBox: double.tryParse(v),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 区块标题（labelMedium 大写 + 字距，token 表 labelMedium 用法）。
class _Kicker extends StatelessWidget {
  final String label;

  const _Kicker(this.label);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.space12),
      child: Text(
        label.toUpperCase(),
        style: text.labelMedium!.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

