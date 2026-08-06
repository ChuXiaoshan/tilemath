import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';

import '../domain/length.dart';
import '../domain/tile_calculation.dart';
import '../history/history_controller.dart';
import '../keyboard/metric_editor.dart';
import '../l10n/app_localizations.dart';
import '../state/calculator_controller.dart';
import '../state/settings_controller.dart';
import '../theme/app_dimens.dart';
import 'format.dart';
import 'history_page.dart';
import 'keyboard/tile_keyboard.dart';
import 'materials_section.dart';
import 'result_card.dart';
import 'settings_page.dart';
import 'value_field.dart';

/// 主计算页（brief §3.1/3.3）：≥600dp 双栏（输入左 / 结果右）。
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

  /// 离开主页前收起两种键盘。系统 IME 的焦点若留在输入框上，路由弹回时
  /// iOS 会自动恢复焦点并重新弹出键盘——用户回到主页就被键盘怼脸。
  void _dismissKeyboards() {
    FocusManager.instance.primaryFocus?.unfocus();
    final calc = context.read<CalculatorController>();
    if (calc.editing != null) calc.commitAndClose();
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
      // iOS 纯数字键盘没有 return 键，系统键盘弹出时给一条 Done 横条兜底。
      // 必须在无系统键盘时返回 null 而非空 widget——非 null 的
      // bottomNavigationBar 会让 Scaffold 移除 body 的底部安全区 padding，
      // 那正是自定义键盘让出 Home Indicator 所依赖的。
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? const _KeyboardDoneBar()
          : null,
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.historyTitle,
            onPressed: () async {
              _dismissKeyboards();
              // 存档点：让当前算完的结果出现在即将打开的列表里
              _recordCurrentCalculation();
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const HistoryPage()));
              // 弹回时 Flutter 会恢复离开前的焦点，不再收一次系统键盘会自己冒出来
              if (mounted) _dismissKeyboards();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () async {
              _dismissKeyboards();
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
              if (mounted) _dismissKeyboards();
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 双栏分支的键盘是常驻的，光看宽度会让 iPhone 横屏（如 667×375）
          // 也落进来——那点高度放不下常驻键盘，表单会被压成 0 高。
          final twoPane =
              constraints.maxWidth >= 600 && constraints.maxHeight >= 600;
          final form = _InputForm(calc: calc);
          final results =
              _ResultsSection(calc: calc, settings: settings, twoPane: twoPane);
          if (!twoPane) {
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    // 下拉即收系统键盘（iOS 数字键盘无 return 键）
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    // 键盘在场时由键盘负责垫底部安全区，此处不能重复加
                    padding: EdgeInsets.fromLTRB(
                      AppDimens.space16,
                      AppDimens.space16,
                      AppDimens.space16,
                      AppDimens.space16 +
                          (calc.editing != null
                              ? 0
                              : MediaQuery.paddingOf(context).bottom),
                    ),
                    children: [form, const SizedBox(height: 24), results],
                  ),
                ),
                if (calc.editing != null) TileKeyboard(controller: calc),
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
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.all(AppDimens.space16),
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
                  // 右栏没有键盘垫底，自行让出安全区
                  padding: EdgeInsets.fromLTRB(
                    AppDimens.space16,
                    AppDimens.space16,
                    AppDimens.space16,
                    AppDimens.space16 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [results],
                ),
              ),
            ],
          );
        },
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
        const SizedBox(height: AppDimens.space24),
        MaterialsSection(calc: calc),
      ],
    );
  }
}

class _ResultsSection extends StatelessWidget {
  final CalculatorController calc;
  final SettingsController settings;

  /// 双栏布局：预览放大到 120dp（单栏 84dp）。
  final bool twoPane;

