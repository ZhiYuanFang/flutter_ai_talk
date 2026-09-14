## Why

AI 分析页把「喂养记录分析」与「成长轨迹预测」的开通门闸与完整业务（列表/日刷新、SSE 问答/结果）叠在同一 `ListView`，页面过重；已开通用户需要整屏工作台。同时客户端用本地「今日已刷」藏「AI智能分析」与 Go 日缓存语义重复，冷启动后难以再拉回当日缓存，且同日再点得到相同结果时缺少预期文案。

## What Changes

- **BREAKING（信息架构）**：`/prediction/ai-analysis` 改为 **Hub 资格门**：两张极简能力卡；未合格/未开通在 Hub 拦截（进度 / 邀请开通）；**已开通**可点击进入对应子页完成业务。
- **新增**喂养工作台路由（如 `/prediction/ai-analysis/feeding`）：列表、「AI智能分析」、条目进既有 `/prediction/alert`；**不得**因进页自动请求 `care-alert/daily`。
- **新增**成长轨迹工作台路由（如 `/prediction/ai-analysis/growth`）：承接现有预测/问答/思考/结果；Hub **不得** `ensureLatest`；进子页再拉历史。
- **移除**喂养客户端一日一刷：`CareAlertManualRefreshStore`、`manualRefreshSucceededToday`、成功后藏钮、成功后 skip HTTP；日结果幂等依赖 Go 日缓存（命中不调智能体）。
- 「AI智能分析」在喂养子页**常驻**（请求中除外）；失败 Toast；成功更新列表，**不再**强制「请明日再来」成功 Toast 与藏钮。
- Hub 与喂养子页展示小字：**每日仅支持分析一次**（解释缓存预期）。
- Hub **已开通**卡片展示权益**时效**（复用 catalog `expiresAt` / VIP `expireAt` + `featureRemainingDaysCopy`）。

## Capabilities

### New Capabilities

- （无独立新能力名；行为落在既有 `ai-analysis-page` / `prediction-care-alert` / `growth-trajectory-predict` 增量。）

### Modified Capabilities

- `ai-analysis-page`：Hub 两卡极简门闸 + 子路由工作台；已开通时效；喂养「每日一次」文案；成长业务迁出 Hub。
- `prediction-care-alert`：废除客户端上海日成功标记与藏 CTA；仅手动 daily；错误 Toast；依赖服务端日缓存。
- `growth-trajectory-predict`：工作台迁至子页；Hub 仅开通门闸；有效开通后进子页再 HTTP/SSE。

## Impact

- Flutter：`ai_analysis_screen.dart` 瘦身为 Hub；新建喂养/成长 Screen；`app_router.dart` 增路由；`prediction_care_alert_provider` 去掉 hydrate/store/日限 skip；可删 `care_alert_manual_refresh_store.dart`。
- Go / Python：无契约变更（沿用既有 daily 日缓存与成长轨迹 API）。
- 对照基线 `openspec/specs/v2.1.0.md`；未归档能力名沿用 change `ai-analysis-care-alert-relocate` / `growth-trajectory-predict` 中的 `ai-analysis-page`、`prediction-care-alert`、`growth-trajectory-predict`。
- 不自动新建 `**/test/**`。
