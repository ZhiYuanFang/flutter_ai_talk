## Context

- `FeatureUnlockHubScreen` 已有 `_VipStickyBar`，但 `bottomNavigationBar` 被注释；ListView 仍留 `SizedBox(height: 140)`。
- `kVipPurchaseEnabled == true`；`/vip/purchase` 可达。
- 已 VIP 时现文案偏「月卡已开通」+ 括号内剩余天数；产品要求标题突出 **「VIP · 剩余 N 天」**。
- `PredictionCareAlertScreen` 残留暂停期 VIP CTA 注释与 `showVipCta`；产品明确不要该入口。

## Goals / Non-Goals

**Goals:**

- 恢复开通中心底栏月卡条；未 VIP 可去购买页；已 VIP 标题倒计时优先。
- 清除值得留意页 VIP 开通残留代码。

**Non-Goals:**

- 改 VIP 下单/验单逻辑、价格展示。
- 在其它页面新增 VIP 入口。
- 客户端埋点新事件（购买页展示沿用既有即可）。

## Decisions

### D1：恢复 sticky 接线

- **选择**：取消注释 `bottomNavigationBar: _VipStickyBar(...)`；`build` 中 `watch(vipProductProvider)`；`onOpenPurchase` 在 `kVipPurchaseEnabled` 为 true 时 `push('/vip/purchase')`，否则 null。
- **理由**：复用已有组件与留白；对齐商业化重开规格。

### D2：已 VIP 标题文案

- **选择**：主标题为 `VIP · {剩余文案}`，其中剩余文案复用 `featureRemainingDaysCopy(expireAt)`（如「剩余 12 天」「不足 1 天」「已过期」「永久」）。副文保留「有效期至 YYYY-MM-DD」（`expireAt>0` 且非永久时）；永久可副文写「长期有效」或省略日期行。
- **理由**：用户锁定「VIP · 剩余 N 天」形态，一眼感知身份与倒计时。
- **备选**：仅副文含剩余 —— 否决（不够醒目）。

### D3：未 VIP 文案

- **选择**：保持「开通月卡解锁所有功能」+ 开通后有效期说明 +「去开通月卡」按钮。

### D4：值得留意去 VIP CTA

- **选择**：删除注释 bottom bar、`showVipCta`、相关暂停注释；移除因此变为未使用的 import（如仅为此引入的 `ucg_feature_flags`、`foundation` kIsWeb、`app_toast` 若无其它引用）。
- **理由**：产品撤销留意页开通入口，避免误恢复。

## Risks / Trade-offs

- [历史 care-alert VIP CTA spec] → 本 change 明确覆盖；归档时以本行为为准。
- [expireAt=0 永久 VIP] → 标题「VIP · 永久」，避免「剩余 0 天」误解。

## Migration Plan

1. 发版客户端即可；无服务端迁移。
2. 回滚：再注释 sticky / 恢复留意 CTA（不推荐）。

## Open Questions

无。
