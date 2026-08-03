# TileMath 上架 App Store 差距清单（2026-07-27）

关键结论先说：现在离"能提交"最远的不是代码，是 **工具链（Xcode 16.3 → 必须 Xcode 26）** 和 **账号/证书**。这两条我都做不了，只能你本人操作，且 Xcode 26 大概率连带要升 macOS（本机 15.2）。

---

## 一、阻塞级（不解决就根本传不上去）

按先后顺序：

### 1. 工具链不达标：必须用 Xcode 26 / iOS 26 SDK 构建 —— 【用户操作，最先做】
- **现状（已实测）**：`xcodebuild -version` → Xcode 16.3 (16E140)；`xcodebuild -showsdks` → 只有 iOS 18.4 SDK；`sw_vers` → macOS 15.2 (24C101)。
- **要求**：Apple 自 2026-04-28 起强制上传的 app 必须用 Xcode 26+ / iOS 26 SDK 构建（来源 developer.apple.com/news/upcoming-requirements/，状态已是 "Since April 28, 2026"）。这只约束编译 SDK，不影响 deployment target 保持 13.0。
- **怎么做**：先升 macOS（Xcode 26 要求 macOS Sequoia 15.6+，具体最低版号请以 App Store 里 Xcode 页面的要求为准），再从 Mac App Store 或 developer.apple.com/download 装 Xcode 26。下载体积大，预留半天。
- **连带影响（我能帮你处理）**：iOS 26 SDK 编译后原生控件默认套 Liquid Glass 外观。Flutter app 的 UI 自绘，主要影响的是 UIKit 弹层（ATT 弹窗、UMP webview、系统键盘/分享面板）。升级后需要真机/模拟器过一遍。

### 2. 没有 Apple Distribution 证书，也没有 App Store profile —— 【用户操作】
- **现状（已实测）**：`security find-identity -v -p codesigning` 只有 2 张 **Apple Development** 证书（xiaoshan1215@gmail.com / linlin cui），零张 Distribution。本机仅有的 2 个 provisioning profile 都是 development（`get-task-allow=true` + 设备列表），且属于公司 team K7X9DK93KR、App ID 是 `cn.qmai.console.*`，跟 TileMath 完全对不上。
- **怎么做**：登录 developer.apple.com/account（需付费 Developer Program 会员且你在该 team 是 Account Holder/Admin）→ 注册 Explicit App ID `com.tilemath.calculator` → 然后在 Xcode > Settings > Accounts 登录账号，Runner target 勾 "Automatically manage signing"，Xcode 会自动创建 Apple Distribution 证书 + App Store profile。这一步涉及账号登录，我不能代做。

### 3. DEVELOPMENT_TEAM 写的是公司 team，不是你自己的 —— 【我能改，但要你先告诉我 Team ID】
- **现状（已实测）**：`ios/Runner.xcodeproj/project.pbxproj:379 / :559 / :582` 三处均为 `DEVELOPMENT_TEAM = K7X9DK93KR`，而本机该 team 的 profile 名是 `cn.qmai.console.20210830.QMAIHelpeiPad` —— 这是青麦（qmai）公司团队。用公司 team 发个人项目会有归属和账号权限问题。
- **怎么做**：你在 developer.apple.com/account → Membership 查到自己个人账号的 Team ID，告诉我，我把 pbxproj 三处（Debug/Release/Profile）改掉。或者直接在 Xcode Signing & Capabilities 里选 team，Xcode 会自己写回。

### 4. AdMob 全部是 Google 官方测试 ID —— 【混合：你去后台申请，我来改代码】
- **现状（已实测）**：`lib/ads/ad_ids.dart:13-25` 三组 ID 全是 `ca-app-pub-3940256099942544` 系列（Google 公开 demo publisher）；`ios/Runner/Info.plist` 的 `GADApplicationIdentifier` 同样是 `ca-app-pub-3940256099942544~1458002511`；`android/app/src/main/AndroidManifest.xml:36` 同理。
- **后果**：Apple 审核不校验 AdMob ID，用测试 ID **能过审**，但展示/点击不产生任何收入、AdMob 后台看不到数据 —— 等于白发一版。
- **怎么做**：
  - 你：AdMob 后台 → Apps → Add app → 选 iOS → 选 "Yes, it's listed on a supported app store" 关联 App Store 条目 → 拿到 App ID → 创建 Banner 和 Interstitial 两个正式广告单元。
  - 我：替换 iOS 三处（`Info.plist` 的 `GADApplicationIdentifier`、`ad_ids.dart:20` banner、`ad_ids.dart:25` interstitial）+ Android 三处。建议同时改成 `--dart-define` 注入或 debug/release 分支，避免下次误发测试 ID。
  - 顺带：`AdIds.appId` 是死代码（grep 确认 `lib/`、`test/` 无任何调用方），要么删掉 `ad_ids.dart:12-15`，要么保留但必须同步更新。

