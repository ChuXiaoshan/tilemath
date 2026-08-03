# TileMath 项目指令

美国市场瓷砖计算器（Flutter，iOS 首发）。产品/设计/调研/发布全部背景资料见 **`docs/README.md`**，动手前先读它。

## 硬规则

- **一律 `fvm flutter ...`**（固定 3.44.8），禁止动全局 Flutter
- 改任何 `lib/l10n/*.arb` 后必须 `fvm flutter gen-l10n`（`flutter test` 不会自动重新生成）；改 `app_zh.arb` 还要重跑 `tool/fonts/subset_noto_sc.sh`
- 跑完 `fvm dart run flutter_launcher_icons` 必须 `git diff` 检查 `ios/Runner.xcodeproj/project.pbxproj`——0.14.4 的正则会把 `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` 误改成 `AppIcon`
- 图标/启动屏是脚本生成物：改 `tool/icon/make_app_icons.py`、`tool/launch/make_launch_image.py` 后重跑，不要手改 PNG
- v1.0 无广告（SDK 已从二进制移除，为的是 IDFA 声明干净）；广告完整实现在提交 `8a2cbf3`，恢复从那取

## 验证

提交前：`fvm flutter analyze` + `fvm flutter test` 全绿。UI/布局类修改要写量尺寸、计次数的断言，存在性断言（findsOneWidget）抓不住布局缺陷。
