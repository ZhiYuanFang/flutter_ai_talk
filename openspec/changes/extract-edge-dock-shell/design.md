## Context

`home_input_dock_geometry` + `HomeInputModeDock` 已具备可复用的贴边交互；`HomeTipPanel` 自建 docked/collapsed，拉出用单帧 delta、热区无外扩。产品冻结：**先抽壳并挂模式球，再迁 tip，效果对齐模式球**。

## Goals / Non-Goals

**Goals:**

- 通用壳：peek / engaged / floating；参数化 diameter；hit expand；累计向内拉；pointer 锁滑。
- 模式球零行为回归后，tip 球态挂壳并对齐拉出/点出。
- 为后续贴边球预留同一 API。

**Non-Goals:**

- 本变更不把 tip **展开大卡**整段拖进壳（仅球态）。
- 不统一各 feature 持久化 Store。
- 不改 PageView 三页业务。

## Decisions

### 1. 分层

- **geometry**：`DockEdge`、snap/clamp/圆心；`diameter` 入参（默认 48）。
- **shell**：纯 UI/手势；`child` 为球内容；回调 `onTap`、`onPointerOccupied`、`onPlacementChanged(edge, along | freeCenter)`。
- **feature**：模式球 = 壳 + cycle/persist；tip = 大卡自管 + 球用壳。

### 2. 状态对齐模式球

| 壳状态 | 模式球语义 | tip 语义 |
|--------|------------|----------|
| edgePeek | 贴边半圆 | docked |
| edgeEngaged | 贴边全圆（可点切模式） | 可选：拉出过程全圆；松手可回 peek 或进 expanded |
| floating | 自由悬浮全圆 | collapsed 浮空圆 |

**tip 拉出**：累计向内 ≥ 阈值 → `onTap`/专用 `onEngage` 回调展开大卡（居中或保留偏移，默认居中对齐现 tip expand）；点 peek 同样展开。

### 3. 迁移顺序（强制）

1. 抽 geometry + shell；模式球改挂；手工验收模式球。  
2. tip 球迁壳；删 tip 弱拉出；手工验收 tip。  
禁止 tip 先于模式球挂壳合并。

### 4. 锁滑

- 壳 `pointerDown` → `onPointerOccupied(true)`；up/cancel → false。  
- 模式球/tip 都接到现有 `onDockDraggingChanged` / 等价。

### 5. 兼容

- `home_input_dock_geometry.dart` 可 `export` 新 geometry 或薄包装，减少无关 diff；新代码走 `edge_dock_*`。

## Risks / Trade-offs

- [模式球回归] → Phase1 门禁；行为对照表手工点。  
- [tip 大卡与壳双套拖动] → 过半才切壳；expanded 仍 tip 自管。  
- [两球同边重叠] → 沿用 tip along 错开；壳可接受 initial along。

## Migration Plan

- Phase1 可单独合入；Phase2 依赖 Phase1。回滚：模式球恢复旧 State；tip 恢复自绘 docked。

## Open Questions

- 无（先壳后 tip、效果对齐已冻结）。
