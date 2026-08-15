## ADDED Requirements

### Requirement: Logged-in app resume SHALL refresh feeding history and prediction range

当 App 从后台回到前台且用户已登录时，客户端 MUST 触发喂养历史远程刷新（`homeHistory` bootstrap 或文档化等价），并且 MUST 对预测近 7 日 range 执行 force 重拉（`predictionRangeHistory.ensureLoaded(force: true)` 或文档化等价）。未登录时 MUST NOT 因本要求发起上述历史 HTTP。本刷新 MUST 遵守副作用 HTTP 治理（single-flight、失败熔断、短窗去重），MUST NOT 因本要求在历史 WebSocket gave-up 态自动重连。

#### Scenario: Resume on prediction page refreshes cards without visiting feeding

- **WHEN** 用户已登录，停留在智能预测页将 App 切到后台再回前台，且服务端历史在离开期间有更新
- **THEN** 客户端 MUST 拉取最新喂养历史与预测 range，使预测事件卡（及进行中计时相关展示）在无需先进入喂养页手动刷新的情况下反映更新

#### Scenario: Logged-out resume skips history HTTP

- **WHEN** 用户未登录且 App resume
- **THEN** 客户端 MUST NOT 因本要求发起喂养历史 bootstrap 或预测 range force 拉取

#### Scenario: Rapid resume is de-duplicated

- **WHEN** 已登录用户在短时间窗内连续触发多次 App resume
- **THEN** 喂养历史与预测 range 的 resume 刷新 MUST 受 short-window 去重或 single-flight 约束，MUST NOT 对每一次 resumed 事件都无合并地打满重复 HTTP
