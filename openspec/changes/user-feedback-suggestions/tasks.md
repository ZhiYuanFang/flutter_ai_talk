## 1. [go_ai_talk] 数据模型与 DDL（feedback-data-model）

- [x] 1.1 编写 `feedback` 表 DDL（`ai_voice_device` / `ai_voice_device_test`）：`id`, `wx_id`, `question`, `official_reply`, `status`, `created_at`, `updated_at`, `replied_at`
- [x] 1.2 添加索引 `(wx_id, created_at)` 与 `(status, created_at)`
- [x] 1.3 生成或手写 `entity.Feedback`、`dao.Feedback`（对齐现有 `qa` 模式）
- [x] 1.4 在部署 runbook 或 migration 文档中记录 DDL 执行步骤

## 2. [go_ai_talk] App API（feedback-api）

- [x] 2.1 定义 `api/v1/device_app_feedback_http.go`：`DeviceAppFeedbackListReq/Res`、`DeviceAppFeedbackSubmitReq/Res`
- [x] 2.2 实现 `GET /device/app/api/feedback/list`：JWT 鉴权、`wx_id` 作用域、时间倒序
- [x] 2.3 实现 `POST /device/app/api/feedback/submit`：非空与 2000 字校验、插入 `status=0`
- [x] 2.4 注册 controller 路由；确认不在 `gateway_app_auth_exempt` 白名单内
- [x] 2.5 在 `device_route_proxy.go` 增加 `/device/app/api/feedback/*` 反代前缀（gateway-app → device-service）

## 3. [go_ai_talk] Admin API 与页面（feedback-admin）

- [x] 3.1 定义 `api/v1/device_admin_feedback_http.go`：list（分页 + `unrepliedOnly`）、reply
- [x] 3.2 实现 `GET /device/admin/api/feedback/list`：Admin 口令鉴权、分页、倒序
- [x] 3.3 实现 `POST /device/admin/api/feedback/reply`：首次回复成功；已回复记录拒绝二次回复
- [x] 3.4 新建 `resource/public/feedback-records.html`（对齐 `qa-records.html`：登录、表格、分页、仅未回复筛选、行内回复）
- [x] 3.5 在 `register.go` / `gateway_app_register.go` 绑定 `/device/admin/feedback-records` 静态页
- [x] 3.6 在 `admin.html` 增加「用户反馈」卡片与「展开更多」链接

## 4. [flutter_ai_talk] 数据层与路由

- [x] 4.1 新建 `Feedback` 模型与 `FeedbackRepository`（list + submit，对接 App API）
- [x] 4.2 在 `app_router.dart` 注册 `/settings/feedback`，未登录门禁

## 5. [flutter_ai_talk] 设置入口（settings-feedback-entry）

- [x] 5.1 在 `settings_screen.dart` 已登录区块新增「反馈建议」`_buildGlassTile`
- [x] 5.2 点击跳转 `/settings/feedback`；未登录不展示入口

## 6. [flutter_ai_talk] 反馈列表页玻璃 UI（feedback-list-screen）

- [x] 6.1 提取或共享 `_SettingsGlassPanel`（避免与 `settings_screen.dart` 样式漂移）
- [x] 6.2 新建 `FeedbackListScreen`：渐变 Scaffold、透明 AppBar「反馈建议」
- [x] 6.3 列表项玻璃卡片：问题 + 官方回复 /「等待官方回复」占位
- [x] 6.4 空状态：玻璃 panel 内欢迎引导文案
- [x] 6.5 底部玻璃输入 dock：TextField + primary 胶囊「提交」；键盘 `viewInsets` 适配
- [x] 6.6 提交成功后清空输入、刷新列表、toast 提示

## 7. 联调与验收

- [ ] 7.1 [go_ai_talk] 本地验证 Admin 列表、仅未回复筛选、单次回复与二次回复拒绝（需部署含 2.5 反代修复后的 gateway-app）
- [ ] 7.2 [flutter_ai_talk] 已登录：设置入口 → 列表 → 提交 → 展示待回复态（需 test/prod 部署后联调）
- [ ] 7.3 端到端：Admin 回复后 App 列表展示官方回复（需 test/prod 部署后联调）
- [x] 7.4 未登录：设置无入口、直达路由被门禁（`settings_screen` 仅 `loggedIn` 展示入口；`app_router` redirect 拦截 `/settings/feedback`）
- [x] 7.5 `openspec validate user-feedback-suggestions` 通过
