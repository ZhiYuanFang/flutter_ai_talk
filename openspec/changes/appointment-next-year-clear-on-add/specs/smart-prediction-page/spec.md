## ADDED Requirements

### Requirement: Appointment hot cards MUST show tappable countdown in portrait and landscape

When a hot appointment root card has forecast enabled and a computable appointment prediction (`nextAt`), the card MUST render a countdown block (caption plus live HMS or overdue copy) in **both** portrait compact waterfall layout and landscape layout. Activating that block MUST open the dedicated next-appointment sheet as specified by `appointment-event-client`. Landscape MUST NOT omit the countdown solely because a lookback chart is shown; if both appear, countdown MUST remain tappable. 热态预约卡在推演开启且有预约预测时，竖屏与横屏 **必须** 均展示可点 countdown 块；横屏 **不得** 因展示折线图而省略该块；点按行为见 `appointment-event-client`。

#### Scenario: Landscape appointment card shows countdown

- **WHEN** 用户在横屏热态查看某预约根且该根有正 `nextAt` 预测
- **THEN** 该卡 MUST 展示与竖屏同语义的倒计时块（文案 + 时刻/逾期）
- **AND** 点按该块 MUST 可打开改约 sheet

#### Scenario: Portrait appointment card keeps countdown

- **WHEN** 用户在竖屏瀑布流查看同卡
- **THEN** 该卡 MUST 继续展示可点 countdown（行为与既有竖屏倒计时展示兼容并增加点按改约）
