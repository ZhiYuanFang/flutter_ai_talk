## ADDED Requirements

### Requirement: Admin feedback list API SHALL paginate and support unreplied filter

`GET /device/admin/api/feedback/list` MUST require admin authentication (`X-Admin-Password` or documented equivalent). It SHALL accept `page` (default 1), `pageSize` (default 20, max 100), and `unrepliedOnly` (boolean). Results MUST be ordered by `created_at` descending and include pagination fields `list`, `total`, `page`, `pageSize`. Each list item MUST expose `id`, `wxId`, `question`, `officialReply`, `status`, `createdAt`, `repliedAt`.

Admin 反馈列表 API 须分页、支持仅未回复筛选，按时间倒序。

#### Scenario: 默认分页列表
- **WHEN** 管理员请求 `GET /device/admin/api/feedback/list?page=1&pageSize=20`
- **THEN** 响应 SHALL 返回最多 20 条记录及 `total`
- **AND** 记录 SHALL 按 `createdAt` 从新到旧排序

#### Scenario: 仅未回复筛选
- **WHEN** 管理员请求 `unrepliedOnly=true`
- **THEN** 响应 `list` SHALL 仅包含 `status=0`（或 `officialReply` 为空）的记录

### Requirement: Admin reply API SHALL allow exactly one official reply per feedback

`POST /device/admin/api/feedback/reply` MUST accept `{ "id": <int64>, "officialReply": "<text>" }`. `officialReply` MUST be non-empty after trim and MUST NOT exceed 2000 characters. The server SHALL set `official_reply`, `status=1`, and timestamps only when the target row is currently unreplied. If the row already has an official reply (`status=1` or `official_reply` non-null), the API MUST reject the request with a business error and MUST NOT modify existing reply text.

Admin 回复 API 每条反馈仅允许回复一次；已回复记录 MUST 拒绝二次回复。

#### Scenario: 首次回复成功
- **WHEN** 管理员对 `status=0` 的记录 POST 合法 `officialReply`
- **THEN** 服务 SHALL 返回 `code=0`
- **AND** 该记录 `status` SHALL 变为 1 且 `officialReply` 持久化

#### Scenario: 二次回复拒绝
- **WHEN** 管理员对已回复记录再次 POST `officialReply`
- **THEN** 服务 SHALL 返回 `code≠0` 及明确错误信息
- **AND** 数据库中 `officialReply` SHALL 保持原值不变

### Requirement: Admin feedback-records page SHALL mirror qa-records independent page pattern

The system MUST serve `resource/public/feedback-records.html` at `/device/admin/feedback-records`. The page MUST use admin password login, call `/device/admin/api/feedback/*`, display a paginated table (newest first), provide an「仅未回复」filter toggle, show reply action only for unreplied rows, and include a link back to `/device/admin`. `admin.html` MUST include a card entry (with「展开更多」link to the full page when applicable) consistent with the QA card pattern.

Admin 须提供独立 `feedback-records.html` 分页管理页，并在 `admin.html` 提供入口卡片。

#### Scenario: 独立页访问
- **WHEN** 管理员打开 `/device/admin/feedback-records` 并输入正确口令
- **THEN** 页面 SHALL 展示分页反馈表格
- **AND** SHALL 提供「仅未回复」筛选与刷新操作

#### Scenario: 已回复行不可再编辑
- **WHEN** 列表中某行 `status=1`
- **THEN** 页面 SHALL NOT 展示可编辑回复表单或提交按钮
- **AND** SHALL 只读展示已有 `officialReply`

#### Scenario: admin 卡片入口
- **WHEN** 管理员在 `/device/admin` 主页查看设备管理
- **THEN** 页面 SHALL 展示「用户反馈」相关卡片
- **AND** SHALL 提供跳转 `/device/admin/feedback-records` 的链接
