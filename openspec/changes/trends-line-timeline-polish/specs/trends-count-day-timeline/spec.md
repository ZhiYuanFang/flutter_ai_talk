## ADDED Requirements

### Requirement: 时间轴轴线使用事件色

Count-day timeline axis and tick marks SHALL use the event accent color.

计次时间轴的底轴与小时刻度短线 MUST 使用当前事件 accent（可半透明），MUST NOT 使用与事件无关的固定白灰作为主轴色。

#### Scenario: 轴色随事件

- **WHEN** 用户查看计次某日时间轴
- **THEN** 轴线视觉 MUST 与事件 accent 一致

### Requirement: 四段背景整体变浅

The four day-part background bands SHALL be rendered lighter so markers and time labels remain readable.

四时段背景填充 MUST 整体浅于现网偏深表现（降低不透明度或提高与浅色的混合），在可区分时段的前提下 MUST NOT 压过发生点与时刻文案。

#### Scenario: 背景可读

- **WHEN** 时间轴带有发生点与 `HH:mm`
- **THEN** 背景带 MUST 明显浅于先前深底，且时刻文案仍清晰

### Requirement: 近距时刻上下交替标注

Occurrence time labels SHALL alternate below and above the marker by sorted index (even: below first, odd: above) to reduce overlap when points are close.

发生点按时刻排序后，时刻标注 MUST 按序号奇偶交替：偶数先下、奇数再上，以此类推；细线长度 MUST 保持短段。本规则按序号交替，不要求像素距离检测。

#### Scenario: 相邻两点

- **WHEN** 选中日有两条接近的发生记录
- **THEN** 靠前一条的时刻 MUST 在点下方区域，后一条 MUST 在点上方区域（或按 0/1 序号对应下/上）
