## Context

当前双仓库均无用户反馈相关代码。喂养 App 设置中心（`settings_screen.dart`）已建立玻璃拟态视觉体系：渐变 `Scaffold` 背景、`_SettingsGlassPanel`（`BackdropFilter` blur + 渐变描边 + 圆角 22）、`_buildGlassTile` 列表项，以及登录门禁模式（未登录显示引导文案并跳转 `/login`，已登录显示「账号管理」等能力）。

go_ai_talk 设备域已有可复用 Admin 模式：`qa-records.html` 独立分页页、`/device/admin/api/qa/*` 列表 API、`admin.html` 卡片 +「展开更多」链接。JWT App API 惯例为 `/device/app/api/*`，`wx_id` 从 access_token `sub` 解析，数据落在 `ai_voice_device` 库。

## Goals / Non-Goals

**Goals:**

- 登录用户可在设置中心进入反馈页，查看本人历史反馈（问题 + 官方回复）并提交新问题。
- 运营在 Admin 独立页分页浏览反馈、筛选未回复项、对每条记录执行**一次**官方回复。
- Flutter 反馈全流程 UI 与设置中心玻璃拟态一致（非 UCG 简约卡片）。
- API 契约清晰：`/device/app/api/feedback/*` 与 `/device/admin/api/feedback/*`。

**Non-Goals:**

- 用户编辑或删除已提交反馈。
- Admin 修改或删除已回复内容（仅拒绝二次回复，不提供编辑 UI）。
- 推送/站内信通知用户「已回复」。
- 富文本、图片附件、分类标签。
- 自动化测试文件。
- UCG 模块 UI 变更。

## Decisions

### 1. 数据模型（`feedback` 表，`ai_voice_device`）

| 列 | 类型 | 说明 |
|----|------|------|
| `id` | BIGINT PK AUTO_INCREMENT | 主键 |
| `wx_id` | BIGINT NOT NULL, INDEX | 提交用户，关联 `wx.id` |
| `question` | VARCHAR(2000) NOT NULL | 用户问题正文 |
| `official_reply` | VARCHAR(2000) NULL | 官方回复；NULL 表示未回复 |
| `status` | TINYINT NOT NULL DEFAULT 0 | `0`=待回复，`1`=已回复（与 `official_reply` 非空一致） |
| `created_at` | DATETIME | 提交时间 |
| `updated_at` | DATETIME | 最后更新时间（回复时更新） |
| `replied_at` | DATETIME NULL | 官方回复时间（可选，便于排序展示） |

索引：`(wx_id, created_at DESC)` 用于 App 列表；`(status, created_at DESC)` 用于 Admin 未回复筛选。

**理由**：字段最小化满足列表/筛选/单次回复；`status` 便于 Admin 筛选，避免仅依赖 `official_reply IS NULL` 的隐式语义。

### 2. App API 契约

**鉴权**：须携带有效 JWT；从 `sub` 解析 `wx_id`；未登录返回 401。

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/device/app/api/feedback/list` | 返回当前 `wx_id` 全部记录，`created_at` 倒序 |
| POST | `/device/app/api/feedback/submit` | Body: `{ "question": "..." }`；校验非空、长度 ≤ 2000 |

响应 DTO 字段：`id`, `question`, `officialReply`（可空）, `status`, `createdAt`, `repliedAt`（可空）。

**理由**：路径与现有 device app API 扁平风格一致；列表不分页（单用户量级可控），Admin 侧分页。

### 3. Admin API 与页面

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/device/admin/api/feedback/list` | Query: `page`, `pageSize`, `unrepliedOnly`（bool）；`created_at` 倒序 |
| POST | `/device/admin/api/feedback/reply` | Body: `{ "id": 123, "officialReply": "..." }` |

**单次回复约束**：若 `status=1` 或 `official_reply` 非空，返回业务错误（如 code≠0，message 表明已回复），**不得**覆盖原回复。

