# TileMath

瓷砖用量计算器（Flutter），差异化是英尺-英寸-分数自定义键盘。完全离线，AdMob 变现。

- 目标平台：Android / iOS（含平板 600dp 双栏）
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
- 广告位当前全部为 Google 官方测试 ID（`lib/ads/ad_ids.dart`），上架前替换
- AdMob 政策硬约束：banner 与键盘/可交互元素之间保持 16dp+ 非交互隔离带（`home_page.dart`）
