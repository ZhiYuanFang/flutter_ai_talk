## MODIFIED Requirements

### Requirement: 喂养今日 chip MUST NOT 打开小时趋势 Sheet

While the feeding home shows per-day summary chips on day sticky headers, tapping those chips MUST NOT open `showHomeEventHourlyTrendSheet` (or equivalent today/yesterday hourly trend sheet) solely from that tap; the tap MUST instead open the single-day `TrendDayDetailChart` sheet defined by `home-per-day-summary-sticky`. Other trend entries (e.g. immersive header Trends → `/trends`) MAY remain.

喂养主页在日期吸顶上展示按日汇总 chip 时，点击这些 chip **不得** 仅因此打开 `showHomeEventHourlyTrendSheet`（或等价今昨小时趋势 Sheet）；该点击 **必须** 打开 `home-per-day-summary-sticky` 所定义的单日 `TrendDayDetailChart` 玻璃 Sheet。其它趋势入口（如沉浸头趋势 → `/trends`）MAY 保留。

#### Scenario: 点击按日 chip 不打开今昨小时 Sheet

- **WHEN** 用户点击喂养页某日吸顶汇总区中某一事件 chip
- **THEN** 客户端 MUST NOT 弹出今昨小时趋势玻璃态 Sheet

#### Scenario: 点击按日 chip 打开单日详图 Sheet

- **WHEN** 用户点击喂养页某日吸顶汇总区中某一事件 chip
- **THEN** 客户端 MUST 弹出内嵌 `TrendDayDetailChart` 的单日玻璃态 Sheet（该日 + 该 `eventId`）
