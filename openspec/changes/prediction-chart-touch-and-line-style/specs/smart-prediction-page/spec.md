## ADDED Requirements

### Requirement: Prediction chart Y-axis SHALL show at most five time labels

For each forecast-enabled chart on the smart prediction page, the left/time-of-day axis SHALL display **at most five**（≤5） time-of-day tick labels (including endpoints when shown). The client MUST derive tick spacing from the visible Y range so the rendered label count never exceeds five; fewer labels are allowed when the range is narrow.

预测页折线 Y 轴时刻刻度 **必须** ≤5 个；窄窗口允许更少。

#### Scenario: 宽窗口不超过五个标签

- **WHEN** 折线 Y 轴可见范围较大
- **THEN** 左侧时刻刻度标签数量 MUST ≤ 5

#### Scenario: 窄窗口可以更少

- **WHEN** 折线 Y 轴可见范围很小
- **THEN** 时刻刻度标签数量 MAY < 5
- **AND** MUST NOT > 5

### Requirement: Prediction chart SHALL show time tooltip above touched spots

When the user touches or presses a plotted data point on the prediction chart, the client SHALL show a floating affordance above that point displaying that point’s concrete local time as `HH:mm` (or equivalent zero-padded hour:minute). The tooltip MUST reflect the underlying chart point time (including today’s `nextAt` when that point is plotted).

用户触碰折线数据点时，**必须**在点上方浮层展示该点具体时间（`HH:mm`）。

#### Scenario: 触碰历史点

- **WHEN** 用户触碰某一过去日数据点
- **THEN** UI MUST 在该点上方展示该点对应的 `HH:mm`

#### Scenario: 触碰今日预测点

- **WHEN** 今日点已绘制为 `nextAt` 且用户触碰该点
- **THEN** 浮层 MUST 展示 `nextAt` 的本地 `HH:mm`

### Requirement: Prediction chart SHALL use solid history segments and a dashed link to today’s nextAt

Connecting segments among past-day chart points（days before today）SHALL be drawn as a **solid** line. When a today point is plotted at `nextAt`, the segment from the chronologically last past-day point to that today point SHALL be drawn as a **dashed** line. If there is no today point, the chart MUST NOT require a dashed prediction segment. If there is only a today point and no past points, the client MAY show the point without a connecting segment.

过去日之间连接 **必须** 为实线；仅「最后过去点 → 今日 nextAt」**必须** 为虚线；无今日点则无该虚线段。

#### Scenario: 有过去点与今日 nextAt

- **WHEN** 折线至少有一个过去日点且今日点为同日 `nextAt`
- **THEN** 过去点之间的连接 MUST 为实线
- **AND** 最后过去点到今日点的连接 MUST 为虚线

#### Scenario: 无今日点

- **WHEN** `nextAt` 不在今天因而无今日点
- **THEN** 折线 MUST 仅为实线历史段（若有点可连）
- **AND** MUST NOT 绘制连向今日的虚线段
