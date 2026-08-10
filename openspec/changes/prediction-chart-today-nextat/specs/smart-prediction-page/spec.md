## MODIFIED Requirements

### Requirement: Seven-day chart SHALL show one TOD-near point per day as dashed line

For each event with forecast ON and a computable prediction, the page SHALL render a chart over calendar days in `[now-6d, now]` explaining the predicted `nextAt` time-of-day.

For each **past** local calendar day in that window (from the start of `now-6d` through **yesterday**), if the day has at least one local occurrence (`occurrenceInstant` ≤ `now`), the client MUST plot **at most one** point—the occurrence whose time-of-day is closest to `nextAt`’s time-of-day (circular minute distance). Past days with no occurrence MUST omit a point.

For **today** (local calendar day of `now`): the client MUST plot a point at `nextAt` **if and only if** `nextAt` falls on that same local calendar day (including when `nextAt` is earlier than `now` on that day). The client MUST NOT choose today’s chart point from already-occurred occurrences. If `nextAt` is on a later local calendar day, today MUST omit a point even if occurrences exist today.

One axis MUST be calendar day; the other MUST be time-of-day. Connecting segments MUST be drawn as a **dashed** line. The chart MUST NOT plot every raw occurrence in the window. Chart value scales MUST accommodate today’s `nextAt` when it is plotted (even if after `now`).

推演开启且可预测时，折线 **必须** 解释 `nextAt` 时刻：过去各日（今日前）每天至多一点（最接近 `nextAt` 时刻的 occurrence）；**今天** 仅当 `nextAt` 落在今天时画点，且点 **必须** 为 `nextAt`，**不得** 用今日已发生记录替代；`nextAt` 不在今天则今日不画点。连接 **必须** 为虚线。

#### Scenario: 过去日每天至多一点

- **WHEN** 事件 A 在同一过去自然日有多次 occurrence，且存在 `nextAt`
- **THEN** 该过去日 MUST 仅贡献一个点（TOD 距 `nextAt` 时刻最近者）

#### Scenario: 今日点为 nextAt

- **WHEN** 事件 A 的 `nextAt` 落在本地今天，且推演开启
- **THEN** 折线今日点 MUST 为 `nextAt`
- **AND** MUST NOT 使用今天已发生的 occurrence 作为今日代表点

#### Scenario: nextAt 不在今天则今日无点

- **WHEN** 事件 A 的 `nextAt` 落在明天或更晚，即使今天已有 occurrence
- **THEN** 折线 MUST NOT 为今天绘制数据点

#### Scenario: 虚线连接

- **WHEN** 至少有两个图表点（含今日 `nextAt` 点与过去日点的组合）
- **THEN** 连接折线 MUST 为虚线样式

#### Scenario: 关闭无折线

- **WHEN** 事件 A 推演关闭
- **THEN** UI MUST NOT 展示 A 的折线图
