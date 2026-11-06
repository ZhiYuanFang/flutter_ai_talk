## Why

某日详图对量（`number`）/时（`time`）现用整日小时折线，空时段占轴、读点也偏「整点感」。产品要求改为柱图：只在有数据处出柱、X 轴不强制 24 小时格、柱上时间精确到分；计次仍时间轴。变更落在共用 `TrendDayDetailChart`（喂养按日 Sheet + 趋势中心某日详图一致）。

## What Changes

- `TrendDayDetailChart` 对 `eventType` 为 `number` / `time`：**柱状图**替代折线；`one` 仍为计次时间轴。
- **仅有数据的样本出柱**（无发生时段不出柱）；X 轴 MUST NOT 再硬编码固定 24 整点桶作为必选域。
- 每根柱 MUST 展示该样本时刻的 **`HH:mm`**（精确到分；通常取记录 `startTime` / 点的 `t`）。
- 空数据：空坐标/骨架，MUST NOT 画幽灵折线或 24 根零柱。
- 喂养按日汇总 Sheet 与趋势某日详图共用该组件行为（方案 B）。
- **BREAKING（相对现网某日折线 UX）**：量/时某日详图形态由折线改为稀疏柱。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `trends-center-event-charts`：某日详图 `time`/`number` 由折线改为有数据才出柱的柱图，柱标 `HH:mm`；空态/轴线相关 Requirement 对齐；移除折线连点/选中竖线条款。
- `trends-center-date-range-ui`：某日详图时域描述改为稀疏柱（计次仍 0–24 轴）。
- `home-per-day-summary-sticky`：按日 Sheet 内量/时展示改为柱图（不再验收「时长折线」）。

## Impact

- UI：`trend_day_detail_chart.dart`（量/时分支）；可复用玻璃柱视觉原子；喂养 `home_day_summary_chart_sheet` 无契约变更仅随组件。
- 数据：仍用本地/piece 的 `TrendPoint` 列表；不再依赖为折线补零的 24 小时桶作为展示主路径。
- 基线对照：`trends-center-event-charts` 中「Selected-day detail chart by event type」等折线条款；`home-per-day-summary-sticky`。
