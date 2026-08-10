## Why

智能预测页折线在解释「过去习惯 → 今日预测」时，当前整段虚线、Y 轴刻度过密、无法手触看具体时刻，阅读成本高。需要把线型拆成「历史实线 + 连今日预测虚线」，并限制 Y 轴时刻标签数量、支持触点浮层。

## What Changes

- Y 轴时刻标签 **最多 5 个（≤5）**（含端点；窗口很窄时可以更少）。
- 支持手指/指针触碰数据点：在点**上方**浮动展示该点具体时间（`HH:mm`）。
- 折线样式：过去日之间的连接为**实线**；仅「最后一个过去日点 → 今日 `nextAt` 点」为**虚线**。无今日点时仅实线；仅今日一点时可不画线段或只画点。
- 今日点语义不在本 change 重开：沿用 `prediction-chart-today-nextat`（仅当 `nextAt` 在今天才画今日点，且点为 `nextAt`）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：补充/修改折线展示 Requirement（Y 轴刻度上限、触点浮层、实线/虚线分段）。

## Impact

- **Flutter**：`smart_prediction_screen.dart` 中 `_LookbackChart`（fl_chart 双 `LineChartBarData`、`lineTouchData`、左侧 `SideTitles` 间隔）。
- **测试**：不新建 `**/test/**`；手工触点与线型验收。
- **Android**：不改原生，不强制 release APK。
