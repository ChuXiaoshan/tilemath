# v1.1 功能包设计（4.2 拒审重提）

**日期**：2026-08-06　**目标版本**：1.1.0+7（iOS 重提审核；Android 同步受益但本轮不发布）
**背景**：1.0.0(6) 于 2026-08-06 被 App Review 以 Guideline 4.2 Minimum Functionality 拒审（审核设备 iPad Air 11-inch M3，拒信为"not enough content"变体，Submission ID f8daa942-1390-4c64-91a7-4dbbe9012269）。
**设计稿**：Claude Design 项目「Tile Calculator」→ `Tile Calculator - v1.1 Feature Pack.dc.html`（轮次 t10：10a 主页 / 10b Materials 交互 / 10c 分享卡片 / 10d iPad 双栏）。

## 1. 范围

核心四件套（已拍板）：

1. **铺贴布局可视化**：结果卡迷你预览（按真实参数绘制）+ 铺法选择器升级为图案卡（Style Round 1 · 1a 原设计，实现时回接）
2. **iPad 原生支持恢复**：解锁 device family 1,2，激活既有 ≥600dp 双栏布局
3. **材料估算（专业可调）**：填缝剂 + 胶粘剂用量，厚度/缝深/镘刀可调、全带默认
4. **结果图片分享**：专用分享卡片离屏渲染 PNG → 系统分享面板

**非目标**：交互式布局编辑器/切割清单、PDF 导出、命名项目、速查参考表、广告/内购恢复、新增语言。

## 2. 计算层

### 2.1 `lib/domain/materials_calculation.dart`（新建，纯函数）

风格对齐 `calculateTiles`：输入对象 → 结果对象 → 纯函数；参数断言在 domain 层，"build 期读取永不抛错"由 controller 层归一保证（同 `CalculatorController.result` 契约）。

**输入**：新增独立 `MaterialsInput` 对象（不改动 `TileCalcInput`，两者由 controller 组合调用，历史算法不受影响）：

| 参数 | 类型 | 默认 | 约束 |
|---|---|---|---|
| tileThickness | `Length` | 5/16″（≈8mm） | > 0 |
| jointDepth | `Length?` | null = 跟随砖厚 | 有效值 = min(jointDepth, tileThickness)，超出按砖厚 clamp |
| trowel | `Trowel?`（enum） | null = Auto 按砖尺寸推荐 | 四档见 2.3 |

**填缝剂**（水泥基，密度取 1.8 kg/L，属行业典型值）：

```
kg = (L + W) / (L × W) × 缝深 × 缝宽 × 1.8 × 净面积㎡ × (1 + 损耗率)
```

L/W/缝深/缝宽单位 mm；缝宽复用现有 `grout` 输入；损耗率与铺法损耗一致（材料与瓷砖同损耗，简单一致的规则）。输出 kg 与 lb 双值（`lb = kg × 2.20462`），显示时按当前单位制排主次。

**胶粘剂**：`袋数 = ceilGuarded(净面积 × (1 + 损耗率) / 每袋覆盖面积)`，向上取整复用 `_ceilGuarded`（浮点护栏语义一致，需从私有提为共享工具或复制）。输出袋数 + 袋规格（英制 50 lb / 公制 20 kg）。

**边界**：净面积 0 → 材料全 0（不显示行）；缝宽 0 → 填缝剂 0 kg（合法，显示 0）。

### 2.2 镘刀覆盖率表（实现时须以 Custom Building Products / Mapei 等厂商公开覆盖表核对定值，下表为设计基准）

| 档位 | ft²/50 lb 袋 | m²/20 kg 袋 |
|---|---|---|
| 3/16″ V | 90 | 7.4 |
| 1/4″×1/4″ | 80 | 6.5 |
| 1/4″×3/8″ | 60 | 4.9 |
| 1/2″×1/2″ | 45 | 3.7 |

**Auto 推荐**（按 max(tileWidth, tileHeight)）：≤100mm → 3/16″ V；≤220mm → 1/4″×1/4″；≤420mm → 1/4″×3/8″；>420mm → 1/2″×1/2″。手动选档后 Auto 退选、推荐 caption 隐藏。

**免责**：结果区材料行下固定 caption「Material amounts are estimates — follow your product's coverage chart.」三语。

### 2.3 `lib/domain/pattern_geometry.dart`（新建，纯函数）

输入：画布尺寸(px)、砖宽/高(mm)、缝宽(mm)、`LayoutPattern` → 输出砖块矩形/路径列表（straight 网格 / diagonal 45° / herringbone 人字互扣 / custom 按 straight 画）。纯几何便于按 CLAUDE.md 要求写"量尺寸、计次数"单测；`lib/ui/pattern_preview.dart` 的 `CustomPainter` 只负责上色（砖=surface 阶、缝=描边色，跟随主题明暗）。预览按真实比例，输入变化实时重绘。

## 3. UI（对应设计稿 t10）

