## ADDED Requirements

### Requirement: Expect-anchor chain SHALL disable missed-cycle chase

When the silent post-mutation pipeline builds expect patches via the same-bucket previous-tip anchor chain（including after inserting a history row in the middle and recomputing subsequent stamps）, the client MUST invoke interval prediction with missed-cycle chase **disabled**. The chain MUST continue to use only prior real occurrences as tip and MAY still stamp overdue expect* per existing `HistoryExpectStamp.fromPrediction` rules.

锚点链 expect 重算（含中间插入）MUST 关闭漏记追赶；tip MUST 仅为 prior 真发生；过期 expect 打戳按既有语义。

#### Scenario: 中间插入不跑 2h 追赶

- **WHEN** 用户在历史中部插入一条记录并触发静默 expect 重算
- **THEN** 后续行的 predictNext MUST NOT 相对墙钟 now 做漏记 2h/3 步追赶
