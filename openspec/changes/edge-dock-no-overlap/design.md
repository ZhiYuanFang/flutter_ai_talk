## Context

多颗 `EdgeDockShell` 独立 snap，会重叠。产品冻结：**互不重叠写入基线**；floating + 贴边均互斥；冲突推**正在拖的球**；模式球 **sticky**。

## Goals / Non-Goals

**Goals:**

- 占位注册表 + 解冲突 API（propose edge / propose free）。
- 壳松手落点经协调后再 `showPeek` / floating。
- tip、模式球接入；后续球只注册 id。

**Non-Goals:**

- 拖动过程中实时避让（可只在松手解析；拖中 MAY 穿透，松手再推）。
- 推开 sticky 球或改模式球持久化优先逻辑以外的业务。

## Decisions

### 1. 重叠判据

- 将 placement 规范为圆心（peek 用半圆圆心或全圆圆心——统一用**视觉/命中主圆**圆心，与 `dockCircleCenterForSnapped` / floating center 一致）。
- 若两圆心距 `< diameter + gap`（建议 `gap ≥ 8`，默认可 `gap = 8`）则冲突。
- 同边沿：亦可用 along 差换算弧长/边长，与圆心距等价实现即可。

### 2. 协调器

- `EdgeDockOccupancy`（ChangeNotifier / Riverpod）：`register(id, placement, sticky)`、`unregister`、`resolve(id, desired) → EdgeDockPlacement`。
- 解冲突：在同边扫描 along、或浮空沿排斥方向外推，取最近合法点；失败则换邻边或保最小距离浮空。
- sticky 球视为固定障碍；非 sticky 的 desired 被调整。

### 3. 壳接线

- Shell 增加可选 `occupancyId` + 读写协调器；或宿主在 `onPlacementChanged` / `_finishDrag` 后调用 `resolve` 再 `controller.show*`。
- 优先：**壳内松手**调用 resolve（基线行为一致），宿主只提供 id/sticky。

### 4. 否决

- 仅 tip 写死避开 0.75：否决——非基线。
- 拖中每帧避让：首期不做，降复杂度。

## Risks / Trade-offs

- [松手才推开略跳] → 可接受；后续可加拖中 resolve。  
- [多球同边塞满] → resolve 换边或浮空；极端挤满时保 gap 优先。  
- [模式球 persist 与 tip 瞬时占位] → tip unregister 于 dismiss/无 tip；模式球始终注册。

## Migration Plan

1. geometry 辅助 `circlesOverlap` / `resolveAlong`。  
2. Occupancy + shell 松手 resolve。  
3. tip / mode 传入 id+sticky。  
4. 手工：两球拖同边不重叠。

## Open Questions

- 无（floating+贴边互斥、推拖动球、模式 sticky 已作默认冻结）。
