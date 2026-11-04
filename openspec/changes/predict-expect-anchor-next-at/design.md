## Context

间隔预测在 `predict-interval-use-start` 后已统一为 `occurrenceInstant → startTime`，`nextAt = lastAt + interval` 能正确给出「今晚约 19:00 开睡」。duration 样本自身也按 `startTime` 分桶。但开事前挂 expect 时，`attachWinningExpect` 把加权**查询锚点**设为 `prediction.lastAt`（上次开始的时段），而进行中 ETA 用本次 `startAt`。昼夜双峰（日间短睡 + 夜间长睡）下，白天 `lastAt` 会把开事前用时拉向 ~1h，用户在 `nextAt` 开睡后 ETA 又回到 ~10h。

基线 `event-expect-prediction` 已写「晚间 start 或等价锚点」应抬高夜间长睡权重，但未把开事前的「等价锚点」钉死为 `nextAt`。

## Goals / Non-Goals

**Goals:**

- 开事前胜出 expect（duration 与 amount）的时段/半衰期查询锚点与「即将发生的那场」对齐：`prediction.nextAt`。
- 与进行中 ETA（`anchorAt = startAt`）语义一致：查询锚 = 这场开始时刻。
- 规格补场景：上午 lastAt → 傍晚 nextAt 时，开事前 duration 不得系统性贴近日间短睡。

**Non-Goals:**

- 不改间隔公式、同桶硬过滤、桶边界、权重数值、半衰期分段。
- 不改 duration 样本时刻（仍为该次 `startTime`）与 `end−start` 时长定义。
- 不改进行中 ETA 实现路径（已正确用 `startAt`）。
- 不改 Go API 字段；不强制热卡重新展示 duration 行（展示策略另议）。
- 不新建 `**/test/**` 测试文件（仓库测试约定）。

## Decisions

1. **单点改 `attachWinningExpect` 的 `anchorAt`。**  
   将 `anchorAt: prediction.lastAt` 改为 `anchorAt: prediction.nextAt`。所有经该函数挂载的开事前 expect 一并生效，避免双轨。  
   **备选**：仅 duration 用 `nextAt`、amount 仍用 `lastAt` → 需拆 `resolveWinningExpect`，收益小且「下次喂多少」同样应按下次喂养时段。

2. **duration 与 amount 共用 `nextAt` 查询锚。**  
   `resolveWinningExpect` 本就单锚驱动双线；「下一场」的时段对用量同样成立。

3. **不改 `confidentDurationExpectSec` 调用方中的进行中路径。**  
   Active ETA 已锚在本次 start；与本次改动正交，仅保证开事前与开睡后查询语义对称。

4. **规格用 ADDED Requirement 钉查询锚，不重写整段双模态正文。**  
   样本 startTime 规则、胜出模态、文案「约」保持基线；新增「开事前查询锚 = nextAt」及昼夜双峰场景，避免归档时误删既有细则。

## Risks / Trade-offs

- [开事前用时突然变长/变短] → 预期行为；昼夜双峰更准，单峰事件 `lastAt` 与 `nextAt` 常同桶，结果接近。  
- [pending / 照护提醒文案变化] → 指纹含 expect，会触发一次全量 pending 同步；无协议破坏。  
- [仅缓存旁路、nextAt 来自种子间隔] → 仍用该 `nextAt` 作锚；与「预测的下一场」一致。  
- [热卡当前隐藏 duration 行] → 用户可能主要从推送/旧包感知；改锚仍修正 pending 与任何展示路径。

## Migration Plan

发版客户端即可；无磁盘 schema 迁移。回滚：恢复 `attachWinningExpect` 的 `anchorAt: prediction.lastAt` 并还原本 change 规格。

## Open Questions

无（amount 与 duration 同锚已在 Decisions 敲定）。