### 5. app-ads.txt —— AdMob 新 app 强制验证 【用户操作 + 我可生成文件内容】
- Google 明确：2025 年 1 月起新建的 AdMob app 必须用 app-ads.txt 验证，未验证前 **广告只能 limited serving**。做法：把 app-ads.txt 放在你自己域名根目录（如 `https://你的域名/app-ads.txt`），并且这个域名必须填进 App Store 商店页的 Marketing/Support URL，AdMob 才能确认归属。
- 你需要有一个自己的域名 + 静态托管（GitHub Pages 就够）。文件内容 AdMob 后台会直接给你复制。

### 6. 隐私政策：ASC 字段 + app 内入口，两处都必填 —— 【混合】
- **现状（已实测）**：`lib/ui/settings_page.dart:105-110` 隐私政策 ListTile 的 `onTap: () {}` 是**空函数体**；无 `url_launcher` 依赖（pubspec.yaml 依赖只有 google_mobile_ads / intl / provider / shared_preferences）。
- **要求**：审核指南 5.1.1(i) 要求隐私政策既要在 App Store Connect 元数据里填链接，**也要在 app 内可方便访问**（只填 ASC 字段被拒是高频原因）。内容必须写明：收集哪些数据/如何收集/全部用途、点名第三方（明确写 Google AdMob）、数据保留删除策略、用户如何撤回同意。
- **怎么做**：我可以起草一份覆盖 AdMob/IDFA 的隐私政策正文 + 加 `url_launcher` 依赖 + 把 `settings_page.dart:109` 的空 onTap 换成 `launchUrl`。托管到你自己的域名和填进 ASC 需要你做。

---

## 二、提交前必须（能传上去，但会被拒或卡流程）

### 7. ATT：声明了用途字符串却从不请求 —— 这是 5.1.2 的典型拒绝点 【我能改】
- **现状（已实测）**：`Info.plist` 有 `NSUserTrackingUsageDescription`（"This identifier will be used to deliver personalized ads to you."），但全仓 grep `app_tracking_transparency` / `requestTrackingAuthorization` / `ATTrackingManager` 零命中，唯一提及是 `lib/ads/consent_manager.dart:11-13` 的 TODO 注释。
- **二选一，必须选一个**：
  - **(A) 做个性化广告**：加 `app_tracking_transparency` 依赖，在 `lib/ads/ads_service.dart` 第 45 行 `gatherConsent()` 返回之后、第 48 行 `MobileAds.instance.initialize()` 之前插 iOS-only 的 ATT 请求（要处理 notDetermined 需等 app 进 active 态）。同时 AdMob 后台要创建并发布 IDFA message（UMP 会在 ATT 系统弹窗前先展示它，这是 Google 官方推荐顺序）。ASC 问卷答"用于追踪"。
  - **(B) 不做追踪**：删掉 `Info.plist` 的 `NSUserTrackingUsageDescription`，ASC 问卷答"不追踪"。代价：IDFA 全零，只能投非个性化广告，eCPM 明显低。
- 注意：不请求 ATT **本身不违规**（违规的是"做了 tracking 却没弹"）。但当前"声明了 + 不弹"这个状态最糟糕 —— 审核会问。
- 还有一条硬雷：ASC 提交时有独立的 "Advertising Identifier (IDFA)" 声明题，**答错（app 里有 IDFA 却答 No）会导致二进制被永久拒绝、必须重传新包**。

### 8. UMP 隐私选项没有重入口 【我能改】
- `lib/ads/consent_manager.dart` 全文 61 行只有 `gatherConsent()`（:23）和 `canRequestAds()`（:53），没有 privacy options form 的调用；Settings 页也没这一行。GDPR/IAB TCF 地区的 UMP 消息通常要求提供"重新打开同意表单/撤回同意"的入口。
- 我可以加：ConsentManager 增加查询 privacy options requirement status + 展示表单的方法，Settings 在隐私政策附近加一行（仅在 required 时显示）。

