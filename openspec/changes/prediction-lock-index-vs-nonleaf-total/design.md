## Context

`invite-peer-force-ucg` 已落地：catalog 永久 `allowedCount`、服务端 `totalActivatableCount`（device 非叶子）、预测页 `isVip OR index < allowedCount`、Hub「已激活 / 已全部激活」。联调后产品确认锁槽与天花板**故意使用不同集合**，需在客户端规格与实现注释中钉死，避免误对齐为「按非叶子事件 ID 开锁」。

## Goals / Non-Goals

**Goals:**

- 规格写明：N 次永久开通 → 当前预测展示列表（排序后）下标 `0..N-1` 可用。
- 规格写明：「已全部激活」仅当 `totalActivatableCount > 0 && allowedCount >= totalActivatableCount`；`totalActivatableCount` = 服务端字典非叶子总数。
- 审计现实现与决议一致；必要时补注释，避免后续重构改错。

**Non-Goals:**

- 不改 Go / catalog 契约字段；不按事件 ID 绑定槽位。
- 不用客户端可见行数重算「已全部激活」。
- 不改 VIP OR 语义、不改邀请码/原力流程；不新建测试。

## Decisions

### D1：锁槽 = 当前排序 display index

- 解锁判定：`realIndex < permanentAllowedCount`（VIP 另 OR），`realIndex` 为**当前**预测行列表下标。
- 列表排序变化（如 nextAt）后，同一 `allowedCount` 可能解锁不同 eventId——产品接受「买的是槽位数」。
- 否决：按非叶子事件固定 ID 开锁（实现成本高且与现列表模型不符）。

### D2：全部激活天花板 = 字典非叶子

- 仅信任 catalog `totalActivatableCount`；失败或省略时按既有规则（total≤0 不显示「已全部激活」）。
- 否决：用 `rows.length` 或本地 `hasChildren` 重算天花板（会与 Go 权威分叉）。

### D3：两集合解耦为明确 trade-off

- 可见行数 < total 时：列表可能已全开，Hub 仍可卖到 total。
- 可见行数 > total（如含无子根的骨架）时：仍以 total 判「已全部激活」，不以行数为准。

## Risks / Trade-offs

- [重排导致「解锁的事件」漂移] → 规格与注释标明槽位语义；产品接受。
- [Hub 继续售卖而列表已无锁行] → 用户可继续累加永久条数直至 total；符合「天花板跟字典」。
- [与 Go design「MUST 同集」措辞冲突] → 本客户端变更显式不采纳该客户端对齐要求；服务端仍只提供非叶子 total。

## Migration Plan

- 仅规格/注释；随下一版客户端发版。无数据迁移、无回滚脚本。

## Open Questions

- 无（产品已确认：排序前 N 行 + 非叶子 total）。
