# 隐私政策草稿

App Store Connect **强制要求**每个 app 提供隐私政策 URL；审核指南 5.1.1(i) 还要求 **app 内也能方便访问**（只填 ASC 字段而 app 内没入口，是高频被拒原因）。

因为首发版本不带广告、不联网、不收集任何数据，这份政策可以写得非常干净——**这本身就是竞争优势，值得在商店描述里讲**。

---

## 需要你先定的两件事

1. **托管地址**：GitHub Pages 最省事（免费、有 HTTPS）。建个 public 仓库 `tilemath-site`，把下面的 HTML 存成 `privacy.html`，开启 Pages，地址形如
   `https://<你的用户名>.github.io/tilemath-site/privacy.html`
   这个域名同时能当 Support URL 用。

2. **公开联系邮箱**：政策里必须留一个联系方式。下面用 `tilemath.app@gmail.com` 占位——**要不要用你的私人邮箱是你的决定**，我没有替你填。建议单独注册一个 `tilemath.app@gmail.com` 之类的对外邮箱，别把常用私人邮箱公开。

---

## 正文（英文，替换两处占位后即可发布）

```
# Privacy Policy for TileMath

Last updated: July 27, 2026

## Summary

TileMath does not collect, transmit, or share any personal data. The app
works entirely offline and does not connect to the internet.

## Information We Collect

None.

TileMath does not collect personal information, usage analytics, device
identifiers, advertising identifiers, location data, or crash reports. There
is no account system, no sign-up, and no way to contact the app's servers —
because there are no servers.

## Information Stored on Your Device

Your calculation history and app settings (units, language, appearance,
currency symbol) are saved locally on your device so the app remembers them
between launches. This data never leaves your device. We cannot see it.

You can delete your calculation history at any time using "Clear all" on the
History screen. Deleting the app removes all stored data permanently.

## Third-Party Services

TileMath contains no advertising SDKs, no analytics SDKs, and no third-party
tracking of any kind.

## Children's Privacy

TileMath does not collect data from anyone, including children under 13.

## Changes to This Policy

If a future version of the app changes how data is handled, this policy will
be updated before that version is released, and the "Last updated" date above
will change.

## Contact

Questions about this policy: tilemath.app@gmail.com
```

---

## App Store Connect 的「App 隐私」问卷怎么答

这是独立于隐私政策 URL 的另一套申报（隐私营养标签），**漏报是首次提交被拒的高频原因**。首发版本的答法非常简单：

**「你或你的第三方合作伙伴是否从此 App 收集数据？」→ 选「否，我们不会从此 App 收集数据」**

选了这个，后面所有数据类型的问题都会跳过。

**前提是这个答案必须属实——目前属实：**
- `google_mobile_ads` 已从依赖移除，包里没有任何广告/追踪 SDK
- 没有 analytics、没有崩溃上报
- `shared_preferences` 只写本地 UserDefaults，数据不出设备，**不算"收集"**（Apple 的定义是"数据被传输离开设备"）

⚠️ **以后加回广告时，这一整套都要重填**：数据类型要勾 Identifiers（设备 ID / 广告标识符）、Usage Data、Diagnostics、粗略位置，用途勾 Third-Party Advertising。ATT 也要一起做。别忘了。

---

## 代码侧待办（我来做，等你定了 URL）

`lib/ui/settings_page.dart` 里隐私政策那一行现在是空实现：

```dart
ListTile(
  title: Text(l10n.privacyPolicy),
  trailing: const Icon(Icons.open_in_new, size: 18),
  onTap: () {},          // ← 空函数
),
```

需要加 `url_launcher` 依赖并接上真实 URL。同一行下面的 `rateApp` 也是空实现——**上架后用户点了没反应比没有这个入口更糟**，要么接 `in_app_review`，要么先隐藏。