### 9. ITSAppUsesNonExemptEncryption 缺失 【我能改，1 分钟】
- 实测 `plutil -p ios/Runner/Info.plist` 无此 key。加 `<key>ITSAppUsesNonExemptEncryption</key><false/>`。本 app 只走系统 HTTPS/TLS，属豁免。不加不会阻止上传，但每个构建版都会卡在 "Missing Compliance"，TestFlight 外测和提审都要先手动答一次。

### 10. iPad：要么适配要么砍掉 【我能改配置，UI 适配要一起看】
- **现状（已实测）**：`TARGETED_DEVICE_FAMILY = "1,2"`（pbxproj:367/:494/:547），即声明为 iPhone+iPad 通用 app。
- **后果**：App Store Connect 会**强制要求 13 英寸 iPad 截图**（2064×2752 或 2048×2732），审核也会在 iPad 上实测 UI。
- **建议**：首发如果没做 iPad 适配，直接改成 `"1"` 只做 iPhone，省掉整套 iPad 截图和 iPad UI 审查风险。这是我能改的一行。

### 11. 截图规格 —— 【你出图，我可以帮你搭截图脚本】
- iPhone **6.9 英寸档必填**：1320×2868（推荐）/ 1290×2796 / 1260×2736。若不提供 6.9"，则 6.5"（1284×2778 或 1242×2688）变必填。
- 每档 1–10 张，PNG/JPEG，RGB，**不得含 alpha 通道**，尺寸必须精确匹配无容差。
- 若保留 iPad，追加 13 英寸档 2064×2752。

### 12. CFBundleLocalizations 缺失 【我能改】
- **现状（已实测）**：`Info.plist` 无此 key；`project.pbxproj:198-201` 的 `knownRegions = (en, Base)`；但 `lib/l10n/app_localizations.dart:97-100` 声明支持 ar/en/zh（三语各 61 键，翻译完整）。
- **后果**：App Store 商品页"语言"栏只显示 English，影响中文/阿语市场的搜索曝光；iOS 设置里不会出现该 app 的"首选语言"选项。
- **改法**：`Info.plist` 加 `<key>CFBundleLocalizations</key><array><string>en</string><string>zh-Hans</string><string>ar</string></array>`。

### 13. 版本号硬编码 【我能改】
- `lib/ui/settings_page.dart:121` 的版本号写死 `'0.1.0'`（有 TODO 注释）。现在跟 `pubspec.yaml:4` 的 `0.1.0+1` 恰好一致，改版本号后必然失配。加 `package_info_plus` 读真实值。
- 另建议 `pubspec.yaml:4` 改成 `version: 1.0.0+1` —— Apple 接受 0.x，但用户看到 0.1.0 会当测试版。

### 14. App Store Connect 网页端必填项 —— 【全部用户操作，我一条都做不了】
按 ASC 页面顺序：
- **App Information**：App Name（2–30 字符）、Bundle ID（从 Identifiers 下拉选）、SKU（建后不可改）、Primary Language、Primary Category（建议 Utilities）、Content Rights 声明。**不要勾 Made for Kids**（带广告，且过审后不可改）。
- **年龄分级问卷**：新体系 4+/9+/13+/16+/18+。TileMath 无 UGC 无社交，社交类全答否；含广告那一项如实答。
- **App Privacy 隐私营养标签**：这是硬前置。你要为 AdMob 采集的数据负责，按 Google 官方 data-disclosure 页申报：Identifiers（设备 ID / 广告标识符）、Usage Data（Advertising Data、Product Interaction）、Diagnostics（崩溃/性能）、粗略位置（IP 推断），用途勾 Third-Party Advertising + Analytics。**漏披露是首次提交被拒的高频原因。**
- **版本信息**：Description（4000 字符）、Keywords（100 bytes）、Support URL（必须真实可达、带 http(s):// 协议头）、Copyright（如 "2026 你的名字"）、App Review Information（联系人姓名/邮箱/电话必填）。
- **Agreements**：确认 Apple Developer Program License Agreement 状态是 Active。若显示 "Active (New Agreement Available)" 必须重新接受，否则不能提交。
- **EU Trader Status**：若在欧盟上架必填，且会**公开你的姓名/地址/电话/邮箱**在欧盟区商品页。AdMob 广告收入大概率会被判为 trader。个人开发者若介意隐私，首发在 Availability 里排除欧盟即可规避。

