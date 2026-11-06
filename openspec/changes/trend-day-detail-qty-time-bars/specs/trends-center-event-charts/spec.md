## MODIFIED Requirements

### Requirement: Selected-day detail chart by event type

The selected-day detail region SHALL show a sparse bar chart for `time`/`number` events (one bar per positive sample, each labeled with local `HH:mm`), and SHALL show the count-day timeline for `one` events (see `trends-count-day-timeline`).

某日详图：`time`/`number` MUST 展示**稀疏柱图**（仅有有效样本处出柱；每柱 MUST 标注该样本本地时刻 **`HH:mm`**；X 轴 MUST NOT 强制固定 24 整点桶）；`one` MUST 展示计次时间轴（`trends-count-day-timeline`）。该区域允许柱图/时间轴。

#### Scenario: Timing or quantity day bars

- **WHEN** 选中计时或计数（量）事件且选中日有至少一条有效样本
- **THEN** 某日详图 MUST 为柱图，柱数 MUST 等于有效样本数（无数据的小时 MUST NOT 单独出柱），且每柱附近 MUST 可见精确到分的时间文案

#### Scenario: Count-once day timeline

- **WHEN** 选中计次事件且选中日有数据
- **THEN** 某日详图 MUST 为时间轴图（非折线、非量/时柱图）

### Requirement: Bar chart metric semantics unchanged

The system SHALL preserve metric semantics: duration hours when `eventNumber == 0`, otherwise the numeric event value.

量值语义 MUST 保持：`eventNumber == 0` 为持续小时；否则为数值量。界面 MUST NOT 额外展示“纵轴含义说明”文案。

#### Scenario: Timer event volume

- **WHEN** 选中事件为计时类（`eventNumber == 0`）
- **THEN** 近 N 日柱高与计时某日柱高 MUST 仍基于时段小时

### Requirement: 非时间轴图表使用事件色坐标轴线

N-day bar charts and day quantity/timing bar charts SHALL draw visible X and Y axis lines using the event accent color.

近 N 日柱图与计时/计量某日柱图 MUST 展示 X 轴与 Y 轴线，其颜色 MUST 为当前事件 accent；本要求不适用于计次时间轴图。

#### Scenario: 柱图轴线

- **WHEN** 近 N 日柱图可见
- **THEN** 用户 MUST 能看到事件色的横纵轴线

#### Scenario: 某日量/时柱图轴线

- **WHEN** 计时或计量某日稀疏柱图可见（含空坐标态）
- **THEN** 用户 MUST 能看到事件色的横纵轴线

### Requirement: 折线空态为空白坐标域

When a timing/quantity day chart has no records, the system SHALL show an empty chart frame without bars (Y domain MAY default around 0–10), and MUST NOT draw a ghost polyline or twenty-four zero-height hour bars.

计时/计量某日无数据时，MUST 渲染空坐标系且 MUST NOT 绘制柱、幽灵折线或 24 根零高整点柱。

#### Scenario: 今日无数据空坐标

- **WHEN** 选中计时或计量事件且选中日无记录
- **THEN** 下图 MUST 为无柱的坐标框（Y 上界可表现为 10 量级）

## REMOVED Requirements

### Requirement: 折线仅连接真实非零点

**Reason**: 量/时某日详图改为稀疏柱，不再使用折线连点。

**Migration**: 以「有数据才出柱」替代；勿再验收折线段/断点行为。

### Requirement: 某日折线以单线连接全部非零点

**Reason**: 同上，折线形态废弃。

**Migration**: 见稀疏柱 Requirement；多点各自成柱。

### Requirement: 折线选中竖线与具体时间

**Reason**: 量/时改为柱图；时间改由柱上 `HH:mm` 标注，不再依赖折线选中竖线。

**Migration**: 柱标承担具体时间展示；可选后续再加柱选中态（非本变更必做）。
