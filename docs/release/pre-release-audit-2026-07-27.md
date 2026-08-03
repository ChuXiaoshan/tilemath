已用实测复核过关键项。以下是最终裁定。

---

# TileMath 1.0.0 上架前最终裁定

## 1. 一句话结论

**现在不能提交。** 有 3 个我亲自跑测试复现的硬缺陷（其中 2 个是任何用户都能在 30 秒内撞上的），必须修完再打包。修完这 3~4 条即可提交，其余问题都不阻塞。

---

## 2. 必修（发布前）

### M1. 「Tiles per box」输入 `0` → build 期抛异常，结果区被 ErrorWidget 顶掉、History 按钮同时变死按钮

- **位置**：`/Users/chuxiaoshan/project/indev/tile/tilemath/lib/state/calculator_controller.dart:161-165`（`setBoxInfo` 无任何校验）→ 抛出点 `/Users/chuxiaoshan/project/indev/tile/tilemath/lib/domain/tile_calculation.dart:93-95`；UI 入口 `/Users/chuxiaoshan/project/indev/tile/tilemath/lib/ui/home_page.dart:789`
- **触发**：先做出一个有效计算（12′×10′ 区域 + 选中 12×12 预设，结果 131）→ 展开 "Boxes & cost" → 在 Tiles per box 里让文本变成 `0`。两条真实路径：直接首字符打 0；或把已填的 `10` 改成 `20` 时先删首位，中间态就是 `0`。iOS 上该字段是 `TextInputType.number`（纯数字盘），`0` 是键盘唯一能录入的非法值，不需要粘贴。
- **我的实测**（widget 测试，端到端跑通）：
  - 选预设后 `HAS_131=1`（结果正常）
  - `enterText('0')` 后 → `AFTER_ZERO_EXC=Invalid argument(s): 箱规必须大于 0`
  - 同帧 → `ERRORWIDGET_COUNT=1`，"131" 消失（Release 下是灰块，不是黄条）
  - 紧接着点 AppBar 的 History → `HISTORY_OPENED=0`，异常被手势回调吞掉，历史页根本没打开
  - 此状态下退后台（`didChangeAppLifecycleState` → `_recordCurrentCalculation`，`home_page.dart:45`）同样抛异常
- **注意**：`result` getter 上面写着注释「保证 build 期读取永不抛错」（`calculator_controller.dart:98-99`），它守住了 `tileWidth/tileHeight`，唯独漏了 `tilesPerBox/pricePerBox` 这两个来自系统 IME、完全没有 InputFormatter 的值。这是原设计意图和实现之间的漏洞，不是设计取舍。
- **改法**：在 `setBoxInfo` 里把非法值归一成 null，不要往下传：
  ```dart
  this.tilesPerBox  = (tilesPerBox != null && tilesPerBox > 0) ? tilesPerBox : null;
  this.pricePerBox  = (pricePerBox != null && pricePerBox.isFinite && pricePerBox >= 0) ? pricePerBox : null;
  ```
  `isFinite` 顺带挡住粘贴 `1e400` 导致成本显示 `$∞`。domain 层的 ArgumentError 保留作契约断言，别删。UI 层加 FilteringTextInputFormatter 只是加固，不能替代兜底。

---

### M2. iPhone 横屏落进为平板写的双栏分支：输入表单高度归零，键盘一半在屏幕外

