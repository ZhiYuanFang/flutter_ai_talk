## Why

兄弟仓 `go_ai_talk` 的 `unify-live-activity-list` 已将 Live Activity 收敛为**每用户一条**、ContentState 为 `items[]`（预测 + 进行中混排）的统一推送契约，并去掉 register 的 `attributesKind` / `activityId` 分槽。本仓仍按 Imminent / Timing **双 Attributes** 与双槽锁屏实现，无法消费新消息体，也无法在锁屏同时展示「进行中 + 预测」。需要 Flutter/iOS twin 同发对齐。

## What Changes

- **统一单条 LA（BREAKING）**：废弃 `PredictImminentAttributes` / `PredictTimingAttributes` 双轨；改为单一 `BabyLiveActivityAttributes`（与 Go `PUSH_LA_ATTR_TYPE` 默认名对齐），ContentState 含 `items[]` + `phase`。
- **锁屏纵向列表**：按 `items` 动态渲染；每条按 `kind`（`imminent` / `timing`）**复用现有各态行样式**（非固定三行模板；不新造 nextAt 倒计时行）。
- **顶栏「胖宝」**：唯一一行，**横向居中**，文字色用 **App 主题色**（产品主色常量；非事件 accent）。
- **Dynamic Island**：仅展示 `items.first`，并沿用该条 kind 的既有 Island 样式；其余条目仅锁屏可见。
- **register 契约（BREAKING）**：`POST /app/api/push/live-activity/register` 不再传 `attributesKind` / `activityId`；原生/Dart 监听与设置页诊断收敛为单轨（`push_to_start` + `activity`）。
- **文档**：更新 `LIVE_ACTIVITY.md` 与设置页文案，指向统一列表契约。
- **非目标**：不改 Android Live Update；不改预测算法 / pending PUT 业务字段；不要求 Go 再改消息体（以已落地 Refresh/`items[]` 为准）。

## Capabilities

### New Capabilities

- `unified-live-activity`：统一列表态 Live Activity 的 Attributes/ContentState 契约、锁屏纵向列表、顶栏居中主题色「胖宝」、Island 仅首条、以及单轨 token 监听与 register。

### Modified Capabilities

- `predict-imminent-live-activity`：锁屏/Island 专属双层单事件与双 Attributes 要求改为由统一列表中的 `kind=imminent` 行承载；register 分槽要求废止。
- `predict-timing-live-activity`：同上，`kind=timing` 行复用既有 Timing 行/Island 样式；多槽 Timing LA 废止。
- `settings-live-activity`：「已开通」与诊断从双 `attributesKind` 收敛为单 Attributes 轨的 push_to_start / activity 状态。

## Impact

- iOS：`PangbaoWidget`（Attributes / Views / Widget 注册）、`PredictLiveActivityBridge`、`LiveActivityNativeRegister`、深链。
- Dart：`live_activity_registration_service`、`live_activity_native`、`live_activity_registration_status`、设置页 `live_activity_settings_screen`。
- 文档：`app/ios/PangbaoWidget/LIVE_ACTIVITY.md`、`app/README.md`（若 Debug/LA 表受影响）。
- 对端：依赖已合入的 Go `unify-live-activity-list`（须同发/联调开关 `PUSH_LIVE_ACTIVITY_ENABLED`）。
- 基线：相对 `openspec/specs/v2.1.8.md` 中双轨 LA 需求为破坏性 UI/契约变更。
