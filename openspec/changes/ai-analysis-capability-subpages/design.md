## Context

当前 `/prediction/ai-analysis`（`AiAnalysisScreen`）纵向嵌套喂养记录分析与成长轨迹完整业务，单文件过重。Go `CareAlertDaily` 已按上海日缓存：命中直接返回、不调 Python；Flutter 另用 prefs「今日已刷」藏钮并 skip HTTP，与缓存语义重复且阻碍冷启动回填。探索定稿：Hub = 资格拦截门 + 极简入口；业务下沉子页。

对照基线 `openspec/specs/v2.1.0.md`；能力名沿用既有 change 中的 `ai-analysis-page`、`prediction-care-alert`、`growth-trajectory-predict`。

## Goals / Non-Goals

**Goals:**

- Hub 仅资格/开通门闸；已开通极简卡可进子页，并展示权益时效。
- 喂养/成长业务在独立 Screen 完成。
- 喂养仅手动 `daily`；去掉客户端一日一刷；Hub+子页「每日仅支持分析一次」文案。
- 成长 Hub 不 `ensureLatest`；进子页再拉。

**Non-Goals:**

- 不改 Go daily 缓存契约，不新增 force 强刷产品入口。
- 不改成长轨迹 SSE/日限/问答规则（含手动输入）。
- 不改预测页「AI分析」入口位置；不新建 `**/test/**`。

## Decisions

### D1. 路由

| 路径 | 职责 |
|------|------|
| `/prediction/ai-analysis` | Hub |
| `/prediction/ai-analysis/feeding` | 喂养工作台 |
| `/prediction/ai-analysis/growth` | 成长工作台 |
| `/prediction/alert` | 单条留意详情（不变） |

深链进子页时：若未开通，子页 MUST 门禁（pop 回 Hub 或就地开通），不得裸跑业务。

### D2. Hub 卡片态

- **喂养**：未合格 → 进度/去喂养；合格未开通 → 邀请弹框；已开通 → 整卡进 feeding，展示时效 +「每日仅支持分析一次」。
- **成长**：未开通 → 邀请弹框；已开通 → 整卡进 growth，展示时效。
- Hub `initState`：eligibility + catalog；**不得** `hydrateManualRefreshFlag` / `fetchDaily` / `ensureLatest`。

### D3. 时效文案

复用开通中心逻辑：`item.unlocked && expiresAt > 0` → `featureRemainingDaysCopy`；VIP 合成开通用 VIP `expireAt`；`expiresAt==0` 且功能开通 →「永久」。格式默认「剩余 N 天」。

### D4. 喂养刷新

删除 `CareAlertManualRefreshStore` 与 `manualRefreshSucceededToday` 相关路径。`refreshDailyManual` 每次用户点击可请求（single-flight 仍保留）。成功：更新列表，可不弹「请明日再来」。失败：Toast（优先业务 `message`）。UI 请求中显示「正在思考中」，CTA 防连点。

### D5. 文件拆分

- `ai_analysis_screen.dart`：Hub + 门闸弹框复用。
- `feeding_analysis_screen.dart`（名可微调）：喂养工作台。
- `growth_trajectory_screen.dart`：从现有 `_GrowthTrajectoryCard` 迁出。
- Provider 继续全局共享，不按路由新建 store。

### D6. 备选（未采纳）

- Hub 带摘要（B）：增加预取压力，违背「Hub 不跑业务」。
- 保留客户端藏钮：与 Go 缓存冲突，冷启动差。

## Risks / Trade-offs

- [同日多次点击仍发 HTTP] → Go 缓存快回；文案说明「每日一次」；single-flight 防并发。
- [深链未开通进子页] → 子页校验 `isFeatureEffectivelyUnlocked`（喂养另加 eligibility）。
- [成长中途返回 Hub] → provider 保会话；本期不强制取消 SSE（可后续加）。

## Migration Plan

纯客户端；发版即切。无数据迁移。回滚：恢复页内嵌业务与 store（git revert）。

## Open Questions

- （无阻塞）成功弱提示是否保留：默认成功静默更新列表。
