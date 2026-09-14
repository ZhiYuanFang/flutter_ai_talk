## Context

- 兄弟仓 `go_ai_talk` 已实现 client-usage：`POST /device/app/api/client-usage/report`（须登录）、Redis 聚合 + 时间线、Admin Hub「客户端使用统计」。现网 Body 仅 `featureId`；时间线成员为 `unix|featureId`（故 `|` 非法）。同 wxId **3 秒**限流 1 次成功写入；失败可丢。
- 本仓尚无埋点层。产品目标：全量登录用户上报，按新用户体验设计事件，运维通过 Admin 时间线反省「页是否进过、关键控件是否用过」。
- 主壳为嵌套导航：外层 `UcgHomeShell` PageView（喂养 | 预测 | UCG）+ `UcgShell` IndexedStack/底栏（广场、消息、我的；发布为 push）+ 大量 GoRouter 独立页。KeepAlive 页不得用 `initState` 冒充「展示」。

## Goals / Non-Goals

**Goals:**

- 静默上报 `featureId` + `description`；未登录不调；错误不 toast。
- 页展示覆盖：主壳三页、UCG 子表面、Compose、**全部**登录后可达路由页（含设置）。
- 动作：预测开关 on/off（列表数据序 + 事件类型名）、预测/UCG 布局切换、主题入口、主题成功、换宝宝头像成功。
- 事件字典集中维护，避免各处手写漂移。

**Non-Goals:**

- 本地 3s 队列 / 可靠投递 / 离线重试。
- 游客未登录上报、仅新用户客户端过滤。
- 在本仓实现 Go/Admin（须跨仓并行；本设计约定契约）。
- 新建 `**/test/**` 测试文件（遵循 project.md）。

## Decisions

### D1：仓储与静默语义

- **选择**：`ClientUsageRepository` 经 `authorizedApiClientProvider` 调 `postJsonEnvelope`；catch 业务/HTTP 错误后 **仅** `AppDebugLog`（若启用 tag）记录，**不** toast、不 rethrow 到 UI。
- **理由**：对齐「用户无感知」；与 `FeedbackRepository` 的 toast 路径刻意分离。
- **备选**：复用 Feedback 错误处理 — 否决（会打扰用户）。

### D2：调用方式与副作用治理

- **选择**：在明确 UI 生命周期/手势处 `unawaited(report(...))`（`onPageChanged`、Tab 切换、路由页首帧可见、按钮成功路径）；**不**在 Riverpod `listen` 里批量自动刷报。
- **理由**：符合副作用 HTTP 治理；避免状态抖动刷爆限流。
- **备选**：GoRouter observer 全局统一 — 可作辅助，但 pager/KeepAlive 仍须壳层补枪；本变更以壳层 + 页内钩子为主。

### D3：契约字段

- **选择**：Body `{ "featureId": string, "description": string }`；二者 trim 后非空；均勿含 `|`；`featureId` ≤128（与现网一致）；`description` 建议 ≤128（与 Go 上限对齐，Go 须校验）。
- **跨仓**：Go 须：校验并写入时间线（建议 `unix|featureId|description` 或 registry last-write-wins + 时间线扩展）；Admin 功能列表与用户时间线 **必须**展示 description。
- **备选**：仅客户端硬编码中文、服务端无 description — 否决（运维要求）。

### D4：事件字典

- **选择**：集中常量（或小表）映射 `featureId` → 默认中文 `description`；动态描述（开关顺序/事件名、主题名）由调用方格式化后传入。
- **聚合键**：稳定 `featureId`（如 `prediction_card_toggle_on`）；细节进 description，避免按顺序/事件碎聚合。

### D5：预测开关描述格式（已锁定）

- **选择**：
  - `featureId`：`prediction_card_toggle_on` / `prediction_card_toggle_off`
  - `description`：`开启预测开关（顺序 {n}·{事件显示名}）` / `关闭预测开关（顺序 {n}·{事件显示名}）`
  - **顺序**：当前 `rows` 数组下标 **+ 1**（列表数据序，从 1 起）
  - **事件**：该行 `eventId` 对应目录显示名（无则退回 eventId）
- **理由**：运维可读；聚合仍看 on/off；顺带知道开的是哪种事件。
- **备选**：视觉瀑布列序 — 否决（难算，非本阶段）。

### D6：页展示触发

| 表面 | 触发 |
|------|------|
| 喂养 / 预测 / 进入 UCG 壳 | 外层 `onPageChanged`；冷启落在预测须首帧补报（`onPageChanged` 可能不触发） |
| UCG 广场 / 消息 / 我的 | `_selectTab` 变为该 Tab |
| 发布动态 | `UcgComposeScreen` 打开（push） |
| 设置及其它路由页 | 各页进入可见时（如首帧 `addPostFrameCallback` 或统一 observer）；**不得**漏掉非 pager 页 |

同一会话内同一 `featureId` 是否去重：**不去重**（每次展示可报）；撞 3s 限流则丢弃可接受。

### D7：其它动作

- 预测布局切换 / UCG 广场布局切换：toggle 成功后报（description 写明切到列表或瀑布）。
- 主题：`ThemePaletteIconButton` 点击 → `theme_palette_open`；apply/clear 成功 → `theme_change_ok`（description 含预设名或「自定义/经典」）。
- 换宝宝头像：本地落盘成功 → `baby_avatar_change_ok`（失败不报成功事件）。

### D8：限流策略

- **选择**：不做客户端串行队列；依赖服务端 3s；丢点可接受。
- **理由**：产品明确新用户不会极速连滑；实现简单。

## Risks / Trade-offs

- [Go 未先发 description] → 客户端发未知字段可能被忽略或整请求失败；联调前确认 Go 已接受 description，或短暂兼容仅 featureId（本变更以双字段为准）。
- [3s 丢点] → 时间线可能缺环；产品已接受。
- [KeepAlive 漏报] → 必须挂可见切换，禁止只靠 initState。
- [featureId 拼写分裂] → 字典集中 + code review。
- [模拟用户] → Go 侧跳过写入；客户端仍可调用（无感）。

## Migration Plan

1. `go_ai_talk`：report + store + Admin 展示 `description`；更新 runbook。
2. 本仓：仓储 + 字典 + 挂点发版。
3. 回滚：停调 report 或服务端忽略；Redis 自然过期。

## Open Questions

无（探索已锁定：全页展示、开关序=rows 下标+1、描述含事件名、主题点/成功分开、换头像、不排队）。
