## ADDED Requirements

### Requirement: 喂养今日 chip MUST NOT 打开小时趋势 Sheet

While the feeding home shows today-summary chips for display, tapping those chips MUST NOT open `showHomeEventHourlyTrendSheet` (or equivalent today/yesterday hourly trend sheet) solely from that tap. Other trend entries (e.g. immersive header Trends → `/trends`) MAY remain.

喂养主页展示今日汇总 chip 时，点击这些 chip **不得** 仅因此打开 `showHomeEventHourlyTrendSheet`（或等价今昨小时趋势 Sheet）。其它趋势入口（如沉浸头趋势 → `/trends`）MAY 保留。

#### Scenario: 点击今日 chip 不打开 Sheet

- **WHEN** 用户点击喂养页今日汇总区中某一事件 chip
- **THEN** 客户端 MUST NOT 弹出今昨小时趋势玻璃态 Sheet
