## ADDED Requirements

### Requirement: 计次某日采用时间轴图

For `eventType == one` (count-once) events, the selected-day detail chart SHALL be a 0–24 hour occurrence timeline without a numeric Y axis.

当当前事件 `eventType` 为 `one` 时，某日详图 MUST 渲染 **0–24 小时时间轴图**，MUST NOT 使用数值 Y 轴，MUST NOT 使用折线图或无标注的纯散点图作为主表达。

#### Scenario: 计次打开某日详图

- **WHEN** 用户选中计次事件且某日详图可见
- **THEN** 该区域 MUST 为时间轴表达，且 MUST NOT 显示数值 Y 刻度

### Requirement: 四时段背景与事件色交叉

The count-day timeline SHALL divide the day into four background bands—凌晨、早、午、晚—at 00–06 / 06–12 / 12–18 / 18–24, each tinted by blending a band base color with the event accent.

时间轴背景 MUST 分为四段：**凌晨 00:00–06:00、早 06:00–12:00、午 12:00–18:00、晚 18:00–24:00**；各段底色 MUST 与当前事件 accent **交叉渲染**（混合或叠色），使时段可辨且仍带事件品牌感。

#### Scenario: 四段可见

- **WHEN** 计次某日时间轴渲染完成
- **THEN** 用户 MUST 能区分凌晨/早/午/晚四块背景，且色调与事件 accent 相关

### Requirement: 发生点下伸细线与时刻

Each occurrence on the count-day timeline SHALL render a marker on the time axis, a short thin leader line extending below the marker, and the concrete `HH:mm` time below that line.

每条发生记录 MUST 在对应时刻位置绘制发生点；点下方 MUST 延伸一条短细线；细线下方 MUST 显示该发生的具体时间（`HH:mm`）。

#### Scenario: 单次发生标注

- **WHEN** 选中日存在一条计次发生记录于本地 08:30
- **THEN** 时间轴在约 08:30 处 MUST 有发生点、点下细线，以及文案 `08:30`

#### Scenario: 多次发生

- **WHEN** 选中日存在多条计次发生
- **THEN** 每条 MUST 各自具备点、下伸细线与时刻文案