### 15. 归档前先 clean 【我能做】
- `ios/Flutter/Generated.xcconfig` 里 `FLUTTER_APPLICATION_PATH` 还指向已废弃的 `/Users/chuxiaoshan/project/indev/tile/app`（该目录只剩 build/ 和 lib/ 空壳）。这文件被 gitignore 且每次构建重新生成，但说明当前构建缓存是脏的。
- 建议运行：`cd /Users/chuxiaoshan/project/indev/tile/tilemath && fvm flutter clean && fvm flutter pub get`

---

## 三、可后补（不影响上架，但影响观感/收入/维护）

按性价比排序：

### 16. SKAdNetwork ID 清单已过期，缺 15 个 —— 直接影响 eCPM 【我能改】
- 现有 38 条（`Info.plist:33-187`），对比 Google 官方最新清单缺 15 个：`3qcr597p9d, 3rd42ekr43, 44jx6755aq, 4dzt52r2t5, 578prtvx9j, 8c4e2ghe7u, 97r2b46745, c3frkrj4fj, e5fvkxwrpn, f38h382jlk, k674qkevps, kbmxgpxpgc, t38b2kh725, tl55sbb4fm, wg4vff78zm`；另有 3 个已从官方清单移除：`ecpz2srf59, eh6m2bh4zr, pwa73g5rt2`。
- 不影响过审，但缩小可归因的广告买方范围，**直接压 eCPM**。这是所有"可后补"里唯一直接影响钱的，建议一起做。注意提交当天重新对一遍官方清单，这是动态列表。

### 17. 启动屏是纯白空屏 【我能改】
- `LaunchScreen.storyboard:19-26` 是 Flutter 模板原样，`LaunchImage.png/@2x/@3x` 三张实测都是 **1×1 像素**（各 68 字节）。`:22` 背景色硬编码纯白，深色模式下会闪白屏。
- 换品牌图 + 改用 Assets 里的 named color 支持深浅两套。不是拒绝项，但首启观感很差。

### 18. Rate this app 是空实现 【我能改】
- `settings_page.dart:112-116` 的 `onTap: () {}`。接 `in_app_review`，或先隐藏这一行 —— 上架后用户点了没反应比没有这个入口更糟。

### 19. 10 处 debugPrint 会进 release 包 【我能改】
- `lib/ads/` 下：`interstitial_manager.dart:57,69,106,112`、`anchored_banner.dart:121,131`、`consent_manager.dart:35,47,57`、`ads_service.dart:51`。Dart 的 debugPrint 不像 assert 那样在 release 被剥离，内容含中文调试串和 AdMob 错误码，会写进用户设备日志。包一层 `if (kDebugMode)` 即可。

### 20. app 级 PrivacyInfo.xcprivacy 【我能建，但先别急】
- 实测 `find ios -name "*.xcprivacy"` 零命中。三方 SDK 都自带清单（shared_preferences_foundation 2.5.6、webview_flutter_wkwebview 3.26.0 已本地确认；GoogleMobileAds 由 Google 随 xcframework 分发）。Runner 自身 Swift 代码只有 AppDelegate.swift 16 行 + SceneDelegate.swift 6 行，不调 required-reason API。
- **建议策略**：先不加，传一个 build 到 TestFlight，看 Apple 有没有发 ITMS-91053 邮件。收到再补，比现在瞎填 `NSPrivacyTrackingDomains` 安全（填错域名会导致用户拒绝 ATT 后广告请求被系统直接阻断）。

### 21. 工程杂项 【我能改】
- `pubspec.yaml:15` 的 `intl: any` 未约束版本，锁在 0.20.2，建议改显式范围。
- 无 ExportOptions.plist / fastlane / CI。手动提交不受影响；要自动化我可以建 `ios/ExportOptions.plist`（method=app-store-connect + teamID + signingStyle=automatic）。
- 工程级 `CODE_SIGN_IDENTITY[sdk=iphoneos*] = "iPhone Developer"`（pbxproj:349/:470/:527）是 Flutter 模板旧值，自动签名归档时通常会被覆盖。证书到位后若报签名错误，删掉这三行让自动签名接管。
- 横屏已声明（iPhone 三向 / iPad 四向），审核会在横屏实测，需确认分数键盘和 banner 位不破版。
- **已通过、无需动**：App 图标 21 个 png 齐全，1024 图实测 RGB 无 alpha（`hasAlpha: no`）；Bundle ID 三配置一致 `com.tilemath.calculator`；SPM 依赖锁在已提交的 Package.resolved；三语 l10n 61 键完整；无测试设备 ID / kDebugMode 分支残留。

---

## 四、时间敏感（今天就该做的）

