## Context

当前 UCG 未读指示依赖 App 内 `ucgUnreadCountProvider`：由 WebSocket `comment_notification` / 会话事件与 HTTP `GET /conversations`、`GET /notifications/comments` 校准，在 UCG Shell 消息 Tab、喂养页「进入广场」拉条等位置展示红点。进程被杀或 App 在后台时，用户无法从桌面启动器图标获知未读总数。

`fix-ucg-social-ux-ws` 已强化登录后 UCG WS 长连与喂养页未读同步，但不解决**杀进程后**的启动器角标。本变更与前者独立，仅共享未读计数语义：`totalUnread(wxId) = Σ(会话 unread) + unread comment/mention 通知数`。

约束：遵循 `v2.0.2` 基线；推送通道限定 **APNs（iOS）**、**HMS Push（华为）**、**MiPush（小米）**；**不得使用 FCM**；非华为/小米 Android 不保证启动器角标；全栈同迭代交付 `go_ai_talk` + Flutter 原生；不含 Web。

## Goals / Non-Goals

**Goals:**

- 服务端权威计算绝对未读总数，经官方通道推送 `badge=N` 至已注册设备。
- 新私信、新互动通知触发**可见**推送（通知栏文案 + 角标）；全部已读或已读降级触发**静默**角标更新（`badge=0` 或无 alert）。
- 客户端登录且 wxId 绑定后自动注册推送 token；登出注销；App resume 时 HTTP/WS 校准与应用内未读一致。
- 持久化 `ucg_push_device`，支持同一用户多设备、多通道 token。

**Non-Goals:**

- FCM 或通用 Android 推送兜底。
- 非华为/小米 Android 杀进程后启动器数字角标（可展示系统通知栏，但不承诺角标数字）。
- Web 客户端推送。
- v1 推送折叠/同会话多条 DM 合并为一条通知。
- v1 因收件人在线已 WS 投递而跳过推送（仍发推送，见 Open Questions）。
- 自定义推送铃声、富媒体、深度链接路由细化（首版打开 App 即可）。

## Decisions

### 1. 未读总数计算（服务端权威）

`ComputeTotalUnread(ctx, wxId)`：

```
totalUnread = SUM(conversation.unread_count WHERE recipient=wxId)
            + COUNT(ucg_notification WHERE recipient_wx_id=wxId AND read_at IS NULL)
```

与客户端 `ucgUnreadCountProvider` OR 逻辑对齐。推送 payload 中 `badge` **必须为绝对值**，不得发增量 `+1`。

**备选**：客户端上报未读 → 拒绝，易被篡改且杀进程后无客户端。

### 2. 推送通道与厂商检测

| 平台 | 通道 | channel 枚举 |
|------|------|----------------|
| iOS | APNs | `apns` |
| 华为 Android | HMS Push Kit | `hms` |
| 小米 Android | MiPush | `mipush` |
| 其他 Android | — | 不注册 / register 返回 400 或客户端跳过 |

Flutter 启动时用 `device_info` + 厂商元数据检测；仅匹配通道时初始化对应 SDK 并获取 token。**不集成** `firebase_messaging`。

**备选**：FCM 统一 Android → 拒绝，与产品决策冲突且小米/华为角标需厂商通道。

### 3. 设备注册 API 与表结构

`ucg_push_device`（ucg-service）：

| 列 | 类型 | 说明 |
|----|------|------|
| id | BIGINT PK | |
| wx_id | BIGINT | 收件人 |
| channel | ENUM | `apns` \| `hms` \| `mipush` |
| token | VARCHAR(512) | 厂商 token |
| device_key | VARCHAR(64) | 客户端稳定设备 id（如 UUID 持久化） |
| updated_at | TIMESTAMP | |

唯一约束：`(wx_id, device_key, channel)`。登出或 token 失效时 `unregister` 删除行。

```
POST /ucg/app/api/push/register
Body: { "channel": "apns|hms|mipush", "token": "...", "deviceKey": "..." }
Auth: Bearer（wxId 非零）

POST /ucg/app/api/push/unregister
Body: { "deviceKey": "...", "channel": "..." }  // channel 可选，省略则删该 deviceKey 全部
```

gateway-app 鉴权转发；token 存储与发送逻辑均在 **ucg-service**。

### 4. 推送 payload 契约

**可见推送**（新 DM / 新互动通知）：

- **alert/body**：本地化中文模板，如「{nickname}发来一条私信」「{nickname}评论了你的动态」
- **badge**：`ComputeTotalUnread` 结果（整数 ≥ 1）
- **sound**：默认（iOS `default`，厂商默认）
- **data**（可选）：`{ "type": "dm"|"comment", "refId": "..." }` 供后续深链扩展

