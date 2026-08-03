## Why

首页已有模式球与 tip 球两套 `EdgeDockShell`，彼此不知对方圆心，仅靠 tip `along` 软错开仍可重叠。产品要求**悬浮/贴边球互不重叠**写入**通用基线**，供后续更多贴边球复用，而非 tip↔模式特判。

## What Changes

- **基线**：EdgeDock 体系内已注册球的最终 placement **必须**互不重叠（圆心距 ≥ diameter + 最小间隙；同边沿 along 亦须满足）。
- 新增占位协调（注册 / 注销 / 松手解析合法 placement）；壳或宿主在吸附与浮空落点时走协调结果。
- 冲突时**移动正在拖动的球**；可声明 sticky 优先级（模式球默认 sticky，tip 被推开）。
- tip / 模式球接入注册表；去掉「仅靠 initial along」作为唯一防重叠手段。

## Capabilities

### New Capabilities

- `edge-dock-occupancy`：多球占位注册与解冲突规则（可与 shell 同仓实现）。

### Modified Capabilities

- `edge-dock-shell`：松手/应用 placement 时 MUST 尊重占位解冲突；禁止与其它已注册球重叠。

## Impact

- 代码：`edge_dock_geometry` 辅助、占位协调（provider 或单例）、`EdgeDockShell` / tip / 模式球接线。
- 依赖未归档 shell 系列；行为增量，不改 tip SSE / Android 原生。

**默认冻结（提案时未再确认则采用）：** floating + 贴边均互斥；冲突推拖动中的球；模式球 sticky。
