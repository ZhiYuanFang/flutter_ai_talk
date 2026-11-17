## ADDED Requirements

### Requirement: Predict post-mutation pipeline MAY be scheduled from prediction pull refresh

In addition to scheduling after history CRUD mutations, the client MAY and, when required by `smart-prediction-page` pull-refresh accuracy alignment, MUST enqueue `schedulePredictPostHistoryMutation` (or equivalent) after a successful prediction-page rolling-history pull refresh. The pipeline MUST retain existing single-flight, dirty/epoch, expect-batch circuit-breaker, and resume-cursor behavior. The pull-refresh caller MUST NOT treat a full successful expect-batch round-trip as a precondition for completing the RefreshIndicator.

预测页下拉成功后 MUST 可按页需求入队既有静默管线；single-flight/熔断/resume 不变；下拉指示器 MUST NOT 以整趟 batch 成功为结束条件。

#### Scenario: Pull enqueue does not block indicator on batch

- **WHEN** 预测下拉成功并调度静默管线
- **THEN** RefreshIndicator 可在入队（及滚动历史 await）后结束
- **AND** expect-batch MAY 在后台继续
