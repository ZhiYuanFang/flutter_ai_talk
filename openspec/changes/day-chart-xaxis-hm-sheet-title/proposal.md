## Why

日内稀疏柱的时刻目前靠柱顶 tooltip，读轴不自然；喂养按日 Sheet 把事件名与日期拆成两行，占高且割裂。需要：时刻上 X 轴；**量值留在柱顶**；Sheet 标题改为一行「事件名 · 日文案」。

## What Changes

- 量/时某日稀疏柱：每柱本地 **`HH:mm` MUST 在 X 轴（bottomTitles）**；**不得**再以柱顶展示时刻。
- 每柱柱顶 MUST 展示该样本**量值**文案（与趋势度量格式一致，如 `formatTrendMetricLabel`：时长/用量等）。
- X 轴仍 MUST NOT 强制 24 整点桶；一样本一柱不变。
- 喂养按日汇总 Sheet：标题区 MUST 为居中一行 **`{事件名} · {日文案}`**，日文案更小、与事件名垂直居中；日文案仍用 `formatHistoryDaySectionLabel`。
- 趋势中心某日详图随组件共用柱图改动；趋势页自有标题行本变更 **不改**。
- 不新建 `**/test/**`。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `trends-center-event-charts`：X 轴 `HH:mm`；柱顶为量值。
- `home-per-day-summary-sticky`：Sheet 标题「事件名 · 日」；柱图验收对齐 X 轴时刻 + 柱顶量。

## Impact

- 代码：`trend_day_detail_chart.dart`（`_DaySparseBarChart`）；`home_day_summary_chart_sheet.dart`（标题）。
- 规格：上述 delta；对照 `openspec/specs/v2.1.4.md` 与未归档的 `trend-day-detail-qty-time-bars`。
- 无 HTTP / 无原生。