- **位置**：`/Users/chuxiaoshan/project/indev/tile/tilemath/lib/ui/home_page.dart:126`（`constraints.maxWidth >= 600` 只看宽度）+ `:170`（双栏分支里 TileKeyboard 无条件常驻，与 `calc.editing` 无关）；横屏可达性来自 `/Users/chuxiaoshan/project/indev/tile/tilemath/ios/Runner/Info.plist:66-71`
- **触发**：任意 iPhone 把手机横过来。我 grep 过 `lib/ ios/ android/`，`setPreferredOrientations` / `DeviceOrientation` / `supportedInterfaceOrientations` **零命中**，没有任何上游守卫；Info.plist 明确列了 LandscapeLeft/Right。iPhone 横屏宽度全部 ≥ 667 > 600。
- **我的实测**（667×375，dpr=1，英制）：
  ```
  LANDSCAPE_EXCEPTION = A RenderFlex overflowed by 97 pixels on the bottom.
  LV0(左栏输入表单) rect = Rect.fromLTRB(0.0, 56.0, 317.5, 56.0)   ← 高度 0
  FIELD_COUNT = 0                                                  ← 区域行一个像素都不渲染
  KEYBOARD_RECT = Rect.fromLTRB(0.0, 56.0, 317.5, 472.0)           ← 屏高只有 375
  ```
  竖屏 390×844 对照组：`PORTRAIT_EXCEPTION=null`，`FIELD_COUNT=1`，干净。
  实际效果：横屏只剩右侧结果栏 + 被裁掉底排（0 / C / Next / Done 全部看不见）的半截键盘，既无法输入也无法收键盘。Release 无黄黑条，直接静默裁切。真机还要再减底部安全区，只会更糟。
- **额外事实**：`TARGETED_DEVICE_FAMILY=1`（仅 iPhone），意味着这条双栏路径在真机上**唯一的进入方式就是横屏**——它当前只会以坏状态出现，从来没有正确出现过。
- **改法**：Info.plist:66-71 只留 `UIInterfaceOrientationPortrait`，删掉两个 Landscape 项。iPhone-only 的计算器不需要横屏，这是最省事且符合定位的做法。若坚持保留横屏，判据必须加高度门槛（`maxWidth >= 600 && maxHeight >= 600`），否则横屏仍会落进常驻键盘布局。

---

### M3. 设备语言不是 en/zh/ar 时，整个 App 回退到阿拉伯语 + 全屏 RTL

- **位置**：`/Users/chuxiaoshan/project/indev/tile/tilemath/lib/main.dart:50`（`supportedLocales: AppLocalizations.supportedLocales`，且 MaterialApp 未提供任何 `localeResolutionCallback`）；生成物 `/Users/chuxiaoshan/project/indev/tile/tilemath/lib/l10n/app_localizations.dart:97-101` 的列表按字母序，**首项是 `ar`**
- **触发**：首次启动、用户从未在 Settings 里选过语言（`localeOverride == null`，见 `lib/state/settings_controller.dart:32`），且设备语言不是 en/zh/ar。**美区把系统语言设成 Español 的用户极其常见。**
- **我的实测**（直接调 Flutter 的 `basicLocaleListResolution`，用项目真实的 supportedLocales）：
  ```
  RESOLVED_FR = ar
  RESOLVED_ES = ar
  RESOLVED_PT = ar
  ```
  匹配不上时 Flutter 返回 `supportedLocales.first`，而 gen-l10n 生成的首项就是 ar。西班牙语用户首次打开看到的是阿拉伯语 + 整屏镜像布局。
- **可恢复但首屏已经废了**：用户能进 Settings 手动改（语言名用母语显示），但绝大多数人此时已经删了。
- **改法**：在 `main.dart` 的 MaterialApp 上显式兜底英语，不要依赖生成列表顺序：
  ```dart
  localeListResolutionCallback: (deviceLocales, supported) {
    for (final l in deviceLocales ?? const <Locale>[]) {
      for (final s in supported) {
        if (s.languageCode == l.languageCode) return s;
      }
    }
    return const Locale('en');
  },
  ```
  建议同时补一条测试：设备 locale = fr_FR / es_US 时 `Localizations.localeOf(context).languageCode` 必须是 `en`。

---

### M4. 设置页 Units 行在大字号下布局链断裂（375dp 机型 + iOS 标准最大字号即可触发）

