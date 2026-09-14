## ADDED Requirements

### Requirement: Unlock hub MUST show sticky monthly VIP bar with countdown title when VIP

The feature unlock hub screen SHALL restore a sticky bottom monthly-VIP bar (`bottomNavigationBar` or equivalent non-scrolling chrome). When the user is not VIP, the bar MUST offer navigation to `/vip/purchase` (subject to `kVipPurchaseEnabled`). When the user is VIP, the primary title MUST use the form `VIP · {remaining}` where `{remaining}` is produced by the existing remaining-days copy helper (e.g. 「剩余 N 天」, 「不足 1 天」, 「已过期」, 「永久」); the bar MUST NOT show a purchase button for active VIP. A secondary line SHOULD show the expiry calendar date when `expireAt > 0`.

功能开通中心必须恢复底部月卡 sticky：未 VIP 可进购买页；已 VIP 主标题必须为「VIP · 剩余文案」，无购买按钮。

#### Scenario: Non-VIP opens purchase

- **WHEN** 用户未开通月卡且 `kVipPurchaseEnabled` 为 true，并点击底栏开通 CTA
- **THEN** 客户端必须导航至 `/vip/purchase`

#### Scenario: VIP sees countdown title

- **WHEN** 用户已是 VIP 且剩余不少于 1 个整日
- **THEN** 底栏主标题必须呈现为「VIP · 剩余 N 天」形态（N 为正整数），且不得展示「去开通月卡」按钮

#### Scenario: VIP permanent

- **WHEN** 用户已是 VIP 且 `expireAt` 表示永久（≤0）
- **THEN** 底栏主标题必须呈现为「VIP · 永久」（或等价永久剩余文案），且不得展示购买按钮

### Requirement: Care alert detail MUST NOT offer VIP purchase CTA

The prediction care-alert detail screen MUST NOT present a VIP purchase entry (including commented-out or latent CTAs). Residual pause-era VIP CTA code and unused related imports MUST be removed.

值得留意详情页不得提供 VIP 开通入口；必须删除暂停期 VIP CTA 残留代码。

#### Scenario: Care alert has no VIP bar

- **WHEN** 用户打开值得留意详情页
- **THEN** UI 不得展示「开通 VIP」或等价购买入口（含底部 sticky / FAB）