1. **【最优先，今天】去 App Store Connect 抢注 "TileMath" 这个名字。** 名称在**创建 app 记录那一刻**就被独占，不需要提交审核、不需要 app 做完。路径：先在 developer.apple.com 注册 Explicit App ID `com.tilemath.calculator` → App Store Connect → Apps → + → New App → 填 Name=TileMath / iOS / Primary Language / Bundle ID 下拉选 / SKU → Create。**当天可完成，10 分钟。** 提交审核前 App Name 可随意改，所以先占了不吃亏。

2. **【今天启动，因为耗时长】开始下载 macOS 升级 + Xcode 26。** 这是唯一一条纯等待时间的阻塞，早点挂上。

3. **【本周】创建 app 记录后尽快上传一个 build 到 TestFlight。** Apple 现行文档**没有**写"多久不传 build 就释放名称"，但保留清理占名记录的权利。让记录变成"有活动"状态是目前最稳的保名手段。

4. **【提交前当天】重新抓一次 Google 官方 SKAdNetwork ID 清单比对。** 动态列表，本次核对就发现 15 缺 3 多。

5. **不要主动 Remove 掉 app 记录** —— Apple 明文："If you remove an app, you'll lose ownership of the app name."，被他人占走无法恢复。

**流程耗时预期**（第三方 Runway 实测数据，非 Apple 官方口径）：Beta App Review 排队约 13 小时 + 审核 1.3 小时；正式 App Review 排队约 9 小时 + 审核 1.4 小时。但全新 app 首次提交普遍慢于更新，按 24–48 小时预期、3 天缓冲规划。TestFlight **内测**（≤100 人，团队成员）不需要 Beta Review，build 处理完即可分发 —— 想快速验证走内测。

---

## 五、不确定 / 需你核实（我不编）

1. **Xcode 26 的确切 macOS 最低要求**。研究结论说 macOS Sequoia 15.6+，但我没从 Apple 一手页面逐字确认。本机 15.2，无论如何要升。请在 Mac App Store 的 Xcode 页面看实际要求。

2. **Paid Applications Agreement 是否需要签**。结论是"免费 app + AdMob 不需要签、不需要给 Apple 银行账户和税表"，但这是从协议适用范围条款**推导**的，Apple 没有任何页面直接写这句话。验证方式：ASC → Business → Agreements，只要 ADP License Agreement 显示 Active 就能提交免费 app。（AdMob 那边的税务和收款是完全独立的另一套，仍要填。）

3. **`ITSAppUsesNonExemptEncryption` 填 false 的官方依据**。"仅用 HTTPS/系统加密可填 false"是业界长期共识、方向与 Apple 帮助页一致，但研究阶段两次抓取 Apple 的《Complying with Encryption Export Regulations》原文都拿到空正文，没取到逐字佐证。提交时在 ASC 加密问卷里按实际再确认一次。

4. **app 级 PrivacyInfo.xcprivacy 对纯 Flutter + AdMob 是否"严格必须"**。Apple 文档没有针对"自身代码不调 required-reason API、全靠插件清单"这个场景表态。我倾向于不必须，但只能等 TestFlight 上传后看 Apple 的自动化邮件才确定。

5. **app 级清单里 NSPrivacyTracking 填 true 还是 false 存在真实争议**。风险实打实：列进 `NSPrivacyTrackingDomains` 的域名，在用户拒绝 ATT 后会被系统**直接阻断网络请求**。Google 支持组的公开回复回避了"发布者是否要把 Google 广告域名加进自己的 app 级清单"这个问题。真机验证 ATT 拒绝场景下广告是否仍返回，再决定。

6. **CFBundleLocalizations 缺失对 Flutter 运行时 locale 解析的实际影响**。我倾向于不影响（iOS embedder 读 `NSLocale.preferredLanguages`），但没读 Flutter 3.44.8 引擎源码验证。若实际是与 bundle localizations 求交集，中文/阿语设备会被强制拿到 en，`settings_page.dart:29` 的 deviceLocale 区域判断也会受影响。**需要真机把系统语言切到简中/阿语实测一次**，这个我做不了（本机无 iOS 真机，也无模拟器 runtime —— `xcrun simctl list runtimes` 输出为空）。

7. **`fvm flutter build ipa` 具体会先卡在哪一步**没实际验证（按要求未跑构建）。根因确定（无 distribution 证书 + 无 App Store profile + team/bundle 不匹配），但具体是 archive 阶段报 "No profiles for 'com.tilemath.calculator' were found"，还是 archive 侥幸过了在 exportArchive 阶段报 "No signing certificate 'Apple Distribution' found"，取决于 Xcode 自动签名能否联网向该 team 申请 profile。

