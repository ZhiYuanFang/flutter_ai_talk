## Why

某日折线因「按零拆段」导致稀疏非零点变成单点段、线画不出来；计次时间轴刻度色偏白、背景偏深、近距时刻重叠。需要按验收反馈修正连线语义，并补折线选中竖线与时间轴可读性。

## What Changes

- **FIX**：计时/计数某日折线将所有非零小时点放入**同一条**折线连接（跨时间空隙斜连，不经 y=0）；MUST NOT 再按零值拆成仅含单点的多段以致无连线。
- 折线支持触控选中：展示选中竖线，并显示该点具体时间（及量标，若已有则保留）。
- 计次时间轴：轴线/刻度线改用事件 accent；四段背景整体变浅；发生点按时刻排序后时刻标注奇偶交替上下（先下后上），减轻近距重叠。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `trends-center-glass-bars`：折线连线规则修正；折线选中竖线与时间展示。
- `trends-count-day-timeline`：轴色事件色、背景变浅、时刻上下交替。

## Impact

- **Flutter**：主要 `trend_day_detail_chart.dart`（折线 + `_CountTimelinePainter`）。
- **测试**：不新建 `**/test/**`；不改 `app/android/**`。