**静默角标更新**（已读降级 / 全部已读）：

- **badge**：当前 `totalUnread`（通常为 0）
- **无 alert/title**（APNs `content-available` + `badge`；HMS/MiPush 等价静默分类）
- 用户不应在通知栏看到「已读」类打扰文案

**备选**：已读不发推送 → 拒绝，角标会滞留直至用户打开 App。

### 5. 触发时机（服务端钩子）

| 事件 | 推送类型 | 文案示例 |
|------|----------|----------|
| WS/业务层成功投递新 DM 给收件人 | 可见 + badge | 「张三发来一条私信」 |
| `NotifyOnComment` 写入通知行 | 可见 + badge | 「李四评论了你的动态」 |
| `POST /notifications/comments/read`（单条或全部） | 静默 + badge | 无 alert |
| 会话内标记已读 / 打开聊天清零会话 unread | 静默 + badge | 无 alert |
| 登出 unregister 后 | 不推送 | — |

v1：**收件人 WebSocket 在线且已 `message_delivered` 时仍发送推送**（保证杀进程角标一致；可能短时重复提醒，接受）。

v1：**同会话连续多条 DM 不折叠**，每条各发一条可见推送。

异步：推送发送失败记录日志，不阻塞主业务事务；可选重试队列（首版至少一次 best-effort）。

### 6. 客户端注册生命周期

1. App 启动 → 厂商检测 → 若支持则初始化 SDK、取 token。
2. `sessionProvider.isLoggedIn && isUcgWxAccountBound` → `POST /push/register`。
3. token 刷新（厂商回调）→ 重新 register（upsert）。
4. 登出 → `POST /push/unregister` + 释放 SDK 监听。
5. `AppLifecycleState.resumed` → 现有 `syncUnreadFromWs` / HTTP 校准 `ucgUnreadCountProvider`（与 `fix-ucg-social-ux-ws` 一致）；**不**依赖推送回调更新应用内状态。

应用内红点仍由 WS/HTTP 驱动；推送仅负责**系统通知栏 + 启动器角标**。

### 7. 多通道发送适配层

ucg-service 内 `PushDispatcher` 接口 + 三实现：

- `ApnsSender`：HTTP/2 APNs，p8 密钥或证书配置化
- `HmsSender`：华为 Push REST
- `MipushSender`：小米 Push REST

按 `ucg_push_device.channel` 分组 fan-out；无效 token 响应时删除对应行。

配置项（环境变量/密钥管理）：各厂商 appId、appSecret、APNs keyId、teamId、bundleId 等。

## Risks / Trade-offs

- **[Risk] 非华为/小米 Android 无启动器角标** → 文档与产品明确 out of scope；仍可通过厂商通道外的系统通知（若用户授权）展示文案，但不承诺 badge 数字。
- **[Risk] 在线用户收到冗余推送** → v1 接受；后续可按「最近 N 分钟 WS 活跃」过滤。
- **[Risk] 厂商 token 失效未清理** → 发送失败解析 `InvalidRegistration` 等错误码并 delete 行。
- **[Risk] badge 与 App 内未读短暂不一致** → resume 时 HTTP 校准；推送 badge 以服务端为准。
- **[Risk] 密钥与证书运维** → 配置分离、staging 独立 bundle/应用 id；文档列出轮换步骤。
- **[Risk] 同会话多条推送打扰** → v1 不折叠；后续引入 collapse key。

## Migration Plan

1. **DB**：ucg-service 迁移脚本创建 `ucg_push_device`。
2. **后端**：实现 register/unregister、ComputeTotalUnread、PushDispatcher；在 DM 投递、NotifyOnComment、mark-read 挂钩子；gateway 路由。
3. **配置**：各环境注入 APNs/HMS/MiPush 凭证（CI 密钥库）。
4. **Flutter**：集成厂商 SDK、注册服务、登录/登出监听；iOS capabilities、Android 华为/小米 manifest 与依赖。
5. **验证**：杀进程后发 DM/评论 → 启动器角标数字正确；全部已读 → 角标清零；登出 → 不再收到推送。
6. **回滚**：关闭推送钩子 feature flag；保留表与 API 无妨；客户端 unregister 可选。

## Open Questions

| 问题 | v1 默认 |
|------|---------|
| 已读降级是否发推送？ | **是**，静默 badge only |
| 收件人 WS 在线是否仍推送？ | **是**，仍推送 |
| 同会话多条 DM 是否折叠？ | **否**，不折叠 |
| token 存哪？ | **ucg-service** `ucg_push_device` |
| 推送深链打开具体会话/Inbox？ | 首版仅冷启动 App，深链后续迭代 |
