## Context

`prediction-grid-active-timing` 已实现 compact 计时 chrome，但 logo/标题/`accent` 仍绑定预测行根 `definition`/`colorHex`。产品要求计时中展示叶子名与叶子色，且停止按钮持续心跳。

## Goals / Non-Goals

**Goals:**

- 计时中：叶子 logo + 叶子名 + 叶子 accent（elapsed 与停止底）。
- 停止可点时持续 scale 心跳；`_stopping` 时停动画并显示「…」。
- 叶子解析失败有回退。

**Non-Goals:**

- 不改非计时倒计时大图/心跳 soonest 规则。
- 不改列表卡。
- 不改停止 API 语义。

## Decisions

1. **叶子解析**  
   `leafDef = lookupEventForRecord(catalog, activeTiming)`；标题 `leafDef?.name ?? record.eventName ?? row.eventName`；logo 用 `leafDef`；accent 优先 `resolveEventColor(context, leafDef)`，无则回退行 `colorHex`。

2. **停止心跳**  
   对齐 `_HeartbeatLogo`：`AnimationController` 800ms reverse repeat，scale约 0.92–1.08；包住 `FilledButton`。`_stopping == true` 时 dispose/stop 动画或固定 scale=1。

3. **推演开关**  
   仍在标题行；与叶子身份无关。

## Risks / Trade-offs

- [目录缺叶子] 仅有 eventName → 用记录名 + 根色回退。  
- [动画耗电] 仅计时中卡片有 Stop 心跳，数量有限。

## Migration Plan

- 纯 UI。回滚：恢复根 definition/colorHex + 静止停止钮。

## Open Questions

（无；叶子名与叶子 accent 已确认。）
