## 1. 后端数据模型与 API（`ucg-push-token-registration`）

- [x] 1.1 ucg-service 新增迁移：`ucg_push_device` 表（`wx_id`、`channel`、`token`、`device_key`、`updated_at`），唯一约束 `(wx_id, device_key, channel)`
- [x] 1.2 实现 `POST /ucg/app/api/push/register`：Bearer 鉴权、channel 枚举校验（`apns|hms|mipush`）、upsert 逻辑
- [x] 1.3 实现 `POST /ucg/app/api/push/unregister`：按 `deviceKey`（及可选 `channel`）删除行
- [x] 1.4 gateway-app 注册路由并转发至 ucg-service（与现有 UCG API 鉴权一致）

## 2. 未读聚合与推送编排（`ucg-launcher-badge-push`）

- [x] 2.1 实现 `ComputeTotalUnread(wxId)`：会话 `unread_count` 之和 + 未读 `ucg_notification` 计数
- [x] 2.2 实现 `PushDispatcher` 接口与 `ApnsSender`、`HmsSender`、`MipushSender`（不含 FCM）
- [x] 2.3 配置化各厂商凭证（环境变量/密钥），staging 与 prod 分离
- [x] 2.4 可见推送模板：DM「{nickname}发来一条私信」、互动「{nickname}评论了你的动态」；payload 含绝对 `badge`
- [x] 2.5 静默推送：已读降级仅更新 `badge`，无 alert；`totalUnread=0` 时 `badge=0`
- [x] 2.6 无效 token 错误码解析并删除 `ucg_push_device` 对应行

## 3. 业务触发钩子（`ucg-chat-ui` + `ucg-notifications`）

- [x] 3.1 新私信投递成功后调用推送钩子（WS 在线仍推送；v1 不折叠同会话多条）
- [x] 3.2 `NotifyOnComment` 成功 insert 后调用可见推送钩子
- [x] 3.3 `POST /notifications/comments/read`（单条/全部）后调用静默 badge 推送
- [x] 3.4 会话标记已读路径调用静默 badge 推送
- [x] 3.5 推送发送异步化，失败记日志且不阻塞主事务

## 4. Flutter 厂商检测与注册（`ucg-push-token-registration`）

- [x] 4.1 新增 `UcgPushRegistrationService`：稳定 `deviceKey` 持久化、厂商检测（iOS/华为/小米）
- [x] 4.2 集成 APNs token 获取（iOS capabilities、entitlements、AppDelegate/插件配置）
- [x] 4.3 集成 HMS Push SDK（华为依赖、`AndroidManifest`、agconnect 配置）
- [x] 4.4 集成 MiPush SDK（小米依赖、manifest 与 appId 配置）
- [x] 4.5 登录且 `isUcgWxAccountBound` 时 `POST /push/register`；token 刷新回调重新 register
- [x] 4.6 登出时 `POST /push/unregister`；非华为/小米 Android 跳过注册且不引入 FCM
- [x] 4.7 `ucg_providers` 或 App 级 listener 接入注册生命周期

## 5. 应用内未读对齐（`ucg-chat-ui`）

- [x] 5.1 确认 `AppLifecycleState.resumed` 路径继续调用 `syncUnreadFromWs` / HTTP 校准
- [x] 5.2 验证 `ucgUnreadCountProvider` 语义与服务端 `totalUnread` 一致（会话 + 互动 OR）
- [x] 5.3 推送点击/冷启动后不单独依赖推送 payload 更新应用内状态

## 6. 验证与收尾

- [ ] 6.1 iOS 真机：杀进程 → 收私信/评论 → 启动器数字角标正确；全部已读 → 角标清零
- [ ] 6.2 华为真机：同上路径验证 HMS 角标与通知栏文案
- [ ] 6.3 小米真机：同上路径验证 MiPush 角标与通知栏文案
- [ ] 6.4 登出后不再收到推送；token 无效后服务端自动清理
- [x] 6.5 `flutter analyze`（`app/`）与 go 侧编译无新增 error
- [x] 6.6 文档记录：非华为/小米 Android 启动器角标不保证（out of scope）

> **6.6 说明**：非华为/小米 Android 不注册 push token、不保证杀进程后启动器数字角标（见 `design.md` Non-Goals）。华为 HMS / 小米 MiPush 原生 SDK 已接入 `UcgPushBridge.publishToken`；真机 token 需配置 `agconnect-services.json`（华为）与 `push.properties` + `app/libs/MiPush_SDK_Client*.aar`（小米）。
