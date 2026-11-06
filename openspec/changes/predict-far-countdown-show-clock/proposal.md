## Why

距 `nextAt` 仍远时，卡上长时间倒计时（如十几小时）可读性差，不如直接看预估钟点。在已落地的逾期「显示预估时刻」之上：剩余 **大于 6 小时**时同样改为只显示时刻；跨日时日期前缀用更小字号，突出 `HH:mm`。

## What Changes

- 热态预测卡倒计时区块：当未逾期且 `nextAt − now > 6 hours` 时，大数字区 MUST **只**展示预估本地时刻（MUST NOT 再展示 `H:MM:SS` 倒计时）。
- 时刻格式与逾期态一致：今天仅 `HH:mm`（无「今天」）；昨天「昨天」+ `HH:mm`；更早「M月D日」+ `HH:mm`。
- 展示时刻且含日期前缀时，日期文案字号 MUST 明显小于 `HH:mm`（今天无日期段则不变）。
- 进入「只显示时刻」态（逾期，或未逾期且剩余 &gt; 6h）时，标题 MUST 为「预计{事件名}时刻」；仅当未逾期且剩余 ≤ 6h 时保持「距离下次{事件名}倒计时」与 `H:MM:SS`。
- 承接 `predict-overdue-show-next-at-clock`；本 change 扩展远距阈值与日期小字。
- **不做**：小组件 native、tip 栏、双行同时显示倒计时+时刻、改 6h 为可配置设置项。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：远距（&gt;6h）倒计时改为只显示预估时刻；时刻区日期前缀小字。

## Impact

- 代码：`format_widget_relative_time.dart`（或拆日期/时分结构）、`smart_prediction_screen` 倒计时区块渲染与标题门闩。
- 规格：对照 `openspec/specs/v2.1.4.md`，并与 `predict-overdue-show-next-at-clock` 对齐。
- 无原生 / Go API 变更。
