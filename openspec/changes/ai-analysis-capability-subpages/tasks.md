## 1. 路由与 Hub 骨架

- [x] 1.1 `app_router.dart` 增加 `/prediction/ai-analysis/feeding`、`/prediction/ai-analysis/growth`；Hub 路径保持 `/prediction/ai-analysis`
- [x] 1.2 将 `AiAnalysisScreen` 收为 Hub：两张极简卡；`initState` 仅 eligibility + catalog；去掉 `hydrateManualRefreshFlag` / `ensureLatest`
- [x] 1.3 Hub 喂养卡：未合格进度、合格未开通邀请、已开通整卡进 feeding + 时效 +「每日仅支持分析一次」
- [x] 1.4 Hub 成长卡：未开通邀请、已开通整卡进 growth + 时效

## 2. 喂养工作台与日限清理

- [x] 2.1 新建喂养工作台 Screen：blurb、常驻「AI智能分析」、「每日仅支持分析一次」、列表 → `/prediction/alert`；进页不自动 `daily`
- [x] 2.2 `refreshDailyManual`：去掉「今日已成功 skip HTTP」；成功更新列表（可不成功 Toast）；失败 Toast；保留 single-flight 与「正在思考中」
- [x] 2.3 删除 `CareAlertManualRefreshStore` 及 `manualRefreshSucceededToday` / `hydrateManualRefreshFlag` 全路径引用

## 3. 成长工作台

- [x] 3.1 新建成长工作台 Screen：迁出 `_GrowthTrajectoryCard` 会话 UI（含手动输入等既有行为）
- [x] 3.2 进成长子页再 `ensureLatest`；子页未开通门禁（pop 或就地开通）

## 4. 时效文案

- [x] 4.1 抽取/复用与开通中心一致的时效文案（catalog `expiresAt` / VIP `expireAt` / 永久）并挂到 Hub 已开通两卡

## 5. 验收

- [ ] 5.1 手工：Hub 门闸、已开通进子页、喂养不自动 daily、同日再点可回填缓存、藏钮已移除、时效与「每日一次」文案
- [x] 5.2 `openspec validate ai-analysis-capability-subpages --strict` 通过

## 6. 成长页去卡抛光

- [x] 6.1 去掉玻璃卡与卡内标题；AppBar 标题「成长轨迹」缩小；CTA+用量进 actions
- [x] 6.2 页背景 `pageBg`→`primaryContainer` 渐变；choice 选项改为纵向全宽