8. **AppIcon 是否已换成 TileMath 正式设计图**没法确认（Flutter 3.44.8 模板路径下找不到对应文件做 md5 比对）。建议你直接打开 `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` 肉眼看一眼是不是还留着默认 Flutter 图标。

9. **年龄分级问卷中"广告是否可能让用户接触年龄敏感内容"如何作答**、是否会强制把 4+ 抬高，没找到 Apple 明确指引。另注意 2026-07-09 Apple 新增了社交媒体相关问题，**自 2026 年 9 月起成为提交强制项** —— 如果你 9 月后才提交，这批题必须答。建议在 ASC 里实际打开问卷逐条看措辞。

10. **`com.tilemath.calculator` 是否已在后台注册、你的 Apple ID 是否有付费会员资格和创建 distribution 证书的权限** —— 本地钥匙串只能看到证书，看不到账号权限，必须你登录控制台确认。

11. **未使用的 app 记录会不会被回收名称** —— Apple 现行官方文档**完全没有**写期限（历史上的 90/120/180 天规则已取消），但也不等于承诺永不回收。别赌"名字永久占住"。

12. **google_mobile_ads 9.0.0 的插屏频控是否满足 AdMob 政策** —— `interstitial_manager.dart:21-29` 的"最短 3 分钟 + 3 次计算"是否达标属政策判断，读代码读不出来。代码逻辑本身确认没问题（`home_page.dart:92` 进历史页前触发、`tile_keyboard.dart:44` Done 时计数，都是自然断点，无"计算中途弹屏"）。

---

## 六、坦率判断：被拒风险

**中高。而且最大的威胁不是 4.2（功能过于简单），是 4.3(b)（Spam）—— 这条 2026-06-08 刚刚收紧过。**

现行 4.3(b) 原文点名了"dating、flashlight、sound effects、wallpaper、simple timers、fortune telling"这类饱和品类，说除非提供 "meaningfully different or improved experience" 否则不接受新提交。瓷砖计算器没被点名，但"简单工具计算器"就是这个判定射程内的典型形态，App Store 已有大量 tile calculator。

更麻烦的是这次修订**新增了删除条款**：`We may remove these apps from the App Store going forward if they are not updated, improved, or do not attract customers.` —— 也就是说过审只是第一关，上架后不涨用户也可能被下架。

另一条要留神的是 **3.2.2(iii)**：明确把 "designed predominantly for the display of ads" 列为不可接受。一个单屏计算器 + 顶部 banner + 插屏，很容易被这么看。

（以下是我的判断和建议，不是 Apple 原文，别当成规则。）降低风险的具体做法：

1. **做深，不做多。** 损耗率/切割浪费、异形与多房间汇总、人字形/错缝等铺贴方式对用量的影响、砖缝宽度、按整箱包装规格取整、成本估算 —— 这些是通用计算器给不了的，是"meaningfully different"最容易论证的方向。

2. **把分数键盘顶到最前面。** 美制 in/ft 分数输入是真实痛点，这是你现有的唯一硬差异化。截图第一屏和描述首段就要讲清楚，别埋在第三张图里。

3. **上原生能力让 "app-like" 立得住。** Widget、App Intents/Siri Shortcuts、结果导出 PDF/分享、离线可用、History 持久化（已有）。相机/AR 测量如果能做，对 4.2/4.3 的加分最大。

4. **广告克制。** 别开屏插屏连打，关闭按钮要明显且够大，加一个广告举报入口（2.5.18 明文要求含广告的 app 必须提供举报能力）。现在的 3 分钟 + 3 次计算频控方向是对的，别再放松。

5. **提交时在 App Review Notes 里主动写与市面同类 app 的差异点。** 这对 4.3(b) 的人工判定有实际帮助 —— 审核员不会替你去找差异。

6. **App 名和关键词不要堆 tile calculator 的同义词。** 4.3 审查会看元数据，堆砌本身就是信号。

需要我开始动手的话，我建议的第一批（不依赖你的账号、可以立刻做完）：ITSAppUsesNonExemptEncryption、CFBundleLocalizations、TARGETED_DEVICE_FAMILY 决策、SKAdNetwork 补 15 删 3、debugPrint 包 kDebugMode、package_info_plus 接版本号、pubspec 版本改 1.0.0+1。告诉我从哪条开始。