## Why

iOS 锁屏 Live Activity 依赖 `POST /app/api/push/live-activity/register` 上报 Push-to-Start token，但线上环境无法查看系统日志时，用户与客服难以判断「有没有注册成功、卡在哪一层」。设置中心需要一个仅 iOS 的「锁屏通知」入口：把注册显态告知用户，并提供手动重试，以便在无 logcat 前提下辅助排查客户端注册成败。同时，锁屏监听不得继续挂靠「消息通知」应用偏好——关消息推送不应切断 Live Activity token 监听。

## What Changes

- 设置中心（已登录、仅 iOS）新增「锁屏通知」入口与子页，交互对标「消息通知」页的玻璃面板风格。
- 子页展示锁屏 Live Activity 注册显态（系统能力/允许态、imminent/timing 的 push_to_start 上报结果、最近失败原因等），支持手动「开通/重试」；失败信息展示在下方且可被用户复述或复制。
- **不**新增自动 register 触发时机（仍由现有登录后 bootstrap、resume、token 刷新等路径驱动）；手动重试仅复用现有 listen → token → register 管线。
- **解耦**：应用层「消息通知」偏好关闭时，MUST NOT 停止 iOS Live Activity 监听与 `live-activity/register`；消息偏好仅约束普通设备推送 register/unregister。
- **不**新增独立的「锁屏通知 Off」持久化开关（本变更以显态 + 重试为主；若系统不允许 Live Activities，引导跳转系统设置）。
- 不改 Go API 契约；不要求服务端查询接口。

## Capabilities

### New Capabilities

- `settings-live-activity`: 设置中心 iOS「锁屏通知」入口、注册显态、手动重试与失败展示（面向线上无系统日志的排障辅助）。

### Modified Capabilities

- `app-notification-preference`: 明确消息通知偏好关闭时 MUST NOT 阻断 iOS Live Activity token 监听与 `live-activity/register`（与设备 push unregister 解耦）。
- `predict-imminent-live-activity`: 补充「已登录即可监听/上报；显态与手动重试不改变自动 register 时机」的客户端行为边界（与对端 Push-to-Start 契约不变）。

## Impact

- Flutter：`settings_screen`、路由、`LiveActivityRegistrationService` / bootstrap 门闩、新建锁屏通知设置页与状态 provider；可选原生探测 `areActivitiesEnabled`。
- 对照基线：`openspec/specs/v2.1.4.md` 中消息通知设置入口与偏好；既有 change `predict-ios-live-activity` 的 LA register 需求。
- 不影响 Android/Web 设置列表（入口仅 iOS）；不影响 Go `live-activity/register` 字段。
