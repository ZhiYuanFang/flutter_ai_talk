## Why

UCG 模块（`app/lib/ucg/`）的 UI 与壳层已在 `add-ucg-module` 变更中落地，但 Flutter 客户端与 `go_ai_talk` `ucg-service` 之间存在大量 **API 契约不一致**（路径、HTTP 方法、字段名、WS 帧格式），且客户端未将 JWT `sub`（微信 `wx.id`）映射为 UCG 用户 ID，导致 UCG 功能实际上无法跑通。架构方向已正确——UCG 与喂养模块共用 gateway-app JWT，后端经 `X-Internal-Wx-Id` 识别用户——本变更的目标是在 **不破坏喂养模块**（`/device/app/api/*`、`/device/app/ws/history`）的前提下，对齐契约使 UCG 可运行，并复用同一账号体系（无需 UCG 独立登录）。

## What Changes

- **HTTP 路径与方法对齐**：修正推荐流 `/feed/recommended` → `/feed/recommend`；点赞取消、关注取消、删评、删会话等改用真实 **DELETE**；置顶会话改用 **PUT**；评论删除路径与后端一致。
- **ApiClient 能力补全**：在 `ApiClient` 新增 `putJsonEnvelope` / `deleteEnvelope`；`UcgApiClient.put` / `delete` 改为调用真实 HTTP 方法，不再用 POST 冒充。
- **字段与 DTO 对齐**：统一 `wxId` / `userId` / `authorWxId` 映射；帖子正文 `content` vs `text`；媒体 presign 请求/响应字段；帖子 `status` 整型枚举 vs 字符串；WS 收发帧格式与 gateway 代理约定一致。
- **身份与鉴权**：`ucgCurrentUserIdProvider` 从 JWT `sub`（wx.id）派生，而非依赖 `fetchMyProfile` 副作用；`GET /profile/{wxId}` 需 gateway 匿名白名单以支持未登录浏览他人资料；设备态 `wxId=0` 会话进入 UCG 需登录类操作时展示明确产品错误（非静默失败）。
- **缺失 API 补全**：Flutter 侧实现 `POST /conversations` 以发起私信会话。
- **部署与联调**：确认 `UCG_SERVICE_BASE_URL`、JWT secret 与 gateway 一致；验证 gateway WS 代理（task 8.5）对 `/ucg/app/ws/chat` 的端到端可用性。
- **喂养安全区（不得修改）**：`/device/app/api/*`、`/device/app/ws/history`、`gateway_app_history_ws.go`、`RemoteFeedRepository`、`device_no` / refresh 逻辑。

## Capabilities

### New Capabilities

- `ucg-api-contract`：Flutter UCG HTTP/WS 与 `go_ai_talk` ucg-service 的路径、方法、请求/响应字段契约对齐（含 `ApiClient` PUT/DELETE）。
- `ucg-wxid-identity`：JWT `sub` → UCG `wxId` 客户端映射、`wxId=0` 设备态 UX 门控，以及与 gateway `X-Internal-Wx-Id` 的一致性约定。

### Modified Capabilities

- `ucg-square-feed`：推荐流路径 `/feed/recommend`、分页响应字段解析、帖子 `status` 整型枚举映射。
- `ucg-profile`：`wxId` 字段、`GET /profile/{wxId}` 匿名访问、资料更新请求体字段。
- `ucg-compose-post`：媒体 presign 字段、`createPost` 请求体（`content`）、状态枚举。
- `ucg-interactions`：点赞/取消（POST/DELETE）、评论字段与删除路径、关注/取关 HTTP 方法。
- `ucg-chat-ui`：WS auth/消息帧格式、`POST /conversations`、会话置顶 PUT、删会话 DELETE。

## Impact

- **Flutter 客户端**：`app/lib/api/api_client.dart`、`app/lib/ucg/data/ucg_api_client.dart`、`ucg_repository.dart`、`ucg_models.dart`、`ucg_providers.dart`、相关 UI 门控（`ucg_login_gate.dart` 等）。
- **后端（go_ai_talk，联调侧）**：`gateway-app` UCG 路由白名单（`GET /profile/{wxId}`）、WS 代理配置；`ucg-service` 契约以现有实现为准，客户端向其对齐。
- **不受影响**：喂养模块全部 HTTP/WS、`sessionProvider` 登录刷新流程、`RemoteFeedRepository`、历史同步与 `device_no` 逻辑。
- **部署**：`UCG_SERVICE_BASE_URL`、JWT secret 跨服务一致；gateway `/ucg/app/ws/chat` 代理需与 HTTP 同域验证。
