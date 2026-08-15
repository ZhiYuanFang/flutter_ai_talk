## Why

智能预测事件卡依赖本地近 7 日 range 历史（及喂养 `homeHistory` 的进行中计时）推算；App 回前台时目前不重拉这些快照，用户须进喂养页手动刷新后预测才准。需要在已登录唤醒时一次性刷新喂养历史与预测 range（方案 B）。

## What Changes

- App 从后台回到前台且已登录时：**MUST** 触发喂养历史刷新（`homeHistory` bootstrap / 等价拉新）与预测 range `ensureLoaded(force: true)`（或等价 force 重拉）。
- 遵守副作用 HTTP 治理：single-flight、失败熔断、成功幂等/短窗去重，避免连切后台狂打。
- 不改变「预测仍由本地历史推演」的模型；不新增预测专用服务端 API。
- 不因本变更在 gave-up 态自动重试历史 WS（既有 WS resume 规则保持）。

## Capabilities

### New Capabilities

- `prediction-history-resume-refresh`：已登录 App resume 时刷新喂养历史与预测 7 日 range，使预测页无需先手动刷喂养页。

### Modified Capabilities

- （无）基线未收录「resume 拉预测历史」要求。

## Impact

- 代码：`home_screen.dart` 的 `_onAppLifecycleResumed`（或集中 resume 编排）；`homeHistory` bootstrap；`predictionRangeHistoryProvider.ensureLoaded(force: true)`。
- 对照 `openspec/project.md` 副作用 HTTP 条款。
- 测试：不新建 `**/test/**`；手工杀后台再进 / 仅预测页停留再回前台验收。