  const _ResultsSection({
    required this.calc,
    required this.settings,
    this.twoPane = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Kicker(l10n.sectionResults),
        ResultCard(
          result: calc.result,
          materials: calc.materialsResult,
          tileWidth: calc.tileWidth,
          tileHeight: calc.tileHeight,
          grout: calc.grout,
          pattern: calc.pattern,
          previewSize: twoPane ? 120 : 84,
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
            child: ValueField(
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
            child: ValueField(
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
                color: data.isCutout
                    ? scheme.tertiary
                    : scheme.onSurfaceVariant,
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
    (4, 4),
    (6, 6),
    (12, 12),
    (12, 24),
    (18, 18),
    (24, 24),
    (24, 48),
  ];
  // 公制常见规格（cm）；brief 未给清单，按市场惯例
  static const _metricPresets = [
    (20, 20),
    (30, 30),
    (30, 60),
    (45, 45),
    (60, 60),
    (60, 120),
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
    final editingSize =
        calc.editing?.kind == FieldKind.tileWidth ||
        calc.editing?.kind == FieldKind.tileHeight;
    if (editingSize) _customChosen = true;
    // Custom 选中 = 显式点选 / 手动编辑过 / 当前值不匹配任何预设（含未录入）
    final customSelected = _customChosen || !presets.any(matches);

    final groutField = ValueField(
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
                  padding: const EdgeInsetsDirectional.only(
                    end: AppDimens.space8,
                  ),
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
                child: ValueField(
                  calc: calc,
                  id: const FieldId(FieldKind.tileWidth),
                  label: l10n.tileWidth,
                  value: calc.tileWidth,
                  metricUnit: MetricUnit.cm,
                ),
              ),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: ValueField(
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
        // 四张等宽图案卡（设计稿 10a/1a）：LayoutBuilder 按可用宽度均分四列。
        // 降级规则（brief §2 v2.1）：长文案缩小字号而非换行——名称行定高 +
        // FittedBox，卡片 minHeight 72，四卡恒等高不跳动。
        LayoutBuilder(builder: (context, constraints) {
          final cardW =
              (constraints.maxWidth - 3 * AppDimens.space8) / 4;
          return Row(
            children: [
              for (final p in LayoutPattern.values) ...[
                if (p != LayoutPattern.values.first)
                  const SizedBox(width: AppDimens.space8),
                SizedBox(
                  width: cardW,
                  child: _PatternCard(
                    pattern: p,
                    name: nameOf(p),
                    pct: pctOf(p),
                    selected: calc.pattern == p,
                    onTap: () => calc.setPattern(p),
                  ),
                ),
              ],
            ],
          );
        }),
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
            // 每跨过一个刻度给一次轻触反馈（iOS 的 UISelectionFeedbackGenerator）。
            // 必须先比对整数值：拖动时 onChanged 在同一刻度内会连续回调，
            // 不判重会变成持续震动，也会白白触发一堆 notifyListeners。
            onChanged: (v) {
              final pct = v.round();
              if (pct == calc.customWastePct) return;
              HapticFeedback.selectionClick();
              calc.setCustomWaste(pct);
            },
          ),
      ],
    );
  }
}

/// 铺法图案卡（设计稿 10a/1a）：缩略图 + 名称 + 损耗%，选中态 secondary
/// 描边 + primaryContainer 底。名称行 FittedBox 缩字不换行，四卡恒等高。
class _PatternCard extends StatelessWidget {
  final LayoutPattern pattern;
  final String name;
  final int pct;
  final bool selected;
  final VoidCallback onTap;

  const _PatternCard({
    required this.pattern,
    required this.name,
    required this.pct,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppDimens.radius2),
      child: InkWell(
        key: ValueKey('pattern-card-${pattern.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radius2),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space4,
            vertical: AppDimens.space8,
          ),
          // 描边放 foregroundDecoration 而非 decoration：Container 会把
          // decoration 的 border.dimensions 自动并入内边距，选中态 1.5dp
          // 与未选中 1dp 的宽度差会让四卡布局高度错开 1dp（四卡等高断言会炸）。
          // foregroundDecoration 只做叠加描边，不参与内边距计算。
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radius2),
            border: Border.all(
              color: selected ? scheme.secondary : scheme.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size.square(20),
                painter: _PatternGlyphPainter(pattern: pattern, color: fg),
              ),
              const SizedBox(height: AppDimens.space4),
              SizedBox(
                height: 18,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name,
                    maxLines: 1,
                    softWrap: false,
                    style: text.labelLarge!.copyWith(color: fg),
                  ),
                ),
              ),
              Text(
                '$pct%',
                textDirection: TextDirection.ltr,
                style: text.labelSmall!.copyWith(
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 20dp 铺法缩略图（线稿，与设计稿 1a 图形一致）。
class _PatternGlyphPainter extends CustomPainter {
  final LayoutPattern pattern;
  final Color color;

  const _PatternGlyphPainter({required this.pattern, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;
    final s = size.width;
    switch (pattern) {
      case LayoutPattern.straight:
        canvas.drawRect(Rect.fromLTWH(s * .15, s * .15, s * .7, s * .7), paint);
        canvas.drawLine(Offset(s * .5, s * .15), Offset(s * .5, s * .85), paint);
        canvas.drawLine(Offset(s * .15, s * .5), Offset(s * .85, s * .5), paint);
      case LayoutPattern.diagonal:
        canvas.save();
        canvas.translate(s / 2, s / 2);
        canvas.rotate(0.785398); // 45°
        canvas.translate(-s / 2, -s / 2);
        canvas.drawRect(
            Rect.fromLTWH(s * .225, s * .225, s * .55, s * .55), paint);
        canvas.drawLine(Offset(s * .5, s * .225), Offset(s * .5, s * .775), paint);
        canvas.drawLine(Offset(s * .225, s * .5), Offset(s * .775, s * .5), paint);
        canvas.restore();
      case LayoutPattern.herringbone:
        final path = Path()
          ..moveTo(s * .15, s * .70)
          ..lineTo(s * .40, s * .45)
          ..lineTo(s * .55, s * .60)
          ..lineTo(s * .30, s * .85)
          ..close()
          ..moveTo(s * .45, s * .40)
          ..lineTo(s * .70, s * .15)
          ..lineTo(s * .85, s * .30)
          ..lineTo(s * .60, s * .55)
          ..close();
        canvas.drawPath(path, paint);
      case LayoutPattern.custom:
        canvas.drawLine(Offset(s * .15, s * .5), Offset(s * .85, s * .5), paint);
        canvas.drawCircle(Offset(s * .6, s * .5), s * .15, paint);
    }
  }

  @override
  bool shouldRepaint(_PatternGlyphPainter oldDelegate) =>
      pattern != oldDelegate.pattern || color != oldDelegate.color;
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
  late final FocusNode _tilesFocus;
  late final FocusNode _priceFocus;

  @override
  void initState() {
    super.initState();
    final calc = widget.calc;
    _tilesCtrl = TextEditingController(
      text: calc.tilesPerBox?.toString() ?? '',
    );
    _priceCtrl = TextEditingController(text: _priceText(calc.pricePerBox));
    _tilesFocus = FocusNode()..addListener(_onFocusChanged);
    _priceFocus = FocusNode()..addListener(_onFocusChanged);
    widget.calc.addListener(_syncFromModel);
  }

  /// 从历史恢复等外部改值时把输入框拉回一致。只在两点成立时才写：
  /// 该框没有焦点（不能打断用户正在输入），且文本与模型值确实不同
  /// （否则每次 notifyListeners 都重置光标位置）。
  void _syncFromModel() {
    if (!mounted) return;
    final tiles = widget.calc.tilesPerBox?.toString() ?? '';
    if (!_tilesFocus.hasFocus && _tilesCtrl.text != tiles) {
      _tilesCtrl.text = tiles;
    }
    final price = _priceText(widget.calc.pricePerBox);
    if (!_priceFocus.hasFocus && _priceCtrl.text != price) {
      _priceCtrl.text = price;
    }
  }

  /// 「同时只有一个键盘」必须是不变量，不能只靠 onTap 兜。焦点也可能由
  /// 路由弹回时的焦点恢复等非点击途径落到输入框上，那时若自定义键盘还开着，
  /// 两个键盘就会叠在一起。
  void _onFocusChanged() {
    if (!_tilesFocus.hasFocus && !_priceFocus.hasFocus) return;
    if (widget.calc.editing != null) widget.calc.commitAndClose();
  }

  /// 整数价格不带小数尾巴（12.0 → '12'）。
  static String _priceText(double? price) {
    if (price == null) return '';
    return price % 1 == 0 ? price.toStringAsFixed(0) : price.toString();
  }

  @override
  void dispose() {
    widget.calc.removeListener(_syncFromModel);
    _tilesCtrl.dispose();
    _priceCtrl.dispose();
    _tilesFocus.dispose();
    _priceFocus.dispose();
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
                focusNode: _tilesFocus,
                decoration: InputDecoration(labelText: l10n.tilesPerBox),
                keyboardType: TextInputType.number,
                onTap: _dismissCustomKeyboard,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
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
                focusNode: _priceFocus,
                decoration: InputDecoration(labelText: l10n.pricePerBox),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onTap: _dismissCustomKeyboard,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                onChanged: (v) => calc.setBoxInfo(
                  tilesPerBox: calc.tilesPerBox,
                  // 逗号分隔符地区（fr/de/pt-BR 等）的系统键盘给出的是
                  // "30,5"，直接 tryParse 得 null，成本行会静默消失。
                  pricePerBox: double.tryParse(v.replaceAll(',', '.')),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 系统键盘上方的 Done 横条。箱规/成本两个字段走系统数字键盘，
/// 而 iOS 数字键盘不带 return 键，没有这条用户就只能靠点空白处猜。
class _KeyboardDoneBar extends StatelessWidget {
  const _KeyboardDoneBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 必须自行约束高度：bottomNavigationBar 槽位给的是松约束，
    // Align 之类不带 heightFactor 的布局会撑满整屏、把 body 压成 0 高。
    return Material(
      color: scheme.surfaceContainerHigh,
      child: SizedBox(
        height: AppDimens.minTouchTarget,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => FocusScope.of(context).unfocus(),
              child: Text(AppLocalizations.of(context).keyDone),
            ),
            const SizedBox(width: AppDimens.space8),
          ],
        ),
      ),
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
