## ADDED Requirements

### Requirement: Grid card SHALL show active-timing chrome instead of nextAt countdown

When the smart prediction page is in grid/waterfall（compact）layout and the event for a card has an active timing history record (`eventNumber == 0` and end unset per existing `isActiveTimingRecord` rules), the card MUST NOT show the `nextAt` countdown main area or the large logo above that countdown. The card SHALL show: event logo to the left of the event name; elapsed active duration in the card body using the same formatting rules as feeding active timing (`MM:SS` under one hour, `HH:MM:SS` at one hour or more); a bottom Stop control that ends the timing session via the existing history update API without a confirmation dialog; and MUST keep the forecast（推演）toggle on the title row. Elapsed display MUST refresh at least every second while visible. Vertical list（non-compact）cards are out of scope for this requirement.

智能预测页处于网格/瀑布流（compact）布局且该卡事件存在进行中计时历史时，卡片 **不得** 展示指向 `nextAt` 的倒计时主区及其上方大图；**必须** 在事件名左侧展示事件图标，在卡身展示已计时长（格式与喂养进行中计时一致），在底部提供「停止」且经既有历史更新接口结束计时、**不得** 二次确认；标题行 **必须** 仍保留推演开关；可见时已计时长 **必须** 至少每秒刷新。纵向列表（非 compact）卡不在本要求范围内。

#### Scenario: 计时中网格卡布局

- **WHEN** 布局为网格且事件 A 存在进行中计时记录
- **THEN** 卡片 MUST 在事件名左侧显示事件 logo
- **AND** 卡身 MUST 显示递增的已计时长（非 `nextAt` 倒计时）
- **AND** 底部 MUST 有「停止」控件
- **AND** 标题行 MUST 仍显示推演开关
- **AND** MUST NOT 展示 `nextAt` 倒计时主区或倒计时上方大图

#### Scenario: 停止结束计时

- **WHEN** 用户在网格计时中卡片点击「停止」且更新成功
- **THEN** 该历史记录 MUST 变为已结束
- **AND** 该卡片 MUST 退出计时中 chrome（恢复适用的非计时网格展示）

#### Scenario: 列表态不变

- **WHEN** 布局为纵向列表且事件 A 存在进行中计时
- **THEN** 本 Requirement MUST NOT 要求列表卡改为网格计时中 chrome

## MODIFIED Requirements

### Requirement: Grid layout SHALL show an HH:MM:SS countdown to nextAt instead of a line chart

In grid layout, when forecast is enabled and a prediction exists **and the event does not have an active timing history record**, the event card main area SHALL display a countdown to `nextAt` formatted as hours:minutes:seconds (hours MAY exceed 24; minutes and seconds MUST be two-digit zero-padded). The client MUST NOT show a lookback line chart in grid layout. While not overdue, the card MUST NOT show the short relative-time line (e.g.「x 小时后」). The countdown MUST refresh at least every second while the page is visible. When an active timing record exists for the event, the active-timing chrome requirement applies instead.

网格布局下，推演开启、可预测、**且该事件无进行中计时历史**时，事件卡主区 **必须** 展示指向 `nextAt` 的时:分:秒倒计时（小时可超过 24；分/秒两位补零）；**不得** 再展示回顾折线；未超时时 **不得** 展示「x 小时后」类短相对时间行；页面可见时倒计时 **必须** 至少每秒刷新。当该事件存在进行中计时时，改适用「计时中 chrome」要求。

#### Scenario: 未超时仅倒计时

- **WHEN** 布局为网格、推演开启、事件 A 可预测、`nextAt` 晚于当前时刻、且 A **无**进行中计时
- **THEN** 卡片主区 MUST 显示递减的 `H:MM:SS`（或等价三节）倒计时
- **AND** MUST NOT 展示折线图
- **AND** MUST NOT 展示未超时短相对时间行（如「2 小时后」）

#### Scenario: 超时停表并提示

- **WHEN** 布局为网格、推演开启、事件 A 可预测、已逾期、且 A **无**进行中计时
- **THEN** 倒计时显示 MUST 为 `00:00:00`（不得继续负向或正计时走表）
- **AND** MUST 展示「超时 …」类短文案（如「超时 12 分钟」）

#### Scenario: 列表不受影响

- **WHEN** 布局为纵向列表且事件 A 可预测
- **THEN** 卡片 MUST 仍展示近 7 日折线与既有相对时间规则
- **AND** MUST NOT 被要求改为网格倒计时主区
