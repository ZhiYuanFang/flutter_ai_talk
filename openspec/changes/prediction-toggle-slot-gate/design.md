## Context

预测页现对 `realIndex >= allowedCount`（非 VIP）包 `FeatureLockOverlay`，点卡进开通中心；同时卡上有 `forecastDisabledIds` 推演开关。`prediction-lock-index-vs-nonleaf-total` 曾钉死「锁=排序下标」。产品改为开启计数闸 + 去浮层。

## Goals / Non-Goals

**Goals:**

- 去掉预测事件卡浮层。
- 开开关：非 VIP 且 `enabledCount >= allowedCount` → 弹框 → 确定进开通中心。
- VIP 开开关全放行；关开关始终成功。

**Non-Goals:**

- 不改 Hub 徽章/CTA、不改 catalog 字段、不改服务端。
- 不自动关闭超额已开启项；不改 UCG 浮层。
- 不新建测试。

## Decisions

### D1：槽位 = 开启计数（方案 A）

- `enabledCount` = 当前预测列表中 `forecastEnabled == true` 的条数（与 `forecastDisabledIds` 互补；按展示用的 rows/catalog 根事件计，与开关同一 eventId 空间）。
- 尝试 `setEnabled(id, true)` 时：若 `!isVip && enabledCount >= allowedCount` 且该 id 当前为关 → 拦截并弹框。
- 若该 id 已是开，重复开忽略；关不检查槽位。

### D2：废止预测页下标浮层

- 删除/停用 `lockIfNeeded` + 预测卡 `FeatureLockOverlay`。
- `prediction-lock-index-vs-nonleaf-total` 的「排序前 N 行可用」仅不再适用于预测页锁；Hub 库存文案仍按永久 N vs total。

### D3：弹框

- `showGlassConfirmDialog`（或等价）：说明名额已满、引导购买；确认 → `context.push('/features/unlock')`；开关 UI 保持关。

### D4：VIP

- `isVip == true` 时开开关不弹框、不校验 `allowedCount`。

### D5：超额存量

- 已开启数已大于 N（历史/降级）时：已开项保持；仅阻止**新增**开启，直到 `enabledCount < allowedCount` 或开通 VIP/加购。

## Risks / Trade-offs

- [与下标槽 change 语义冲突] → 本 change 明确取代预测页锁模型；归档时以本 delta 为准。
- [enabledCount 统计范围] → 与开关同一 eventId；骨架 demo 无真实闸或沿用现「demo 不锁」策略并在实现注释标明。

## Migration Plan

- 随客户端发版；本地 `forecastDisabledIds` 无需迁移。

## Open Questions

- 无（A + VIP 全放行已确认）。
