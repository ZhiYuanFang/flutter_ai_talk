## Context

UCG 模块已按 `add-ucg-module` 在 Flutter 端实现 UI、壳层与数据层骨架（`app/lib/ucg/`）。喂养模块通过 `sessionProvider` + `/device/app/api/*` 与 gateway-app 通信；UCG 经同域 `/ucg/app/api/*` 与 `/ucg/app/ws/chat` 代理至 `ucg-service`。

**当前阻塞点**（经代码与后端契约比对）：

| 类别 | Flutter 现状 | go_ai_talk ucg-service 期望 |
|------|-------------|---------------------------|
| 推荐流路径 | `GET /feed/recommended` | `GET /feed/recommend` |
| HTTP 方法 | `UcgApiClient.put/delete` 实为 POST | 真实 PUT / DELETE |
| 用户 ID | `userId` 字符串，靠 profile 副作用写入 | `wxId`（int64 字符串化），JWT `sub` |
| 帖子正文 | 请求/解析 `text` | 请求 `content`，响应可双字段 |
| 帖子状态 | 字符串枚举 `pending_audit` 等 | 整型 `0/1/2/3` |
| 评论 | 请求 `text` | 请求 `content` |
| 作者字段 | `authorId` | `authorWxId` |
| 会话置顶 | `POST .../pin` | `PUT .../pin` |
| 删评路径 | `/posts/{id}/comments/{cid}` | `/comments/{cid}`（以 ucg-service 为准） |
| 发起会话 | 未实现 | `POST /conversations` |
| WS 帧 | `type: auth` + `send_message` | 与 gateway 代理及 ucg-service 约定对齐 |
| 身份 | `ucgCurrentUserIdProvider` 初始 null | 应从 JWT `sub` 同步 |

架构无需重做：gateway 已将 JWT `sub` 注入 `X-Internal-Wx-Id` 转发 ucg-service；UCG **不得**要求独立登录，与喂养共用 access token。

## Goals / Non-Goals

**Goals:**

- 使 UCG 推荐流、个人资料、发帖、互动、私信 HTTP/WS 与 `go_ai_talk` ucg-service 契约一致，端到端可联调。
- `ucgCurrentUserIdProvider` 从 JWT `sub` 派生 `wxId`，与后端用户主键一致。
- `ApiClient` 支持真实 PUT/DELETE，`UcgApiClient` 正确委托。
- `wxId=0`（纯设备态、未绑微信）进入 UCG 需账号操作时给出明确产品提示。
- 喂养模块零回归：`/device/app/api/*`、`RemoteFeedRepository`、history WS 不改动。

**Non-Goals:**

- UCG UI/视觉改版（沿用 `add-ucg-module` 与 `ucg-visual-system`）。
- 宝藏 Tab 功能开通。
- 修改 ucg-service 核心业务逻辑（以现有后端契约为准，客户端对齐）。
- 喂养登录/刷新/device_no 流程重构。
- 新增 UCG 独立登录页或独立 token 体系。

## Decisions

### 1. 契约对齐策略：客户端向 ucg-service 看齐

**Decision**：以 `go_ai_talk` ucg-service 已暴露的路由、方法、JSON 字段为单一事实来源；Flutter `UcgRepository` / `ucg_models.dart` 做适配层（解析时兼容 `text`/`content`、`userId`/`wxId` 等别名，请求时发送后端要求的 canonical 字段）。

**Alternatives**：改后端路由迁就 Flutter 草稿 — 增加 gateway 重定向与双轨维护成本，且与已部署 ucg-service 不一致。

### 2. ApiClient 扩展 PUT/DELETE

**Decision**：在 `ApiClient` 新增 `putJsonEnvelope`（`http.put`）与 `deleteEnvelope`（`http.delete`，无 body）；复用现有 `_send` 401 刷新与 `_decodeResponse` 信封解析。`UcgApiClient.put/delete` 改为调用上述方法。

**Alternatives**：在 `UcgApiClient` 内直接用 `http` — 绕过统一鉴权刷新，与项目惯例不符。

### 3. wxId 身份：JWT sub 为主源

**Decision**：在 `token_expiry.dart`（或同级工具）新增 `readJwtWxId(token)`，解析 JWT `sub` 为字符串；`ucgCurrentUserIdProvider` 由 `sessionProvider` 监听同步更新。`fetchMyProfile` 成功后可校验/补全昵称头像，但**不得**作为 wxId 唯一来源。

