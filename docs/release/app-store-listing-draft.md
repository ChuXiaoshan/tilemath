# App Store 商店文案草稿（美区 / 英语）

App ID `6795019764` · 名称已锁定 `TileMath - Tile Calculator`

> 用法：直接复制到 App Store Connect 对应字段。所有字符数已核对。

---

## 副标题 Subtitle（上限 30 字符）

```
Feet-inch fractions made easy
```
`29 字符`

备选：
- `Fractions, waste, boxes—done` (28)
- `Tile estimates in ft & inches` (29)

---

## 推广文本 Promotional Text（上限 170 字符）

```
Type 12' 3-1/2" the way you'd say it—no decimal conversions. Get tile counts, boxes, and cost in one screen. Works fully offline, no account, no ads.
```
`148 字符`

> 这个字段**改动不需要重新过审**，适合以后放更新公告或促销信息。

---

## 关键词 Keywords（上限 100 字节，逗号分隔、逗号后不留空格）

```
flooring,grout,footage,estimator,herringbone,backsplash,contractor,tiler,remodel,layout
```
`86 字节`

**规则说明：** 名称和副标题里的词（tile / calculator / math / feet / inch / fraction）已被单独索引，**不要在关键词里重复**，那是浪费字节。上面这份刻意只放名称里没有的词。

还有 14 字节余量，可按需追加 `,sqft`（+5）或 `,wastage`（+8）。

---

## 描述 Description（上限 4000 字符）

```
Stop converting feet and inches into decimals just to figure out how many tiles you need.

TileMath is a tile calculator built around the way measurements are actually written on a job site. Type 12' 3-1/2" directly with a purpose-built fraction keypad—no mental math, no decimal conversions, no mistakes.

WHAT IT DOES

• Tile count for any room — enter length and width, get the exact number of tiles
• Multiple areas — add as many rooms or sections as the job needs
• Boxes to buy — enter tiles per box and get whole-box quantities, rounded up
• Cost estimate — set a price per tile or per box and see the total
• Grout lines included — spacing is part of the math, not an afterthought
• Waste allowance — 10% for straight lay, 15% for diagonal, 20% for herringbone, or set your own

THE FRACTION KEYPAD

Most calculators make you type 12.29 when the tape measure says 12' 3-1/2". TileMath doesn't. The keypad has feet, inches, and sixteenths right on it. Tap the fraction you see. Everything is displayed the same way you measured it.

Prefer metric? Switch to meters, centimeters, and millimeters in Settings. The keypad changes with it.

BUILT TO STAY OUT OF YOUR WAY

• Fully offline — no internet connection required, ever
• No ads
• No account, no sign-up, no email
• No data collection of any kind
• History — past calculations are saved on your device so you can pull up a job you did last week

FOR

DIY renovators tiling a bathroom or kitchen. Tile setters and flooring contractors pricing a job. Anyone who has ever bought two boxes too few and had to drive back to the store.

Measurements are shown in feet, inches and sixteenths, or in metric. Available in English, Chinese and Arabic.
```
`约 1750 字符`

---

## 需要你决定 / 补充的字段

| 字段 | 建议 | 说明 |
|---|---|---|
| 类别 Primary Category | **Utilities** | 次类别可留空，或选 Productivity |
| 价格 | **免费** | |
| 版权 Copyright | `2026 Xiaoshan Chu` | 换成你想公开的署名 |
| Support URL | 待定 | **必填且必须真实可达**，GitHub Pages 即可 |
| 隐私政策 URL | 待定 | 见 `privacy-policy-draft.md` |
| App Review 联系方式 | 姓名/邮箱/电话 | 必填，仅 Apple 内部可见 |
| 年龄分级 | 走问卷 | 无 UGC、无社交、无广告 → 预期 4+ |
| EU Trader Status | 见下 | |

**EU Trader 提醒：** 若在欧盟上架必须填报，且会**公开你的姓名、地址、电话、邮箱**在欧盟区商品页。个人开发者若不想公开住址，可在「价格与销售范围」里先排除欧盟，等以后有公司主体再开。

---

## 截屏

ASC 目前显示的槽位是 **iPhone 6.5 英寸**。之前调研说 6.9 英寸是必填档——以实际界面为准，点「在"媒体管理"中查看所有尺寸」确认到底哪一档必需。

规格硬要求：PNG/JPEG、RGB、**不得含 alpha 通道**、尺寸必须精确匹配无容差、每档 1–10 张。

**内容建议（前 3 张会出现在搜索结果里，最关键）：**
1. **分数键盘正在输入 12' 3-1/2"** —— 唯一的硬差异化，必须放第一张
2. 结果卡：片数 + 箱数 + 成本一屏出数
3. 多区域房间列表
4. 铺贴方式选择（直铺/斜铺/人字铺）与损耗率
5. History 历史记录

等 Xcode 和模拟器装好，我可以用脚本批量出精确尺寸的截图。
