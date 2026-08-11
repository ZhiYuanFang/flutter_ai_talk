## ADDED Requirements

### Requirement: Prediction recall interval picker SHALL match usage single-wheel glass sheet

When the user picks「大概多久一次」during prediction recall onboarding, the client MUST present a glass adaptive bottom sheet with exactly one scroll wheel for selecting a single interval value, visually aligned with the feeding-usage number picker sheet (glass chrome, sheet text colors, selection overlay). The selectable values MUST remain interval minutes (existing step/range semantics), and MUST NOT reuse the usage milliliter value list. Confirming MUST update the onboarding interval state; cancel/dismiss MUST leave the previous interval unchanged.

量身定做选择「大概多久一次」时，客户端 **必须** 展示玻璃自适应底部 Sheet，且 **必须** 仅为单列滚轮单选；视觉 **必须** 与喂养用量单滚轮 Sheet 对齐；可选值 **必须** 仍为间隔分钟语义，**不得** 使用用量 ml 档列表；确认 **必须** 写回间隔状态，取消/关闭 **必须** 保持原值。

#### Scenario: 打开间隔选择

- **WHEN** 用户在量身定做卡片点击「大概多久一次」
- **THEN** UI MUST 打开玻璃单滚轮 Sheet（非系统白底 `CupertinoModalPopup` 间隔轮）

#### Scenario: 确认间隔

- **WHEN** 用户在该 Sheet 选中某间隔并确认
- **THEN** 卡片展示的间隔文案 MUST 更新为所选值

### Requirement: Prediction recall last-time picker SHALL use glass date/time atoms

When the user picks the last occurrence/end time during prediction recall onboarding, the client MUST use the same glass picker family as the add-event / history time flow (glass adaptive sheets), and MUST allow selecting both calendar day and clock time with a result not after now. The client MUST NOT use the system white `CupertinoDatePicker` modal popup for this path.

量身定做选择上次发生/结束时间时，客户端 **必须** 使用与添加事件/历史编辑同族的玻璃选择器，**必须** 能选出日期与时刻且结果不晚于当前时刻；**不得** 再走系统白底 `CupertinoDatePicker` popup。

#### Scenario: 打开上次时间选择

- **WHEN** 用户在量身定做卡片点击上次时间入口
- **THEN** UI MUST 打开玻璃日期和/或时分选择（同族原子），MUST NOT 使用系统白底 DatePicker popup

#### Scenario: 确认上次时间

- **WHEN** 用户确认所选日期与时刻
- **THEN** 卡片时间展示 MUST 更新，且所选时刻 MUST NOT 晚于确认时的当前时间
