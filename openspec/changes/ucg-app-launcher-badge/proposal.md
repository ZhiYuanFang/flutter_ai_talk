## Why

UCG 未读数目前仅在 App 前台通过 WebSocket 与 HTTP 校准驱动应用内红点（`ucgUnreadCountProvider`），进程被杀死后桌面启动器图标无法展示数字角标，用户会错过私信与互动消息。需在 iOS 与华为/小米 Android 上通过官方推送通道（APNs、HMS Push、MiPush）将服务端权威未读总数同步到启动器角标，并配合可见通知栏文案提醒。

## What Changes

- 新增推送设备注册/注销 API（`POST /ucg/app/api/push/register`、`POST /ucg/app/api/push/unregister`）与 `ucg_push_device` 持久化表（`wx_id`、`channel`、`token`、`device_key`）。
- 服务端在以下时机向已注册设备推送：**新私信**、**新互动通知**（评论/@）、**已读降级**（静默角标更新）；`badge` 字段为绝对未读总数（会话未读之和 + 未读互动通知数），非增量。
- 可见推送正文示例：「张三发来一条私信」「李四评论了你的动态」；全部已读时发送静默推送 `badge=0`（无 alert）。
- Flutter 客户端：厂商检测（iOS APNs / 华为 HMS / 小米 MiPush）、登录且 wxId 绑定后注册 token、登出注销、App resume 时 `syncUnreadFromWs` 校准；**不使用 FCM**。
- 非华为/小米 Android：**明确不保证**进程被杀后启动器角标（超出范围）。
- 与 `fix-ucg-social-ux-ws` 独立变更；仅共享 `ucgUnreadCountProvider` 未读语义（会话 + 互动 OR）。
- **范围**：iOS + Android 原生客户端；不含 Web。
- v1 默认：收件人在线且 WS 已投递仍发推送；同会话多条私信不折叠；token 存储在 ucg-service。

## Capabilities

### New Capabilities

- `ucg-push-token-registration`：客户端厂商通道检测、推送 token 获取、登录/登出时 register/unregister API 调用与设备键管理。
- `ucg-launcher-badge-push`：服务端未读总数计算、多通道推送编排（APNs/HMS/MiPush）、可见/静默 payload 契约与触发时机。

### Modified Capabilities

- `ucg-notifications`：`NotifyOnComment` 成功写入通知后须触发启动器角标推送（含可见 alert 与绝对 `badge`）。
- `ucg-chat-ui`：新私信投递后服务端须触发启动器角标推送（含可见 alert 与绝对 `badge`）；客户端 resume 时继续 `syncUnreadFromWs` 与推送角标对齐。

## Impact

- **后端 `go_ai_talk`**（同迭代交付）：ucg-service 新增 `ucg_push_device` 表与 DAO；`POST /push/register`、`POST /push/unregister` handler；未读总数聚合查询；APNs / HMS / MiPush 发送适配层；在 DM 投递、NotifyOnComment、标记已读路径挂推送钩子。
- **gateway-app**：路由鉴权转发上述 push API。
- **Flutter `app/`**：新增推送 SDK 集成（`flutter_local_notifications` 或各厂商官方插件）、厂商检测、`UcgPushRegistrationService`；`AndroidManifest` / iOS entitlements / 华为小米配置；`ucg_providers` 登录监听扩展。
- **基线**：引用 `v2.0.2` 中 `ucg-chat-ui`、`ucg-notifications` 并做 delta；未读计数语义与 `ucg-home-entry` / `ucgUnreadCountProvider` 一致。
- **不在范围**：FCM、非华为/小米 Android 启动器角标保证、Web、推送消息折叠/聚合策略。
