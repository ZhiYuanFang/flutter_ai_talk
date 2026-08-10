## Why

预测页折线 Y 轴在上一版为「≤5」刻度，仍偏密。产品要求改为**固定 3 个**时刻标签（典型：底 / 中 / 顶），阅读更干净。

## What Changes

- **BREAKING（相对 `prediction-chart-touch-and-line-style`）**：Y 轴时刻刻度由「最多 5 个（≤5）」改为**固定展示 3 个**时刻标签。
- 步长推导改为按可见 Y 范围二等分（`span/2`）并 snap；左侧标题与水平网格对齐这 3 档。
- 触点浮层、历史实线 / 连今日虚线、今日 `nextAt` 点规则不变。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：将「Y 轴至多五个时刻标签」改为「固定三个时刻标签」。

## Impact

- **Flutter**：`_LookbackChart._yAxisStep` 及对应 `SideTitles` / 网格 interval。
- **测试**：不新建 `**/test/**`；手工确认始终约 3 个 Y 标签。
- **Android**：不改原生，不强制 release APK。
