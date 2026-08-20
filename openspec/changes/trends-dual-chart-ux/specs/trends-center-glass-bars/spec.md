## MODIFIED Requirements

### Requirement: Trends center chart area uses glassmorphism

The system SHALL render the trends center chart area as an immersive near-fullscreen glass panel without a page app bar, hosting the dual-chart layout.

趋势中心主图表区 MUST 使用沉浸式近全屏玻璃布局，页面 MUST 移除顶部 AppBar；玻璃容器仍须保持磨砂、事件色渐变、浅色前景字，与 `HistoryEditGlassPanel` 视觉一致；其内 MUST 承载双图布局（见 `trends-dual-chart-layout`）。

#### Scenario: View trends with selected event

- **WHEN** 用户已选事件且序列加载完成
- **THEN** 系统 MUST 在沉浸式玻璃主视图中展示双图，且 MUST NOT 使用独立顶部标题栏分割图表区

#### Scenario: Loading

- **WHEN** 序列加载中
- **THEN** 系统 MUST 在图表占位区显示加载指示，且玻璃容器结构仍可见

### Requirement: Trends center N-day overview is a bar chart with Y axis

The N-day overview SHALL display a bar chart with a visible Y axis limited to three ticks; bar top value labels MUST appear only on the selected bar.

近 N 日总量图 MUST 以量柱表达各自然日总量，MUST 展示 Y 轴且 Y 刻度数量 MUST 为 **3**。柱顶量标（含事件单位：计时为时分、计数为 `unit`、计次为「次」）MUST **仅在选中柱**上显示。计时/计数事件 MUST NOT 在柱内绘制散点。

#### Scenario: Series with data

- **WHEN** 近 N 日序列含至少一个非零桶
- **THEN** 用户 MUST 看到柱图与 3 档 Y 轴刻度

#### Scenario: Top label only on selected bar

- **WHEN** 用户选中某一日柱且该日有量
- **THEN** 仅该柱顶部 MUST 显示量+单位文案，其它柱 MUST NOT 显示柱顶量标

### Requirement: Count events embed occurrence dots inside N-day bars

For `eventType == one`, each N-day bar SHALL optionally embed darker circular markers whose vertical position maps the occurrence’s time-of-day onto the bar’s physical height as a 24-hour scale.

当事件为计次（`one`）时，近 N 日图 MUST 在柱内展示发生散点：将柱的物理高度视为 24 小时，按发生时刻比例落点；散点 MUST 为颜色较深的圆。非计次事件 MUST NOT 绘制此类柱内散点。

#### Scenario: Count bar with occurrences

- **WHEN** 计次事件某日有至少一次发生且该日柱可见
- **THEN** 该柱内 MUST 出现对应散点，其相对柱底高度反映发生时刻在一日中的比例

### Requirement: Selected-day detail chart by event type

The selected-day detail region SHALL show a line chart with value labels for `time`/`number` events, and SHALL show the count-day timeline for `one` events (see `trends-count-day-timeline`).

某日详图：`time`/`number` MUST 展示折线图，并在折点上/下（避免遮挡折线）显示量带单位；`one` MUST 展示计次时间轴（`trends-count-day-timeline`）。该区域允许折线/时间轴，不再适用「全页仅柱图」禁令。

#### Scenario: Timing or count day line

- **WHEN** 选中计时或计数事件且选中日有数据
- **THEN** 某日详图 MUST 为折线且折点附近 MUST 有量+单位标注

#### Scenario: Count-once day timeline

- **WHEN** 选中计次事件且选中日有数据
- **THEN** 某日详图 MUST 为时间轴图（非折线）

### Requirement: Bar chart metric semantics unchanged

The system SHALL preserve metric semantics: duration hours when `eventNumber == 0`, otherwise the numeric event value.

量值语义 MUST 保持：`eventNumber == 0` 为持续小时；否则为数值量。界面 MUST NOT 额外展示“纵轴含义说明”文案。

#### Scenario: Timer event volume

- **WHEN** 选中事件为计时类（`eventNumber == 0`）
- **THEN** 近 N 日柱高与计时某日折线量值 MUST 仍基于时段小时

## REMOVED Requirements

### Requirement: Trends center shows bar chart only

**Reason**: 产品改为双图；某日详图需要折线或计次时间轴。

**Migration**: 近 N 日仍以柱图为主；某日详图按 `trends-dual-chart-layout` / `trends-count-day-timeline` 实现。

### Requirement: Selected event shows trend line and bar volume

**Reason**: 与「仅柱图」一并废止；双图分工替代「同屏折线+柱」。

**Migration**: 见双图与按类型详图需求。
