## ADDED Requirements

### Requirement: App feedback APIs SHALL require JWT and scope data by wx_id

All `/device/app/api/feedback/*` endpoints MUST require a valid access_token (JWT). The server SHALL derive `wx_id` from the token `sub` claim and MUST only return or create feedback rows for that `wx_id`. Unauthenticated requests MUST return 401.

App 反馈 API 须 JWT 鉴权，数据 MUST 按 token 内 `wx_id` 作用域隔离；未登录返回 401。

#### Scenario: 未登录访问列表
- **WHEN** 客户端请求 `GET /device/app/api/feedback/list` 且无有效 JWT
- **THEN** 服务 SHALL 返回 401
- **AND** SHALL NOT 返回任何反馈数据

#### Scenario: 用户无法查看他人反馈
- **WHEN** 用户 A 的 JWT 请求反馈列表
- **THEN** 响应 SHALL 仅包含 `wx_id` 等于用户 A 的记录
- **AND** SHALL NOT 包含其他用户的反馈

### Requirement: App SHALL list current user feedback in reverse chronological order

`GET /device/app/api/feedback/list` SHALL return all feedback rows for the authenticated `wx_id`, ordered by `created_at` descending. Each item MUST include `id`, `question`, `officialReply` (nullable), `status`, `createdAt`, and `repliedAt` (nullable when applicable).

App 须提供当前用户反馈历史列表 API，按提交时间倒序。

#### Scenario: 有历史记录
- **WHEN** 已登录用户请求反馈列表且存在 3 条历史
- **THEN** 响应 `code=0` 且 `data.list` SHALL 含 3 项
- **AND** 列表 SHALL 按 `createdAt` 从新到旧排序

#### Scenario: 无历史记录
- **WHEN** 已登录用户请求反馈列表且无记录
- **THEN** 响应 `code=0` 且 `data.list` SHALL 为空数组

### Requirement: App SHALL submit new feedback with validated question text

`POST /device/app/api/feedback/submit` MUST accept JSON body `{ "question": "<text>" }`. `question` MUST be non-empty after trim and MUST NOT exceed 2000 characters. On success the API SHALL create a new `feedback` row with `status=0` and return the created record (or its `id`).

App 须提供提交反馈 API，校验问题正文非空且长度合法。

#### Scenario: 成功提交
- **WHEN** 已登录用户 POST `{ "question": "希望增加夜间模式" }`
- **THEN** 服务 SHALL 返回 `code=0`
- **AND** 数据库 SHALL 新增一条该用户的待回复反馈

#### Scenario: 空问题拒绝
- **WHEN** 已登录用户 POST `{ "question": "   " }`
- **THEN** 服务 SHALL 返回业务错误（`code≠0`）
- **AND** SHALL NOT 插入记录

#### Scenario: 超长问题拒绝
- **WHEN** 已登录用户 POST 超过 2000 字符的 `question`
- **THEN** 服务 SHALL 返回业务错误
- **AND** SHALL NOT 插入记录
