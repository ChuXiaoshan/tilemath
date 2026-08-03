# docs/ — 产品与设计资料索引

给后续 AI 会话（或任何新加入者）的完整上下文。代码之外的所有决策依据都在这里。

## design/ — 设计

| 文件 | 内容 |
|---|---|
| `style-round-1.dc.html` | **设计稿本体**（Claude Design 导出）：全部屏幕样张——主计算页、分数/公制键盘、结果卡三态、History、Settings、深色、iPad 双栏、阿拉伯语 RTL、图标 8a 三外观。浏览器直接打开可看；AI 读内嵌 SVG/HTML 即可提取任何屏幕的精确布局与颜色 |
| `design-brief-v2.1.md` | 给设计的完整 brief（交互规格、RTL 硬规则、AdMob 约束），是设计稿的"需求侧" |
| `design-tokens.md` | 色彩/字号/间距 token 表 → 对应 `lib/theme/` 实现 |
| `icon-brief-multi-appearance.md` | 图标三外观（light/dark/tinted）设计要求；定稿为 8a，源图生成脚本在 `tool/icon/make_app_icons.py` |
| `support.js`、`_ds/` | 样张 HTML 的运行时依赖，仅为离线打开服务，不用读 |

## research/ — 调研

| 文件 | 内容 |
|---|---|
| `tile-calculator-research-2026-07.md` | 竞品调研 + 变现评估（2026-07）：分数键盘差异化的验证依据、AdMob 政策约束、定价结论 |

## release/ — 发布

| 文件 | 内容 |
|---|---|
| `pre-release-audit-2026-07-27.md` | 上架前 13 路评估报告：4 个必修 + 建议修清单（全部已修，各有回归测试） |
| `ios-launch-gap-2026-07-27.md` | iOS 上架环境要求（Xcode 26 强制线、证书、ASC 流程坑） |
| `app-store-listing-draft.md` | 商店文案草稿（名称/副标题/描述/关键词） |
| `privacy-policy-draft.md` | 隐私政策草稿 → 已发布于 https://xs-albus.github.io/privacy.html |

## 外部资源

- Claude Design 项目（设计稿源头，可继续迭代）：https://claude.ai/design/p/5f146642-4e8b-4697-9a3d-4a2d8850b728
- 官网/隐私页仓库：`XS-Albus/XS-Albus.github.io`
- App Store Connect：App ID `6795019764`，Bundle ID `com.tilemath.calculator`
- 当前状态（2026-08-03）：1.0.0 (6) 已提交 App Review 排队中；TestFlight 外部群组已建
