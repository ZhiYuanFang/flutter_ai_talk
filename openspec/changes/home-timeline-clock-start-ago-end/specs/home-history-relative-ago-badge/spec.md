## ADDED Requirements

### Requirement: 相对时间标签锚 MUST 保持 historyHomeDisplayInstant

The relative-time badge (「{h}时{m}分前」) and the per-event「newest row」selection SHALL continue to use `historyHomeDisplayInstant` (finished `eventNumber == 0` timing remains the **end** instant). The client MUST NOT re-anchor that badge or selection to the left-column start clock alone. 相对时间标签与「各事件最新行」选取 MUST 继续使用 `historyHomeDisplayInstant`（已结束计时仍为结束时刻）；MUST NOT 仅因左列改为开始时刻而把 ago 改锚到 start。

#### Scenario: 长睡醒后 ago 相对结束

- **WHEN** 一条已结束计时 `startTime` 约 9 小时前、`endTime` 约 3 分钟前，且该行按 `historyHomeDisplayInstant` 为该事件键在列表内最新且非进行中
- **THEN** 该行下方相对时间标签 MUST 反映相对 **结束时刻** 的间隔（量级为分钟级「刚刚 / n分前」），MUST NOT 按开始时刻显示约「9小时前」

#### Scenario: 左列改 start 不影响最新判定函数

- **WHEN** 同事件键存在多条已结束计时，结束时刻不同、开始时刻排序与结束时刻排序不一致
- **THEN** 哪一行展示相对时间标签 MUST 仍由各行 `historyHomeDisplayInstant` 比较决定，MUST NOT 改用左列开始时刻比较
