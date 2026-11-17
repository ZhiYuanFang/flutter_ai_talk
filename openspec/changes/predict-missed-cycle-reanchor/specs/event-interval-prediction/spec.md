## ADDED Requirements

### Requirement: Live nextAt MAY be rewritten by missed-cycle chase after true-lastAt formula

After the client produces a candidate `nextAt` for a non-appointment root via the true-`lastAt` + interval path（including TOD density guard / autoSkip）, **live** consumers MUST apply `predict-missed-cycle-reanchor` when enabled for that call path. The additive base for the initial candidate MUST remain the true latest occurrence；missed-cycle steps MAY then use a predicted tip solely as a virtual affinity/additive anchor without writing history. Expect-anchor-chain callers MUST leave missed-cycle chase disabled.

live 路径在真 lastAt 公式候选后 MUST 可经漏记追赶改写/清空 nextAt；初始加法基 MUST 仍为真发生；expect 锚点链 MUST 关闭追赶。

#### Scenario: live 启用追赶

- **WHEN** `predictNextForEventKey` / `predictAllUpcoming` 用于智能预测、3h 或 Widget
- **THEN** 客户端 MUST 在候选 nextAt 上启用漏记追赶（见 `predict-missed-cycle-reanchor`）
