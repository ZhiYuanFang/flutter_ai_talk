## ADDED Requirements

### Requirement: Feeding grid add for time and one SHALL go through the record sheet

When the feeding home event grid (or shared `handleEventGridTap` path) performs `EventRecordIntent.add` for catalog leaves with `eventType` `time` or `one`, the client MUST collect start/end/remark (and timing semantics) via the unified event-record sheet before calling the history add API. The client MUST NOT construct a silent now payload for those types solely from the grid tap. 喂养格（及共享加事件路径）对 `time`/`one` 的普通新增 MUST 经统一记录 sheet 再调 add；MUST NOT 仅因点格静默构造 now 载荷。

#### Scenario: Grid tap time not silent start

- **WHEN** 喂养页事件格点 `time` 且未在计时中
- **THEN** 客户端 MUST 先展示统一记录 sheet；用户取消时 MUST NOT 调用 add

#### Scenario: Grid tap one not silent now

- **WHEN** 喂养页事件格点 `one`
- **THEN** 客户端 MUST 先展示统一记录 sheet；用户确认后 MUST 再按 one 映射提交
