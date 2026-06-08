## ADDED Requirements

### Requirement: Feedback table SHALL persist user questions and official replies in ai_voice_device

The system MUST create a `feedback` table in the `ai_voice_device` database (and `ai_voice_device_test` for test environments) with at least: `id` (PK), `wx_id` (NOT NULL, indexed), `question` (NOT NULL, max 2000 chars), `official_reply` (nullable, max 2000 chars), `status` (0=pending, 1=replied), `created_at`, `updated_at`, and optionally `replied_at`. Each row MUST belong to exactly one `wx.id`.

系统须在 `ai_voice_device` 库创建 `feedback` 表，持久化用户问题与官方回复，并按 `wx_id` 关联账号。

#### Scenario: 新反馈入库
- **WHEN** App 成功提交一条合法反馈
- **THEN** 系统 SHALL 插入一行 `feedback`，`wx_id` 为当前用户，`status=0`，`official_reply` 为 NULL
- **AND** `created_at` SHALL 记录提交时间

#### Scenario: 官方回复后状态更新
- **WHEN** Admin 对 `status=0` 的记录执行首次回复
- **THEN** 系统 SHALL 写入 `official_reply` 并将 `status` 设为 1
- **AND** `updated_at`（及 `replied_at` 若存在）SHALL 更新为回复时间

### Requirement: Feedback indexes SHALL support user list and admin unreplied filter

The table MUST have an index on `(wx_id, created_at)` for per-user history queries and an index on `(status, created_at)` for admin unreplied filtering.

表须具备支持按用户查历史与按未回复状态筛选的索引。

#### Scenario: 按用户查历史
- **WHEN** 服务按 `wx_id` 查询反馈列表
- **THEN** 查询 SHALL 可利用 `(wx_id, created_at)` 索引按时间倒序返回

#### Scenario: Admin 仅未回复筛选
- **WHEN** Admin 请求 `unrepliedOnly=true`
- **THEN** 查询 SHALL 可利用 `(status, created_at)` 索引筛选 `status=0` 记录
