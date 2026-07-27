# TileMath

瓷砖用量计算器（Flutter），差异化是英尺-英寸-分数自定义键盘。完全离线、无广告、无网络权限。

- 目标平台：Android / iOS。iOS 首发仅 iPhone（`TARGETED_DEVICE_FAMILY = 1`）；≥600dp 双栏布局保留，服务于 Android 平板与 iPhone 横屏
- 语言：en / zh / ar（RTL），其余语言编码阶段扩展
- applicationId / bundleId：`com.tilemath.calculator`

## 开发

工程用 **fvm** 固定 Flutter 版本（见 `.fvmrc`），所有命令用 `fvm flutter ...`：

```bash
fvm flutter pub get
fvm flutter test          # 全量测试
fvm flutter analyze       # 零告警基线
fvm flutter run
```

## 约定

- 长度值一律以 mm 基准的 `Length`（`lib/domain/length.dart`）落地，单位制只影响键盘与显示
- 设计 token 来源：`../material/design-tokens.md`（Claude Design v0.9），主题层在 `lib/theme/`
- **改动 `lib/l10n/app_zh.arb` 后必须重跑 `tool/fonts/subset_noto_sc.sh`**（Noto Sans SC 是按用字子集化的，17MB→97KB）
- **首发不带广告**：`google_mobile_ads` 已从依赖中移除，SDK 不进二进制，因此 App Store 的 IDFA 声明可干净答"否"。广告实现（AdMob + UMP + 插屏频控）保留在提交 `8a2cbf3` 中，后续版本要恢复从那里取
- 底部安全区由各滚动容器/键盘自行让出（`MediaQuery.paddingOf(context).bottom`）：键盘在场时由键盘负责，避免与列表 padding 双算
