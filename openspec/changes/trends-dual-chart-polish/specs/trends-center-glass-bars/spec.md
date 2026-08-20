## ADDED Requirements

### Requirement: 非时间轴图表使用事件色坐标轴线

N-day bar charts and day line charts SHALL draw visible X and Y axis lines using the event accent color.

近 N 日柱图与计时/计数某日折线图 MUST 展示 X 轴与 Y 轴线，其颜色 MUST 为当前事件 accent；本要求不适用于计次时间轴图。

#### Scenario: 柱图轴线

- **WHEN** 近 N 日柱图可见
- **THEN** 用户 MUST 能看到事件色的横纵轴线

#### Scenario: 折图轴线

- **WHEN** 计时或计数某日折线图可见（含空坐标态）
- **THEN** 用户 MUST 能看到事件色的横纵轴线

### Requirement: 折线空态为空白坐标域

When a timing/count day chart has no records, the system SHALL show an empty line chart frame with x domain 0–24 hours and y domain 0–10, and MUST NOT draw a default or ghost polyline.

计时/计数某日无数据时，MUST 渲染空折线坐标系：横轴覆盖 0–24 时，纵轴默认 0–10；MUST NOT 绘制幽灵/默认折线或示意折线。

#### Scenario: 今日无数据空坐标

- **WHEN** 选中计时或计数事件且选中日无记录
- **THEN** 下图 MUST 为无折线的坐标框，且 Y 上界表现为 10 量级

### Requirement: 折线仅连接真实非零点

Day line charts SHALL only place spots for hours with positive metric values and MUST NOT hard-connect across zero-filled gaps as if they were real samples.

某日折线 MUST 只对量值大于 0 的小时（或真实样本）落点连线；MUST NOT 因补零桶把无发生时段硬连成折线。连续非零可连成一段；中间空洞 MUST 断开。

#### Scenario: 间断发生

- **WHEN** 某日仅在 8 时与 18 时有非零量、中间小时为 0
- **THEN** 折线 MUST NOT 经 y=0 把 8 时与 18 时连成一条穿过地面的折线（应断开或仅两点各自成段/按实现拆段）
