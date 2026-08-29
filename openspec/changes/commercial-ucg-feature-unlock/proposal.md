## Why

商业化需要重新开放 UCG 表面，并用统一的「功能开通」闭环（喂养天数门槛、预测事件按数量解锁、开通中心支付/广告/邀请码、月卡覆盖功能与预测锁）替代 `pause-ucg-vip-slim-prediction-chrome` 的临时关停。Go `commercial-feature-entitlement` **已落地**；本变更须对齐其 HTTP 契约一次落地客户端体验。

## What Changes

- **BREAKING（相对暂停态）**：翻回 `kUcgHomePagerEnabled`（及 `kVipPurchaseEnabled`、`kHistorySquareSyncEnabled`），主壳恢复喂养 | 预测 | UCG；预测 Auth 滑动引导恢复「左滑进广场 · 右滑去喂养」。
- **保留暂停期 chrome 瘦身**：预测底 tip 仍不恢复；「值得留意」仍仅非空成功态。
- 允许横滑进入 UCG；**仅当** `GET /cash/app/api/ucg/eligibility` 的 `qualified=false` 时全屏锁（天数来自该 API）；「返回预测页」；cache-first；按 `deviceNo` 键控。**`isVip` 不得绕过 UCG 入场**（对齐 Go）。
- 统一 `FeatureLockOverlay`：高斯模糊 + 浅透罩 + **仅中心锁**（无交叉锁链）；预测卡「点击开通」。
- UCG 锁态：**不得** 请求定位 / 刷新广场 Feed；合格后再按既有广场逻辑执行。
- 预测事件：完整展示 + 锁浮层；`allowedCount` 取自 catalog 项 `prediction_unlock`；展示序前 N；`isVip` 全开预测锁；点击 → 开通中心。
- 开通中心：列表来自 `GET /cash/app/api/feature/catalog`（含嵌套 `products[]`）；方式解析 `unlockMethods`（`payment` / `ad` / `invite_code`）；支付用同项 `products[].productCode` 调 `POST .../feature/orders`；UI 邀请码可称激活码，hint「可向群主获取免费激活码」；兑码 `POST .../invite-codes/redeem`；广告 `POST .../ad/complete`。
- 已开通：「已开通」+ 方式（`payment`/`ad`/`invite_code`/`vip`）；隐藏 CTA。
- 页底「开通月卡解锁所有功能」→ VIP 页；VIP 页列 catalog 标题（**不含 UCG**）。
- 设置头像下已开通摘要 → 开通中心；点击与宝宝编辑分离。
- UCG 广场列表 ↔ 瀑布流；PK/辩论全宽。
- **无**独立 entitlements / allowed-count / activation_code App 路径；主读模型 = catalog + eligibility + vip/status。
- **相对** pause change：supersede 临时关停；**不** supersede tip/留意瘦身。

## Capabilities

### New Capabilities

- `ucg-entry-gate`：eligibility 全屏锁、返回预测、cache-first（**非** catalog/VIP 短路）。
- `feature-lock-overlay`：统一锁定浮层。
- `prediction-event-lock`：catalog `allowedCount` + 展示序；VIP 全开预测。
- `feature-unlock-hub`：开通中心、三路径、已开通态、月卡入口。
- `feature-entitlement-client`：catalog 缓存、`isVip` 仅覆盖功能/预测、deviceNo 键控。
- `ucg-square-layout`：列表/瀑布流与 PK 全宽。

### Modified Capabilities

- `ucg-home-entry` / `smart-prediction-page` / `vip-purchase-ux` / `history-event-square-sync` / `home-history-edit-sheet` / `settings-center` / `cash-vip-client`：同前，支付改为功能建单路径并对齐 Go 字段名。

## Impact

- Flag / 壳 / UCG / 预测 / 开通中心 / VIP / 设置 / 广场布局。
- 数据：`FeatureUnlockRepository`（命名可定）对接上表路径；副作用 HTTP 治理。
- 兄弟仓：依赖已落地 Go `commercial-feature-entitlement` + `feature-catalog-embed-products`（catalog 嵌 `products[]`）。
- 测试：不新建 `**/test/**`。
