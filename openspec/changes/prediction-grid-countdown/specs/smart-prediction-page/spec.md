## ADDED Requirements

### Requirement: Grid layout SHALL show an HH:MM:SS countdown to nextAt instead of a line chart

In grid layout, when forecast is enabled and a prediction exists, the event card main area SHALL display a countdown to `nextAt` formatted as hours:minutes:seconds (hours MAY exceed 24; minutes and seconds MUST be two-digit zero-padded). The client MUST NOT show a lookback line chart in grid layout. While not overdue, the card MUST NOT show the short relative-time line (e.g.「x 小时后」). The countdown MUST refresh at least every second while the page is visible.

网格布局下，推演开启且可预测时，事件卡主区 **必须** 展示指向 `nextAt` 的时:分:秒倒计时（小时可超过 24；分/秒两位补零）；**不得** 再展示回顾折线；未超时时 **不得** 展示「x 小时后」类短相对时间行；页面可见时倒计时 **必须** 至少每秒刷新。

#### Scenario: 未超时仅倒计时

- **WHEN** 布局为网格、推演开启、事件 A 可预测且 `nextAt` 晚于当前时刻
- **THEN** 卡片主区 MUST 显示递减的 `H:MM:SS`（或等价三节）倒计时
- **AND** MUST NOT 展示折线图
- **AND** MUST NOT 展示未超时短相对时间行（如「2 小时后」）

#### Scenario: 超时停表并提示

- **WHEN** 布局为网格、推演开启、事件 A 可预测且已逾期
- **THEN** 倒计时显示 MUST 为 `00:00:00`（不得继续负向或正计时走表）
- **AND** MUST 展示「超时 …」类短文案（如「超时 12 分钟」）

#### Scenario: 列表不受影响

- **WHEN** 布局为纵向列表且事件 A 可预测
- **THEN** 卡片 MUST 仍展示近 7 日折线与既有相对时间规则
- **AND** MUST NOT 被要求改为网格倒计时主区

## REMOVED Requirements

### Requirement: Grid layout SHALL use three calendar days without Y-axis and short relative copy

**Reason**: 网格主区改为倒计时，不再展示三日折线；未超时短相对时间改由倒计时承担，仅超时保留「超时 …」文案。  
**Migration**: 以本 change「Grid layout SHALL show an HH:MM:SS countdown…」为准；列表布局规则不变。