- **位置**：`/Users/chuxiaoshan/project/indev/tile/tilemath/lib/ui/settings_page.dart:73-93`（`ListTile` 的 `trailing` 塞了整个 `SegmentedButton<UnitSystem>`）
- **触发**：我把三档宽度 × 三档 textScaler × en/ar 全跑了一遍，实测阈值表：

  | 宽度 | 1.0 | 1.35 | 1.6 |
  |---|---|---|---|
  | 375dp（SE2/SE3/13 mini） | 干净 | **炸（en 和 ar 都炸）** | 炸 |
  | 393dp（iPhone 15） | 干净 | 干净 | 炸 |
  | 430dp（16 Pro Max） | 干净 | 干净 | 炸 |

  iOS 标准（非辅助功能）字号滑块最大档约 1.35 —— **375dp 机型不开辅助功能就能撞上**。
- **异常内容**：先 `_RenderListTile` 抛 "Trailing widget consumes the entire tile width"，随后一串 `RenderBox was not laid out`，再 `sliver_multi_box_adaptor.dart:629` 的 `hasSize` 断言，最后是若干 `Null check operator used on a null value`（`RenderSliverEdgeInsetsPadding.performLayout`）。
- **改法**：别把 SegmentedButton 放进 `ListTile.trailing`。改成自绘一行：`Column(crossAxisAlignment: start)` → 标题 Text + `SizedBox(height: 8)` + 撑满宽度的 SegmentedButton。
- **坦白一点**：上面那串异常里，`Null check` 那几条是 debug 断言中断子布局后的下游连锁；Release 下 `list_tile.dart:1615` 会拿到负宽度的 `textConstraints`，"Units" 标题肯定没有可见宽度，但**是否会崩、还是只是渲染错乱，我没有在真机 Release 上验证**（见第 5 节）。这是四条必修里唯一有不确定性的，也是最容易修的。如果时间极紧，M1/M2/M3 是绝对不能带上线的，M4 可以在真机 Release 上先看一眼再决定。

---

## 3. 建议修（可发布后）

按我认为的优先级排：

