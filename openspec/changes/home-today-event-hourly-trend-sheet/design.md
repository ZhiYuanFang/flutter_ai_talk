## Context

- **今日 chip**：`HomeTodaySummaryPanel` + `aggregateTodayTotals`（本地自然日、`countsTowardTodayTotal` 排除未结束计时）。
- **趋势中心**：`TrendsScreen` + `RemoteTrendsRepository.loadSeries` → `GET /device/history/api/piece`；`fillTrendBucketsHourlyToday` 仅 0..当前小时，非固定 24 桶；折线+柱图。
- **点语义**：`trendPointFromPieceJson` / `historyRecordMetric` — 计时为小时、计数为次数；分桶按 **startTime 所在整点** 相加（与趋势中心一致，不跨小时拆分）。
- **玻璃 UI**：`HistoryEditGlassPanel` + 固定浅色字色；`showHomeHistoryEditSheet` 透明底 + 限高。
- **后端**：`go_ai_talk` `ListHistoryPiece(deviceNo, eventId, startTime, endTime)` 支持任意 Unix 秒区间。

## Goals / Non-Goals

**Goals:**

- Chip 点击 → 玻璃 Sheet → 今/昨双折线，本地先绘、API 后刷新。
- 固定 24 小时桶；无数据亦为 24 个 0。
- 竖屏 X 5 / Y 3；横屏 X 7 / Y 5（仅轴标签数量，数据仍为 24 点）。
- 未结束计时不计入。

**Non-Goals:**

- 趋势中心 UI/交互改版。
- 柱图、周月季区间。
- MVP 服务端 hourly 预聚合（可后续加）。
- 计时跨小时按分钟摊分到多桶（保持与 piece/趋势中心一致）。

## Decisions

### 1. 数据流（local first → API）

```text
onChipTap(eventId)
  → openSheet
  → localSeries = aggregateFromHistory(items, eventId, today|yesterday)
  → render chart (24 points each, zeros allowed)
  → unawaited apiSeries = loadPieceDualDay(eventId)
  → on success: replace series, setState
```

**API 单次请求**（推荐）：

```text
startTime = yesterday 00:00 local → Unix sec
endTime   = today 23:59:59 local → Unix sec
GET /device/history/api/piece?deviceNo&eventId&startTime&endTime
```

客户端按 `startTime` 本地日拆成两日，再 `fillTrendBucketsHourlyFullDay` 各 24 桶；过滤 `countsTowardTodayTotal`。

### 2. 本地聚合 `aggregateHourlyForEventOnDay`

| 步骤 | 规则 |
|------|------|
| 事件匹配 | `historyRecordEventId` 非空则比 id，否则 `eventName`（与 `aggregateTodayTotals` 一致） |
| 自然日 | `isHistoryRecordOnLocalDay(r, day)`（`createdAt` 本地日） |
| 排除 | `!countsTowardTodayTotal(r)` 时跳过（含进行中计时） |
| 分桶 | `hour = startTime` 的 hour；`value += historyRecordMetric(r)` |
| 输出 | 24 × `TrendPoint(dayStart+h, value)`，缺失为 0 |

新函数建议放在 `trend_series_bucket.dart`：`fillTrendBucketsHourlyFullDay(raw, dayLocal)`。

### 3. 图表（fl_chart）

- `LineChart` 两条 `LineChartBarData`：今日 accent 实线；昨日 accent `alpha≈0.45` 或虚线。
- `minX=0`, `maxX=23`；`minY=0`；`maxY = max(今,昨) * 1.15`，若全 0 则 `maxY=1` 以显示基线。
- **X 标签**（`getTitlesWidget` 仅在这些 index 显示）：
  - Portrait: hours `[0,6,12,18,23]` → `HH:mm`（末格可显示 `24:00` 或 `23:00` 产品统一为 `0:00`…`24:00` 五档）
  - Landscape: `[0,4,8,12,16,20,23]`
- **Y 标签**：portrait 3 档 `[0, maxY/2, maxY]`；landscape 5 档等分。
- 轴与网格线使用 `HistoryEditGlassPanel` 浅色（`glassLabelColor` / white 12–18% alpha）。

### 4. Sheet UI

```text
showModalBottomSheet(backgroundColor: transparent)
  └ SafeArea
       └ Padding
            └ ConstrainedBox(maxHeight: 0.55~0.65 screen)
                 └ HistoryEditGlassPanel(eventAccent, onClose)
                      ├ EventLogo + 事件名
                      ├ 图例：今日 / 昨日
                      ├ Expanded → LineChart
                      └ （API 刷新时 subtle loading）
```

- Chip：`InkWell` on `_TodayChip`，回调 `showHomeEventHourlyTrendSheet(context, total, event)`.

### 5. 后端（go_ai_talk）

| | MVP | 可选后续 |
|--|-----|----------|
| piece 区间查询 | ✓ 已满足 | — |
| 服务端排除进行中 | 客户端过滤 | 查询加 `endTime>0` |
| 预聚合 hourly | ✗ | `GET .../piece/hourly?days=2` |

## Risks / Trade-offs

- **[Risk] 本地分页缺昨日** → API 刷新后替换；可选轻提示「已同步完整数据」。
- **[Risk] piece 返回量大** → 单次 48h 窗口；后续预聚合。
- **[Trade-off] start 小时分桶** → 与趋势中心一致，长计时可能单桶尖峰。

## Migration Plan

- 纯增量 UI + 数据模块；手工：点 chip、竖/横屏轴数、无数据零线、进行中计时不出现在曲线。

## Open Questions

- （默认）Sheet 高度 55% 屏高。
- （默认）昨日线：事件色 45% alpha，图例标注「昨日」。
