## ADDED Requirements

### Requirement: UcgApiClient SHALL use canonical ucg-service HTTP paths and methods

Flutter UCG HTTP calls MUST align with `go_ai_talk` ucg-service routes exposed via gateway `/ucg/app/api`. `UcgApiClient` SHALL use real HTTP verbs: GET for reads, POST for creates, PUT for updates, DELETE for removals. Paths MUST include at minimum: `GET /feed/recommend` (not `/feed/recommended`), `GET /feed/following`, `GET/PUT /profile/me`, `GET /profile/{wxId}`, `POST /posts`, `POST /media/presign`, `POST/DELETE /posts/{id}/like`, `GET/POST /posts/{id}/comments`, `DELETE /comments/{id}`, `POST/DELETE /follow/{wxId}`, `GET /follow/following`, `GET/POST /conversations`, `GET /conversations/{id}/messages`, `PUT /conversations/{id}/pin`, `DELETE /conversations/{id}`.

#### Scenario: 推荐流使用正确路径
- **WHEN** App 请求推荐 Feed 第一页
- **THEN** Client SHALL 调用 `GET /ucg/app/api/feed/recommend?page=1&pageSize=20`，且 SHALL NOT 使用 `/feed/recommended`

#### Scenario: 取消点赞使用 DELETE
- **WHEN** 已登录用户长按撤销自己的点赞
- **THEN** Client SHALL 发送 `DELETE /ucg/app/api/posts/{postId}/like`，且 SHALL NOT 用 POST 冒充 DELETE

#### Scenario: 置顶会话使用 PUT
- **WHEN** 用户在会话列表左滑置顶
- **THEN** Client SHALL 发送 `PUT /ucg/app/api/conversations/{id}/pin` 且 body 含 `pinned` 字段

### Requirement: ApiClient SHALL expose putJsonEnvelope and deleteEnvelope

The shared `ApiClient` MUST implement `putJsonEnvelope` using `http.put` and `deleteEnvelope` using `http.delete` (empty body), with the same envelope decode, 401 refresh-retry, and error handling as existing GET/POST methods.

#### Scenario: PUT 资料更新走真实 HTTP PUT
- **WHEN** 用户保存个人资料
- **THEN** `UcgApiClient.put` SHALL 委托 `ApiClient.putJsonEnvelope`，底层 HTTP 方法 MUST 为 PUT

#### Scenario: DELETE 删会话走真实 HTTP DELETE
- **WHEN** 用户左滑删除会话
- **THEN** `UcgApiClient.delete` SHALL 委托 `ApiClient.deleteEnvelope`，底层 HTTP 方法 MUST 为 DELETE

### Requirement: UCG DTOs SHALL map canonical backend field names

Request bodies MUST send backend-canonical fields: post body `content` (not only `text`), comment `content`, presign fields per ucg-service spec. Response parsing MUST accept `wxId` / `userId`, `authorWxId` / `authorId`, `content` / `text` as aliases. Post `status` MUST support integer enum from API with mapping to `UcgPostStatus`.

#### Scenario: 发帖请求体含 content
- **WHEN** 用户提交图文动态
- **THEN** `POST /posts` body SHALL 包含 `content` 字段（可与解析层 `text` 属性共存）

#### Scenario: 解析他人帖子作者 wxId
- **WHEN** Feed 响应含 `authorWxId` 而无 `authorId`
- **THEN** `UcgPost.fromJson` SHALL 正确填充作者标识供 UI 与跳转使用

#### Scenario: 解析整型帖子状态
- **WHEN** API 返回 `status: 2` 表示已发布
- **THEN** Client SHALL 映射为 `UcgPostStatus.published` 并在公开 Feed 展示

### Requirement: UCG WebSocket frames SHALL match gateway and ucg-service contract

WS client MUST send auth first frame per gateway proxy expectation (JWT in agreed JSON shape). Outbound chat messages MUST use canonical `type` and field names defined by ucg-service (implementation SHALL verify against `go_ai_talk` source). Inbound parsing MAY tolerate legacy alias `type` values during transition.

#### Scenario: WS 鉴权首帧
- **WHEN** 已登录用户连接 `/ucg/app/ws/chat`
- **THEN** Client SHALL 在连接后首条消息发送含 access token 的 auth 帧，格式与 gateway 代理一致

#### Scenario: 发送文本消息字段
- **WHEN** 用户在聊天页发送文本
- **THEN** WS payload SHALL 使用 ucg-service 约定的 `type` 与正文字段名（非仅 Flutter 草稿字段）

### Requirement: Gateway SHALL inject trusted client IP for UCG IP location

gateway-app `HookBeforeServe` SHALL strip client-spoofed `X-Internal-Client-IP`, `X-Internal-Wx-Id`, and `X-Internal-Device-No`, then inject `X-Internal-Client-IP` from `X-Forwarded-For` first hop or `RemoteAddr`. ucg-service SHALL read this header for IP-to-region resolution; clients MUST NOT send `ipLocation` in profile or post bodies.

#### Scenario: 网关注入客户端 IP
- **WHEN** 任意请求经 gateway-app 转发至 ucg-service
- **THEN** 下游请求 SHALL 携带网关解析的 `X-Internal-Client-IP`，且 SHALL NOT 信任客户端伪造值

#### Scenario: 删除帖子使用 DELETE
- **WHEN** 作者删除自己的帖子
- **THEN** Client SHALL 调用 `DELETE /ucg/app/api/posts/{id}`

#### Scenario: device internal 更新 IP 属地
- **WHEN** ucg-service 解析出用户 IP 属地且节流窗口已过
- **THEN** ucg-service SHALL 调用 `PUT /device/internal/api/ucg/wx/{wxId}/ip-location` 写入 `wx.ip_location`