| # | 问题 | 位置 | 一句话 |
|---|---|---|---|
| S1 | Clear all / 删单条后，再点 History 或退后台，被删的记录立刻复活并写回磁盘 | `home_page.dart:45` 与 `:103` 无条件记录 + `history/history_controller.dart:36` 去重只比 `_entries.first`，清空后列表为空直接 insert | 主打「历史无限免费」的功能，删了又回来是直接的信任损伤 |
| S2 | 从历史恢复一条旧记录后再打开 History，同一次计算被重复入库 | `history/history_controller.dart:36` | 「翻历史看看之前那单」这个最常见动作本身在污染历史。改成全表 `indexWhere` 命中即上移 |
| S3 | 恢复历史后 Boxes & cost 两个输入框不同步：屏上显示失效旧值，结果卡按恢复值算 | `home_page.dart:722-738`（`_BoxesAndCostState.initState` 只读一次，无 `didUpdateWidget`/listener） | 触发条件是「恢复时该区域处于展开态」。之后只改一个框，另一个框显示的数和实际参与计算的数持续背离 |
| S4 | 逗号小数分隔符地区（fr/de/pt-BR 等）在 Price per box 打 `30,5`，成本行静默消失 | `home_page.dart:807`（`double.tryParse` 直吃原始文本，字段无 inputFormatters） | 美区首发不受影响（en_US 分隔符是 `.`），但 App Store 是全球分发。解析前按 locale 归一化分隔符即可 |
| S5 | 退格清空后激活段仍停在 inch，重新输入的数字被当英寸（每维差 12 倍） | `keyboard/imperial_editor.dart:124-133`（对比 `clear()` 在 `:148-156` 会复位 `_active`，backspace 不会） | 字段显示空白、与新字段看不出区别，随后输 12 得到 12″ 而非 12′。backspace 末尾补一句复位即可 |
| S6 | 已录入的字段清不掉：按 C 再按 Done，旧值原样回来 | `state/calculator_controller.dart:267`（`if (value == null) return;` 把「没动过」和「用户显式清空」两种语义混为一谈） | 用户按 C 看到字段变空、按 Done 后值又回来。需要给编辑器加「被显式清空过」标记 |
| S7 | 英尺-英寸-分数值在区域行窄字段里换行成 2~3 行，字段高度随输入跳动 | `home_page.dart:473-477`（值 Text 无 `maxLines`/`softWrap:false`/FittedBox） | `12′ 11-7/8″` 的固有宽度 181.5dp，而字段可用宽只有 95~123dp。项目在 `_PatternSelector:668-674` 已经在用 FittedBox 降级，这里照抄即可。`:313` 的面积 Text 同理 |
| S8 | 公制区域字段回显固定按 m 取两位小数，用 cm 键输入 12.5 显示成 `0.13 m` | `ui/format.dart:64`（`_trailingDigits` 只返回 0 或 2）+ `home_page.dart:295`/`:306` 写死 `MetricUnit.m` | 内部存的 mm 值和计算都正确，只是回显丢精度（差约 4%），会让人以为输入没被接收 |
| S9 | 分数键「再按一次取消」不回滚它引发的 feet→inch 改判；段键高亮与数字实际所在段不一致 | `keyboard/imperial_editor.dart:119`、`:101-113` | 12′ 误触分数再取消变成 12″；`144` + `in` 后 in 键高亮但数字还在 feet 段。都是键盘状态机的边角 |
| S10 | 辅助功能字号（≈2.0）下键盘吃满屏，激活字段被完全遮住 | `home_page.dart:129-152` + `ui/keyboard/tile_keyboard.dart:186-196` | 只在 375×667 + 辅助功能档触发，标准字号档（≤1.6）正常。给键盘外层限高即可 |
| S11 | 英文 `1 tiles needed`（未做 ICU 复数） | `lib/l10n/app_en.arb:42` → `ui/result_card.dart:60-69` | 必须 Custom 铺法 + 损耗拖到 0% + 小区域才能触发。同屏的 wasteLine 已经做了复数，两行不一致更显眼 |
| S12 | 禁用态 ft 键与可用态视觉几乎无差别，点击无任何反馈 | `ui/keyboard/tile_keyboard.dart:299`（禁用只把 Material 底色 alpha 降到 0.4，文字色和边框不变，InkWell 水波纹也没了） | 在缝宽/瓷砖尺寸字段上按 ft 键像卡死。按 M3 规范把文字和边框也降到 0.38 |

---

## 4. 复核否掉的（这些地方其实是稳的）

**审查阶段报过、但经复核不成立或被明显夸大的：**

