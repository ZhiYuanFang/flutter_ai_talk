## Why

功能开通中心底部月卡入口被注释关闭，用户难以从该页一键开通 VIP；已是 VIP 时也缺少一眼可见的到期倒计时。值得留意详情仍残留暂停期 VIP CTA 注释/变量，产品已决定该页不再提供开通入口，应清理以免误恢复。

## What Changes

- 恢复开通中心 `bottomNavigationBar` 月卡 sticky 条：未 VIP 展示开通引导并跳转 `/vip/purchase`；已 VIP 标题采用 **「VIP · 剩余 N 天」**（不足 1 天 / 已过期 / 永久等沿用既有剩余文案语义），副文可保留到期日。
- **删除**值得留意详情页的 VIP 开通入口残留（注释掉的 bottom bar、`showVipCta`、仅为此服务的 import/注释）；该页不再展示 VIP 购买 CTA。
- 相对旧 `care-alert-vip-purchase`「留意页须有开通 VIP」：**BREAKING（产品撤销）** —— 以本变更为准。

## Capabilities

### New Capabilities

- `unlock-hub-vip-sticky`: 开通中心底栏月卡条（含 VIP 倒计时标题）与值得留意页去 VIP CTA

### Modified Capabilities

- （无）基线 `v2.1.0` 无独立 capability 文件夹需 delta；行为以本 change 新增 spec 为准，并覆盖历史 care-alert VIP CTA 要求。

## Impact

- **代码**：`feature_unlock_hub_screen.dart`（恢复 sticky + `vipProductProvider`）；`prediction_care_alert_screen.dart`（删 VIP 残留）。
- **路由**：依赖既有 `/vip/purchase` 与 `kVipPurchaseEnabled`。
- **埋点**：进购买页仍可走既有 `page_vip_purchase_show`（若已接入 client-usage）。
