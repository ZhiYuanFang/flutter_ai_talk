## Why

开通中心支付确认弹窗把金额写在正文「价格：…」，确认键仅「去支付」，扫视成本高且与卡片 CTA 已展示的价重复。产品要求金额以小字括号挂在「去支付」右侧，确认时一眼对齐价与动作。

## What Changes

- 支付确认改为支付专用 `showGlassDialog`（不扩通用 `showGlassConfirmDialog` 的 `confirmLabel` 字符串能力）。
- 确认键文案形态：`去支付` + 右侧小字 `(¥…)`（预测带 `/个`）；正文不再重复「价格：」行。
- Web 仍拦截实付；确认键可显示「仅 App 可支付」并保留括号价（便于对照）。

## Capabilities

### New Capabilities

- `feature-pay-confirm-dialog`：开通中心功能支付确认弹窗的确认键价展示与正文去重。

### Modified Capabilities

- （无基线 capability 变更；叠加 `invite-peer-force-ucg` 开通中心支付路径的 UI 增量。）

## Impact

- Flutter：`feature_unlock_hub_screen.dart` 的 `_openPaymentDialog`；可选同文件私有 helper。
- 不改 `showGlassConfirmDialog` 签名；广告确认仍走原 confirm。
- 不新建测试文件。