- **「退格到空也会触发 tilesPerBox=0 崩溃」** —— 不成立。`"12"` 连退两次得到空串，`int.tryParse('')` 返回 null，走的是合法的「未填」分支。只有文本里实际留下字符 `'0'` 才炸。
- **「粘贴负单价 / NaN / 1e400 是独立缺陷」** —— 代码同源属实，但 iOS 的 decimalPad 没有减号键也打不出字母，只能靠粘贴恰好这种字符串，现实中不会发生。已并入 M1 作为 `isFinite` 守卫的附带理由。
- **「0 值会每帧重复抛异常、不可恢复」** —— 夸大。ErrorWidget 就位后不再重建抛出，把 0 改回合法值一帧内自动恢复。故障是「持续到用户改回来」，不是永久损坏。
- **「阿语区是逗号分隔符的主要受害者」** —— 反了。intl 实测 `ar` 和 `ar_MA` 的分隔符就是 `.`，只有 `ar_EG` 是 `٫`；而且 `ui/format.dart:61-62` 对 ar 强制回落 en_US，自定义键盘那侧完全安全。真正受影响的是 fr/de 等欧陆地区。
- **「用户会用阿拉伯-印度数字键盘往 Tiles per box 打 ١٢」** —— 无法验证，已剔除（见第 5 节）。
- **「段改判会让面积差 144 倍」** —— 单个字段只错 12 倍，144 倍要长宽两个字段都踩中同一路径。
- **「feet→inch 改判是静默发生的」** —— 屏上文本确实从 `12′` 变成 `12″`，只是 ′/″ 区分度低。因此降级为 minor。
- **「缝宽完全无法清空是缺陷」** —— `grout` 在 `calculator_controller.dart:55` 是 `late Length` 非空字段，模型上就不存在空态（默认英制 1/16″、公制 2mm），清空到 null 会破坏 `result` 计算。这是设计，不是 bug。
- **「深色模式键帽底色反向」** —— 代码事实属实（dark 未定义 `surfaceContainerLowest`，getter 回退到更暗的 surface），但键帽有 1px `scheme.outline` 描边，边界清晰、可点击、文字对比度正常。纯视觉层级偏好，不是错误行为。
- **「历史列表按记录当时的单位制渲染，与当前 Units 冲突」** —— 现象属实，但 `HistoryEntry.unitSystem` 是有意持久化的字段，「按记录当时的单位展示」是可辩护的存档语义（等同小票）。设计取舍，不是错误。
- **「历史写盘不检查 setString 返回值 / 反序列化失败清空整个历史」** —— 代码属实，但给不出真实触发路径。`toJson`/`fromJson` 逐字段对称（已核对 `history_entry.dart:68-106`），app 内不存在能写出不可解析数据的路径；需要 OS 级存储损坏才能触发。健壮性加固建议，不是上架前缺陷。
- **「孤儿 l10n 键 areaLabel」** —— grep 确认无调用点属实，但零用户可见影响、不影响构建与审核。技术债，不是缺陷。
- **「Rate app 在受限设备上按钮完全没反应」** —— 见第 5 节，无法证实，不作为缺陷保留。

**主动核对过、确认没问题的：**

- `result` getter 对 `tileWidth/tileHeight` 的守卫完整（`calculator_controller.dart:100-106`），`_commit()` 也拒绝提交 0 尺寸（`:274-277`），瓷砖尺寸路径不可能触发 ArgumentError。
- `wasteRate` 由 `setCustomWaste` 的 `clamp(0, 30)` 约束（`:149`），UI 滑块 min:0/max:30 恰好落在 domain 层 0–0.30 合法域内，`tile_calculation.dart:89-90` 的守卫从 UI 走不到。
- 单位制判断**没有**被 locale 回退污染：`home_page.dart:67-72` 明确用 `platformDispatcher.locale` 原始设备 locale 判英制/公制，所以就算 M3 让语言错成 ar，fr_FR/es_US 设备的单位制仍按 countryCode 正确判定，不会叠加成「阿语 + 单位错」的双重错误。这个地方写得很谨慎。
- `restoreFrom`（`calculator_controller.dart:201-225`）对所有字段的写入是完整的，区域行/瓷砖尺寸的 `_ValueField` 是每次 build 读 `widget.value` 的无状态渲染，恢复后显示正确。不同步的只有 `_BoxesAndCost` 里两个持 TextEditingController 的系统输入框（S3）。
- 竖屏单栏主路径干净：`TileKeyboard` 只在 `calc.editing != null` 时插入（`home_page.dart:150`），激活字段位于键盘上方，无溢出、无异常。iPhone 竖屏最大宽度 440dp < 600，不会误入双栏。
- `_ceilGuarded`（`tile_calculation.dart:83`）的浮点护栏 `(value - 1e-9).ceil()` 处理正确，120.000000000001 不会进位成 121。
- `pricePerBox = 0` 是合法输入（`tile_calculation.dart:97` 只拒负数），不会抛错。
- **隐私申报属实**：`pubspec.yaml` 的运行时依赖只有 `in_app_review` / `intl` / `package_info_plus` / `provider` / `shared_preferences` / `url_launcher`，**没有 AdMob、没有 http/dio、没有 firebase、没有任何 analytics**。全 lib grep 网络相关只命中一处常量 `settings_page.dart:17` 的隐私政策 URL（用户主动点击后由 Safari 打开，不属于 app 发起的网络请求，也不收集数据）。「完全离线、无广告、无网络请求、不收集数据」的申报在代码层站得住。
- 隐私政策在 app 内可访问（`settings_page.dart:17` 有注释明确对应审核指南 5.1.1(i)），`_openExternal` 打开失败还给了 SnackBar 反馈，不是静默失败。

