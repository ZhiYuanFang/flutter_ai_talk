## MODIFIED Requirements

### Requirement: Prediction recall last-time picker SHALL use glass date/time atoms

When the user picks the last occurrence/end time during prediction recall onboarding, the client MUST present a **single** glass adaptive bottom sheet (same family as add-event / history time sheets). The sheet MUST default to clock-time wheels (hour and minute). The top-left control MUST show the current time of day and, when activated, MUST switch the middle wheels to calendar-date mode (and MUST allow switching back to time). Confirming MUST write a combined `DateTime` not after now. The client MUST NOT require a separate date sheet followed by a separate time sheet, and MUST NOT use the system white `CupertinoDatePicker` modal popup for this path.

量身定做选择上次发生/结束时间时，客户端 **必须** 打开**一层**与添加事件/历史编辑同族的玻璃底部 Sheet；**必须** 默认展示时分滚轮；左上角 **必须** 为当前时分，点按 **必须** 把中部切换为日期滚轮（并 **必须** 能切回时分）；确认 **必须** 写出不晚于当前时刻的完整日期时间。**不得** 再拆成先日期 Sheet 再时分 Sheet，**不得** 走系统白底 `CupertinoDatePicker` popup。

#### Scenario: 打开上次时间选择

- **WHEN** 用户在量身定做卡片点击上次时间入口
- **THEN** UI MUST 打开单层玻璃 Sheet，且 MUST 默认显示时分滚轮
- **AND** MUST NOT 使用系统白底 DatePicker popup
- **AND** MUST NOT 先弹出独立日期 Sheet 再弹出独立时分 Sheet

#### Scenario: 左上角切换日期

- **WHEN** 该 Sheet 处于时分模式且用户点击左上角时分控件
- **THEN** 中部滚轮 MUST 切换为日期选择
- **AND** 用户 MUST 能再切回时分模式

#### Scenario: 确认上次时间

- **WHEN** 用户确认所选日期与时刻
- **THEN** 卡片时间展示 MUST 更新，且所选时刻 MUST NOT 晚于确认时的当前时间
