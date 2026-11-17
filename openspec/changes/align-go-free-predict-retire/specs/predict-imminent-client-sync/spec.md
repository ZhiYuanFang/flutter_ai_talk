## ADDED Requirements

### Requirement: Imminent pending sync SHALL use the same affinity nextAt as display

When the client builds the body for `PUT /device/api/predict/imminent/pending`, each event’s `nextAt` MUST come from the single affinity prediction rail that also drives user-visible prediction surfaces. The client MUST NOT maintain a separate seed-forced display rail whose times are withheld from pending, and MUST NOT substitute recall-seed interval nextAt into pending in place of affinity. Existing rules for full-replace sync triggers, empty clear, appointment omission, expect fields, single-flight, and failure cooldown SHALL remain.

imminent pending 的 nextAt MUST 与展示共用单轨亲和结果；MUST NOT 再维护「展示种子 / 上传亲和」双轨分叉；MUST NOT 用种子时刻顶替亲和上传。

#### Scenario: 展示与 pending 同源

- **WHEN** 某根亲和算出 nextAt=T 且发生合格本机变更触发 pending 同步
- **THEN** 预测卡展示的下次时刻 MUST 基于 T（若该根有展示行）
- **AND** pending 中该 event 的 nextAt MUST 为 T

#### Scenario: 无亲和则不上报伪种子

- **WHEN** 某根无亲和 nextAt（仅有回忆种子间隔）且发生合格本机变更
- **THEN** pending MUST NOT 仅为展示进度/种子而上传该根的种子推算 nextAt
- **AND** 若无其它可上报 nextAt 则 MUST 按既有规则空列表或省略该 event