---

## 5. 仍不确定的（需要真机 / 更多信息）

1. **M4 在 Release 构建下的真实表现**。debug 下的断言链是确凿的，但 Release 跳过断言后，`list_tile.dart:1615` 拿到负宽度 `textConstraints` 究竟是崩溃、还是标题塌成 0 宽的渲染错乱，我无法在 `flutter test` 里验证（flutter test 只有 debug 模式）。**建议：真机 SE 或模拟器 375pt 机型，设置里把文字调到最大标准档，跑一个 Release/Profile 包进设置页看一眼。** 这直接决定 M4 是必修还是可以推到 1.0.1。
2. **iOS 系统数字键盘在阿拉伯-印度数字地区是否会输出 U+0660–U+0669**。若会，`Tiles per box` 的 `int.tryParse` 会返回 null（箱数行静默消失）。`int.tryParse('١٢') == null` 属实，但键盘行为我没有设备实测依据，不作为缺陷论断。
3. **禁用态 ft 键的实际像素对比度**（S12）。我是按 alpha 手算合成的（浅色 ≈ 差 8/255，深色 ≈ 差 8/255），没做真机截图比对。结论方向应该没错，但具体数值仅供参考。
4. **Rate app 在 App Store 被屏幕使用时间/MDM 限制时的行为**。我读了 `in_app_review-2.0.12` 的 `InAppReviewPlugin.swift:65-87`，`openStoreListing` 在 `UIApplication.shared.open` 后无条件 `result(nil)`，忽略打开结果，所以 `settings_page.dart:44-46` 的 catch 在正常 iOS 构建里基本不会命中。但插件打开的是 `https://apps.apple.com/...` 而非 `itms-apps://` scheme，被限制时**通常会回落到 Safari 打开网页版商店页**，未必「毫无反应」。我没有受限设备可测，不作为缺陷保留。
5. **横屏刘海侧安全区**（`MediaQuery.padding.left/right` 无人消费）。我没有用 `FakeViewPadding` 验证，不做断言；而且若按 M2 建议锁竖屏，这个场景根本不存在。
6. **App Store Connect 里实际填写的隐私申报内容**我没看到，只能确认代码侧无数据收集。提交前请自行比对申报项与 `in_app_review` / `package_info_plus` 的行为（两者都不上报数据，正常勾选 "Data Not Collected" 即可）。

---

## 附：验证方式与项目状态

- 所有复现测试写在 scratchpad 目录（`/private/tmp/claude-501/.../scratchpad/`），从项目根用 `fvm flutter test <绝对路径>` 实际跑过并读取了打印值，**未在 `/Users/chuxiaoshan/project/indev/tile/tilemath` 内创建或修改任何文件**。
- `git status` 中列出的改动（`lib/l10n/*`、`assets/fonts/*`、`lib/ui/home_page.dart`、`lib/ui/settings_page.dart`、`pubspec.yaml`、`test/ui/home_flow_test.dart`、未跟踪的 `test/l10n/`）在本次复核开始前就已存在，与本次复核无关。
- 修完 M1~M3（M4 视真机结果）之后，建议至少补三条回归测试：667×375 横屏无 overflow、`enterText('0')` 到 Tiles per box 不抛异常、设备 locale=fr_FR 时解析出 `en`。