**静态页**：`/device/admin/feedback-records` → `resource/public/feedback-records.html`，结构与 `qa-records.html` 对齐：管理口令登录、`X-Admin-Password`、分页、「仅未回复」checkbox、行内回复表单（仅 `status=0` 行展示）、`admin.html` 卡片 +「展开更多」链到独立页。

### 4. Flutter 路由与门禁

- 设置中心：已登录显示「反馈建议」`_buildGlassTile`；未登录不显示或显示带「登录后使用」副标题并 `push('/login')`（与账号管理一致：仅 `loggedIn` 块内展示）。
- 路由：`/settings/feedback` → `FeedbackListScreen`。
- 数据层：`FeedbackRepository` 调用上述 App API，错误 toast。

### 5. Flutter 玻璃 UI 决策（**强制**）

反馈列表页 **必须** 复用设置中心视觉语言，**不得** 使用 `UcgSurfaceCard` 或 UCG minimal 白底卡片作为主容器。

```
Scaffold(extendBodyBehindAppBar: true)
├── AppBar(transparent) 标题「反馈建议」
├── body: Container(gradient: shellColor → primaryContainer 轻渐变)  // 同 settings_screen
│   └── Column
│       ├── Expanded: ListView
│       │   ├── 空状态: _SettingsGlassPanel + 欢迎文案
│       │   └── 列表项: 每项 _SettingsGlassPanel
│       │       ├── 用户问题（onShell 主色）
│       │       └── 官方回复区（已回复显示；未回复显示「等待官方回复」弱化文案）
│       └── 底部 dock: _SettingsGlassPanel 包裹 TextField + primary 胶囊「提交」
```

**组件复用策略**：

- 优先从 `settings_screen.dart` 提取或复制 `_SettingsGlassPanel` 到共享 widget（如 `settings_glass_panel.dart`），避免反馈页与设置页 drift。
- 提交按钮：`FilledButton` + `StadiumBorder` + `ColorScheme.primary`，与设置/发布动线 primary 胶囊一致。
- 输入框：可使用 `ManagedKeyboardTextField` 或 `TextField` 置于玻璃 panel 内；底部 dock 随键盘 `viewInsets` 上移。
- 列表卡片圆角 22、blur sigma 14、渐变描边与 `_SettingsGlassPanel` 参数一致。

**理由**：用户明确要求反馈 UI 匹配设置中心玻璃风，与 UCG Tab 简约风 intentional 分叉。

### 6. 实现顺序

1. go_ai_talk：DDL → entity/dao → service → App/Admin API → `feedback-records.html` → `admin.html` 入口
2. flutter_ai_talk：repository → 列表页玻璃 UI → 设置入口 → 路由 → 联调

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| `_SettingsGlassPanel` 私有类未共享，反馈页复制导致样式漂移 | 任务中要求提取共享 widget 或显式对齐参数 |
| 单用户反馈量大导致 App 列表变慢 | 首版不分页；若后续需要可加 `page` 参数 |
| Admin 误操作欲改回复 | 产品锁定单次回复；API 硬拒绝，UI 隐藏已回复行的编辑控件 |
| 双仓库发布顺序 | 先部署后端 DDL+API，再发版客户端 |

## Migration Plan

1. 在 `ai_voice_device`（及 `_test`）执行 `feedback` 表 DDL。
2. 部署 go_ai_talk device-service / gateway 路由。
3. 验证 Admin 页与 API（`feedback-records.html`）。
4. 发布 Flutter 客户端并联调提交/列表/回复展示。

回滚：客户端隐藏入口；后端保留表数据；Admin 页可下线链接。

## Open Questions

- 欢迎空状态文案由产品/运营最终定稿（实现阶段可使用占位：「欢迎提出建议，我们会认真阅读每一条反馈」）。
- 是否在 `admin.html` 内嵌最近 N 条预览（建议与 QA 一致：卡片摘要 +「展开更多」跳转独立页）。
