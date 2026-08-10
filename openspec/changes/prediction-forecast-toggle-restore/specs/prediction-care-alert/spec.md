## ADDED Requirements

### Requirement: Care-alert marquee SHALL exclude forecast-disabled events

When aggregating or presenting care-alert event items for the「值得留意」marquee, the client MUST exclude any event whose forecast toggle is OFF. Turning forecast OFF for an event that was the only marquee item MUST cause the marquee block to hide if no other items remain.

值得留意跑马灯 **必须** 排除推演关闭的事件；若关闭后无剩余项，跑马灯 **必须** 整块隐藏。

#### Scenario: 关闭后移出跑马灯

- **WHEN** 事件 A 在跑马灯中且用户关闭 A 的推演
- **THEN** 跑马灯 MUST NOT 再展示 A
- **AND** 若无其它留意项，整块 MUST 隐藏
