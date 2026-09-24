## Why

iOS App Store 审核要求付费能力不得通过非 IAP 路径免费使用。产品决定：功能开通的「邀请码开通」仅保留 Android（及 Web）；原生 iOS App 无论后台 catalog 是否下发 `invite_code` / `inviteAvailable`，均不得展示邀请码开通入口。同时基线中仍残留「预测槽位满额邀码」叙述，与已下线的产品能力冲突，需一并清理。

## What Changes

- 客户端 `FeatureCatalogItem.supportsInviteCode` 增加平台闸门：**原生 iOS App** 恒为 false；Android 与 Web 仍按 `unlockMethods` + `inviteAvailable` 判断。
- 开通中心等所有依赖 `supportsInviteCode` 的邀请开通 CTA 在 iOS 上自动隐藏；不改支付、免费体验、广场「我的邀请码」发码。
- 删除智能预测页对 `invite_code_dialog` 的无用 import（槽位邀码能力已下线）。
- 规格：明确 iOS 邀请开通隐藏；删除/对齐预测槽位满额邀码相关 Requirement；共享邀码弹窗文案收窄为仅服务开通中心。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `feature-unlock-hub`: 邀请码开通 CTA 在原生 iOS 上 MUST NOT 展示（无视 catalog 配置）。
- `user-scoped-feature-commerce`: `inviteAvailable` 可见性规则增加 iOS 平台例外；强化槽位商业能力已删除的终态叙述清理入口。
- `invite-code-howto`: 共享邀码弹窗不再绑定「预测槽位满额」流程，仅服务开通中心等现存调用方。
- `prediction-toggle-slot-gate`: 删除仍要求满额弹出「预测槽位已满」邀码对话框的过时 Requirement / Scenario（与已有「不得槽位闸」终态对齐）。

## Impact

- 代码：`app/lib/data/feature_unlock_models.dart`（`supportsInviteCode`）；`app/lib/ui/smart_prediction_screen.dart`（删死 import）；开通中心行为经 getter 间接生效。
- API / 服务端：无契约变更；后台可继续对全平台下发 `invite_code`，iOS 客户端自行忽略开通入口。
- 不在范围：免费体验、redeem API 服务端硬挡、广场发码 UI、模块介绍弹窗（已无邀请输入框）。
