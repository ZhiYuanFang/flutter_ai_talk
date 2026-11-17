## ADDED Requirements

### Requirement: Accuracy chart SHALL rebuild from refreshed unified-pool history after pull

When the smart prediction vertical-list accuracy chart is visible and the user successfully completes card-area pull-to-refresh that updates the unified-pool home history (and any subsequent expect fields arriving via the scheduled post-mutation pipeline or WS upsert), the accuracy bars and day summary MUST recompute from that updated in-memory history using the existing eligible-sample rules (`expectStartTime` stored only; no predictor replay). The client MUST NOT keep showing a stale empty/sample/gated-empty chart solely because the widget ignored a history provider update.

下拉成功更新统一池（及随后 expect 对齐写入）后，准确率柱/小结 MUST 按新内存历史重算；MUST NOT 因未监听更新而卡在旧空态。

#### Scenario: Today bar appears after pull brings expect

- **WHEN** 某根今日记录服务端已有 `expectStartTime`，下拉前内存无该字段导致今日无柱
- **AND** 用户下拉成功使统一池带上该 expect（或管线/WS 随后写入）
- **THEN** 该卡准确率图区 MUST 在随后重建中展示含今日合格样本的真柱（若页级门闩适用则按门闩规则）