- **主页新增 MATERIALS 区块**（10a）：位于 Boxes & cost 之后、Results 之前；可折叠，**默认参与计算**（与 Boxes & cost"不填=隐藏"语义不同），收起时行尾回显参数摘要（10b 左）。内含：Tile thickness 字段（走现有键盘 imperial inchesOnly / metric mm）、Joint depth 字段（占位显示 "= thickness"）、Trowel 档位 chips（Auto 选中态显示推荐档）。
- **铺法选择器**：`SegmentedButton` 换为四张图案卡（图形 + 名称 + 损耗%），选中态 accent 边框 + accent-100 底（1a/10a 样式）。
- **结果卡 v1.1**（10a/10d）：kicker 行右侧加分享 icon（有结果才显示）；预览图手机 84dp / 双栏 120dp，caption「铺法 · 缝宽」；新增 Grout / Thinset 两行 + 免责 caption。箱数成本行为保持原逻辑（未填隐藏）。
- **分享卡片**（10c）：1080×1350 PNG，浅色主题固定；品牌头（icon + TileMath + 日期）、Tiles needed 大数字、明细行（面积/箱数/成本/材料，未填的行隐藏）、铺贴预览条、参数行、页脚 slogan。
- **iPad**（10d）：竖屏/横屏均走既有 ≥600dp 双栏（[home_page.dart:130](../../lib/ui/home_page.dart)），键盘 56dp 常驻；分屏 <600dp 退化单栏。

## 4. 数据兼容

`HistoryEntry` 追加：`tileThicknessMm: double`、`jointDepthMm: double?`（null=跟随）、`trowelName: String?`（null=Auto，序列化用 enum name，未知值回退 Auto——同 pattern 的向前兼容策略）。`fromJson` 缺字段给默认（老记录可读）；`sameInputs` 纳入新字段；`restoreFrom` 回填。结果摘要不存材料结果（列表不展示，恢复后重算）。

## 5. 分享实现

- 新依赖：`share_plus`（系统分享面板）+ `path_provider`（临时目录）。均为本地插件、无网络请求，不破坏「零数据收集」申报；App Privacy 无需改动。
- 渲染：`dart:ui` Canvas 手绘（`TextPainter` 排版 + `pattern_geometry` 画预览）→ `Picture.toImage(1080, 1350)` → PNG bytes → 写临时文件 `tilemath-share-<ts>.png` → `shareXFiles`。不依赖 widget 树截屏，离屏稳定。
- 文案跟随当前 locale（三语），数字/尺寸恒 LTR 西文数字（沿用全局规则）；阿语环境卡片整体仍为固定版式，文本用本地化字符串。
- 错误处理：无结果时入口不渲染；写文件/分享异常捕获后 SnackBar 提示，不崩溃。

## 6. iOS 工程

- `project.pbxproj` 三处 `TARGETED_DEVICE_FAMILY = "1,2"`（行 367/494/547 现值 "1"）。
- `Info.plist`：iPhone 保持仅 Portrait；新增 `UISupportedInterfaceOrientations~ipad` 四方向；不设 `UIRequiresFullScreen`（支持分屏，双栏布局用 LayoutBuilder 自适应，窄分屏自动退化单栏）。
- 版本号 `pubspec.yaml` → `1.1.0+7`。
- 商店截图：扩展现有截图流水线补 iPad 13″ 档（2064×2752）；ASC 上传为用户操作。

## 7. 本地化

新增 key（约 15–20 个：materials 区块标题/字段标签/档位/Grout/Thinset/袋规格/免责/分享按钮/分享卡页脚等），三语齐全；改 arb 后 `fvm flutter gen-l10n`；改 `app_zh.arb` 后重跑 `tool/fonts/subset_noto_sc.sh`（硬规则）。

## 8. 测试与验收

- domain 单测：材料公式（含 0 面积、缝宽 0、clamp、损耗）、覆盖率查表、Auto 档位边界（100/220/420mm 两侧）、`pattern_geometry` 数砖块/量尺寸断言。
- widget 测试：Materials 区块展开/收起与回显、结果卡材料行显隐、铺法卡选中态、双栏（iPad 竖/横尺寸）下预览 120dp 与分享入口存在性——按 CLAUDE.md 要求写量尺寸断言。
- 分享：单测生成 PNG bytes 非空且尺寸 1080×1350。
- 历史兼容：老 JSON（无新字段）反序列化 + 恢复回填测试。
- 建议运行：`fvm flutter analyze` + `fvm flutter test` 全绿；iPad 模拟器（11″/13″）竖横屏 + 分屏实测；iPhone 回归确认竖屏锁定不变。

## 9. 重提交清单

1. 功能包合入 → 版本 1.1.0(7) → TestFlight 自测（iPhone + iPad）。
2. ASC：补 iPad 13″ 截图；Review Notes 写明针对 4.2 的新增（可视化预览、材料估算套件、分享导出、iPad 原生布局），并点明分数键盘差异化（iOS 品类头部不支持分数英寸）与承包商场景。
3. 重新提交同一 App 版本（被拒后可直接换构建重提，无需申诉）。
4. （可选，并行）在 Resolution Center 回复本次拒审：说明将以功能更新回应，附功能演示视频。
