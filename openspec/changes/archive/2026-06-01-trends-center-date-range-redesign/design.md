## Context

- **现状**：`TrendsScreen` 使用 `SegmentedButton<TrendRange>`；`RemoteTrendsRepository._rangeBounds` 映射四档；`TrendGlassBarChart` 用 `range == today` 决定按小时分桶；`ChartAxisGranularity` 已用于轴标签。
- **已决策（explore）**：视觉跟主页主题色；起止日期；柱 accent 渐变 + 轻 3D；标题固定「喂养趋势图」；最大跨度 **30 天**；**范围可记忆**。
- **参考图**：仅采纳信息架构（双胶囊 + 大卡标题 + 粗柱），不采纳浅色 pastel 材质。

## Goals / Non-Goals

**Goals:**

- 用户可选起止日期（≤30 天），柱图正确分桶与抽稀轴标签。
- 下次进入趋势中心恢复上次日期范围（与事件选择独立记忆）。
- 顶栏与图表区玻璃风格与 `HistoryEditGlassPanel` / `resolveEventColor` 一致。

**Non-Goals:**

- 任意跨度 >30 天、按周/月/季快捷档（可二期加「本周」快捷填入记忆默认值）。
- 事件选择 Sheet 玻璃化（仍可用现有 Material 列表 Sheet）。
- 修改 piece API 字段含义。

## Decisions

### 1. 日期范围模型

- **类型**：`DateTime` 本地 **date-only**（`DateTime(y,m,d)`），查询时：
  - `startSec` = 开始日 00:00:00 本地 → Unix 秒
  - `endSec` = 结束日 23:59:59 本地 → Unix 秒
- **校验**：`end >= start`；`end.difference(start).inDays + 1 <= 30`（按**日历日数**计，含首尾两日）。
- **超限**：toast 提示，不发起请求、不写入记忆。

### 2. 默认与记忆

- **默认**（无记忆或记忆无效）：**本周一 0:00 至今天**（本地周一起算，`DateTime.monday`）。
- **记忆**：`TrendsDateRangeStore`（`SharedPreferences`）
  - Keys：`trends_range_start_v1`、`trends_range_end_v1`（ISO `yyyy-MM-dd` 或 epoch day）
  - 写入时机：用户通过日期选择器**确认**且校验通过后
  - 读取时机：`TrendsScreen.initState`；若跨度 >30 或 end 在未来则 clamp/回退默认
- **不记忆事件 ID**（本变更仅日期；事件仍用现有 catalog 默认选中逻辑）。

### 3. Repository API

```dart
Future<TrendSeries> loadSeries(
  String eventKey, {
  required DateTime startDate,
  required DateTime endDate,
});
```

- 删除或废弃 `TrendRange` 在趋势路径上的使用；`normalizeTrendSeriesForBounds(raw, startSec, endSec)` 替代 `normalizeTrendSeriesForRange`。
- **分桶**：
  - `startDate == endDate`（同日）→ `fillTrendBucketsHourlyFullDay(day: startDate)` 或仅 0..当前小时（若结束日为今天）——**规格**：结束日为今天且同日时用 `fillTrendBucketsHourlyToday` 截断至当前小时；历史完整自然日用 `fillTrendBucketsHourlyFullDay`。
  - 跨日 → `fillTrendBucketsDaily(startSec, endSec)`。

### 4. UI 顶栏

- 左右两枚 `HistoryEditGlassTapField`（或等效玻璃条），横向 `Row` + `Expanded`。
- **左**：标签「选择事件」、当前事件名、`EventLogo`、`Icons.expand_more`；点击现有事件列表 Sheet。
- **右**：标签「选择时段范围」、文案 `{start} — {end}`（`MM-dd`）、日历图标；点击 `showDateRangePicker`（`firstDate`/`lastDate` 限制跨度 30 天）或连续两次 `showDatePicker`。
- 移除 `SegmentedButton<TrendRange>`。

### 5. 图表区

- `TrendGlassBarChart` 参数改为 `startDate`、`endDate`、`bucketMode`（`hourly` | `daily`），移除 `TrendRange range`。
- 标题：**固定** `喂养趋势图`（`glassTextColor`，约 18sp 居中）。
- 柱：`BarChartRodData` + `LinearGradient`（`accent` 高亮 → 低亮）；`borderRadius` 顶部 8–12；`width` 随点数缩放；可选 `backDrawRodData` 同宽偏移 1px 暗色模拟厚度。

### 6. 轴粒度

- 继续 `ChartAxisGranularity`：`hourly` 用整点 marks；`daily` 用 `evenlySpacedIndices` 5/7 档。
- `TrendGlassBarChart` 横轴标签：hourly 用 `HH:00` / 末桶 `24:00`；daily 用 `MM-dd`。

## Risks / Trade-offs

- **[Risk] 30 天日桶柱过密** → X 轴仅 5/7 标签；柱宽下限 4px；可横向滚动为二期。
- **[Risk] 记忆日期含「今天」之后** → 读取时 `end = min(end, today)`。
- **[Risk] 固定标题「喂养」与非喂养事件** → 产品已确认；后续可配置化。

## Migration Plan

1. 扩展 repository + bucket；再改 chart；最后改 screen + store。
2. 移除 `TrendRange` 在 `trends_screen` / `trend_glass_bar_chart` 的引用；若 enum 无它用可保留定义待清理。
3. 手工验证记忆：改日期 → 退出 → 再进趋势页。

## Open Questions

- （已关闭）最大跨度：30 天；记忆：是；默认：本周一至今天。
