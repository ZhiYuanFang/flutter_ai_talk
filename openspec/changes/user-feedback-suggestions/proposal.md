## Why

用户在使用喂养 App 时缺少向官方提交问题与查看回复的闭环渠道；运营侧也无法在设备管理后台集中处理用户反馈。需在 Flutter 设置中心提供「反馈建议」入口，并在 go_ai_talk 设备域补齐持久化、App API 与 Admin 回复能力，形成登录用户可提交、可回看、官方单次回复的完整流程。

## Cross-Repo Scope

本变更为 **双仓库联动**：

| 仓库 | 是否变更 | 说明 |
|------|----------|------|
| **flutter_ai_talk** | ✅ 是 | 设置中心入口、反馈列表页（玻璃拟态 UI）、App API 客户端 |
| **go_ai_talk** | ✅ 是 | `ai_voice_device` 新表、App/Admin API、`feedback-records.html`、admin 卡片入口 |

## What Changes

### Flutter（flutter_ai_talk）

- 设置中心新增「反馈建议」玻璃 tile（登录后可见，未登录点击引导登录，与「账号管理」门禁一致）。
- 新路由 `/settings/feedback`：反馈列表页，展示当前用户历史反馈（问题 + 官方回复）。
- 底部玻璃输入 dock + 提交新反馈；空状态展示欢迎文案。
- **UI 约束**：必须使用设置中心同款玻璃拟态（`_SettingsGlassPanel`、渐变 Scaffold、玻璃列表卡片），不得使用裸 UCG 简约卡片。

### go_ai_talk

- `ai_voice_device` 库新增 `feedback` 表（`wx_id` 作用域、问题、官方回复、状态、时间戳）。
- App API（JWT，`wx_id` 从 token 解析）：
  - `GET /device/app/api/feedback/list` — 当前用户历史列表，时间倒序。
  - `POST /device/app/api/feedback/submit` — 提交新问题。
- Admin API + 独立页面 `feedback-records.html`（对齐 `qa-records.html` 模式）：
  - 分页列表、时间倒序、「仅未回复」筛选。
  - 每条记录仅可回复一次；已回复记录 Admin UI 不得再编辑，API 拒绝二次回复。
- `admin.html` 增加反馈管理卡片入口链接。

### 锁定产品决策

1. **必须登录**才能提交与查看历史（与账号管理门禁一致）。
2. **官方回复仅一次** — Admin 回复后不可通过 UI 修改；API 对二次回复返回错误。
3. **Admin 独立页** — `/device/admin/feedback-records`，与问答库分页页一致，非内嵌表格。

## Capabilities

### New Capabilities

- `feedback-data-model`：设备库 `feedback` 表 DDL、实体与 DAO 约定
- `feedback-api`：App 端反馈列表与提交 API（JWT + `wx_id` 作用域）
- `feedback-admin`：Admin 反馈列表、单次回复 API 与 `feedback-records.html`
- `settings-feedback-entry`：设置中心「反馈建议」入口与登录门禁
- `feedback-list-screen`：反馈列表页（历史展示、空状态、底部提交、玻璃拟态 UI）

### Modified Capabilities

（无 — 均为新增能力，不修改既有 OpenSpec 基线需求。）

## Impact

**flutter_ai_talk**

- `app/lib/ui/settings_screen.dart` — 新增玻璃 tile
- 新建 `app/lib/ui/feedback_list_screen.dart`（或等价路径）
- 新建 `app/lib/data/feedback_repository.dart`（或并入现有 API 层）
- `app/lib/router/app_router.dart` — 注册 `/settings/feedback`

**go_ai_talk**

- DDL / migration：`feedback` 表（`ai_voice_device`）
- `api/v1/device_app_feedback_http.go`、`api/v1/device_admin_feedback_http.go`（或等价）
- `internal/controller/`、`internal/services/device/`、`internal/dao/`、`internal/model/entity/`
- `resource/public/feedback-records.html`
- `resource/public/admin.html` — 卡片入口
- `internal/controller/register.go`、`gateway_app_register.go` — 静态页与路由绑定

**依赖与联调**

- Flutter 依赖 gateway-app JWT；`wx_id` 与现网登录态一致。
- 部署时需先执行 device 库 DDL，再发布后端与客户端。