**Alternatives**：每次 API 从 profile 响应取 id — 多一次 RTT，且 profile 失败时 UCG 全不可用。

### 4. wxId=0 门控

**Decision**：当 `sub` 为 `"0"` 或空时，UCG 需登录类操作（关注、发帖、点赞、消息）展示专用文案：「请先绑定微信账号后再使用社区功能」，引导至现有绑定/登录流；推荐流仍可匿名浏览（gateway 白名单）。

**Alternatives**：静默失败或通用「去登录」— 设备态用户无法理解原因。

### 5. 帖子 status 整型映射

**Decision**：`UcgPostStatus.fromApi` 同时接受 `int` 与 `String`：`0=draft, 1=pending, 2=published, 3=rejected`（具体数值以 ucg-service 常量为准，实现时对照 Go enum）。对外 UI 仍用 Dart enum。

### 6. WS 帧格式

**Decision**：实现阶段对照 `go_ai_talk` gateway WS 代理与 ucg-service handler 源码确定 auth 首帧与 `send_message` payload 字段名；`UcgRepository._onWsMessage` 保持对多种 `type` 别名的宽容解析，但发送侧使用 canonical 格式。

**Alternatives**：仅按 Flutter 现有草稿 — 联调必失败。

### 7. 分阶段实施（与 tasks 一致）

| Phase | 范围 |
|-------|------|
| 1 | 路径/HTTP 方法/核心字段 → 推荐流 + profile/me |
| 2 | presign + createPost + status 枚举 |
| 3 | 互动 + 关注 + conversation HTTP |
| 4 | WS 帧 + gateway WS 代理验证（task 8.5） |
| 5 | JWT sub→wxId + wxId=0 UX |

### 8. 喂养隔离边界

**Decision**：变更文件限定在 `app/lib/api/api_client.dart`（通用 PUT/DELETE，喂养亦可用但无调用方变更）、`app/lib/ucg/**`、`app/lib/session/token_expiry.dart`（仅新增 wxId 解析）。禁止修改 `RemoteFeedRepository`、`home_history_*`、`device_no_notifier` 业务逻辑。

## Risks / Trade-offs

- **[Risk] 后端字段文档与代码漂移** → 实现前对照 `go_ai_talk` ucg-service handler 与 gateway 路由表；联调清单写入 tasks Phase 验收项。
- **[Risk] PUT/DELETE 经 gateway 未正确转发** → 先在 dev 环境用 curl/Postman 验证 gateway 对 UCG 路由的方法支持，再改 Flutter。
- **[Risk] `GET /profile/{wxId}` 未加入匿名白名单** → 需 gateway 侧配置（联调任务）；未登录看他人主页会 401。
- **[Risk] wxId=0 与「已登录」语义重叠** → 设备态 `isLoggedIn` 可能为 true 但 `sub=0`；门控须同时检查 wxId 非零。
- **[Risk] 双 WS（history + ucg）连接数** → 沿用 `add-ucg-module` 策略：仅消息 Tab active 时保持 UCG WS。
- **[Trade-off] DTO 双字段兼容增加解析代码** → 换取渐进联调，避免一次性大爆炸；待稳定后可删别名分支。

## Migration Plan

1. **开发环境**：确认 `UCG_SERVICE_BASE_URL`、JWT secret 与 gateway-app 一致；gateway 启用 UCG HTTP/WS 代理。
2. **Flutter 按 Phase 1→5 合并**，每 Phase 完成后对应用例手工验证（`flutter run`）。
3. **Gateway 变更**（白名单）：与后端同 PR 或先行部署；Flutter 不假设白名单已存在，profile 他人页失败时降级提示。
4. **回滚**：各 Phase 可独立 revert Flutter 文件；无数据库迁移；喂养无耦合可独立回滚。
5. **生产**：UCG 与喂养同 gateway 同域发布；WS 代理 task 8.5 通过后上线消息功能。

## Open Questions

- ucg-service 评论删除的 canonical 路径是 `/comments/{id}` 还是嵌套在 post 下？实现时以 Go 路由注册为准。
- 帖子 `status` 整型与字符串的精确映射表需从 ucg-service `const` 或 proto 抄录。
- WS `send_message` 是否必须经 HTTP 先 `POST /conversations` 获取 `conversationId`，还是 WS 可隐式创建？需对照 ucg-service 会话创建流程。
- `GET /profile/{wxId}` gateway 匿名白名单由哪方 PR 提交？建议 go_ai_talk 侧与本变更联调任务绑定。
