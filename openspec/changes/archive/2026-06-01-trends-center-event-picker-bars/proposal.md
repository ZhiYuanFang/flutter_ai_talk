## Why

趋势中心若一次性罗列全部事件的折线图，信息密度高且难以聚焦；产品希望先拉取服务端事件目录，由用户**主动选择**某一事件后再查看该事件的走势。除折线外还需**量柱**表达每次记录的强度；对 **`event_number == 0` 的计时类事件**，网关给出的「次数」语义不适用，应以**单次记录的持续时段**作为量值，否则趋势与柱状含义失真。

## What Changes

- 进入趋势中心后 **必须先**（在具备 `deviceNo` 等前置条件时）从服务端加载**事件列表**（沿用或明确 `GET /device/history/api/event/options` 契约），以列表/下拉等形式供用户**单选**当前要分析的事件。
- 仅针对**当前选中事件**请求 `piece` 序列（或等价接口），展示 **趋势折线 + 量柱**（同一坐标系或上下联动，以实现为准）；切换事件或时间范围时刷新数据。
- 对每条历史样本计算**量值 `y`**：`event_number != 0` 时使用服务端计数（及单位展示策略）；`event_number == 0` 时 MUST 使用 **`endTime` 与 `startTime` 的差值**换算为 **小时**作为量；无有效结束时间时该条量的规则在规格中明确（如 0 或剔除）。

## Capabilities

### New Capabilities

- `trends-center-event-charts`：事件目录加载与用户单选、选中事件下的趋势折线与量柱展示、计时类（`event_number == 0`）以时段为量的计算与展示约定。

### Modified Capabilities

- （仓库根目录 `openspec/specs` 暂无基线；不声明对既有根规格的 MODIFIED。）

## Impact

- Flutter：`TrendsScreen`、`RemoteTrendsRepository`（或抽取 `TrendMetric` 纯函数）、`TrendPoint` / `TrendSeries` 是否扩展字段、`fl_chart` 组合图。
- 与 `history_mapper` / `parseHistoryInstant` 时间语义对齐，避免与首页历史「0 表示未结束」冲突。
