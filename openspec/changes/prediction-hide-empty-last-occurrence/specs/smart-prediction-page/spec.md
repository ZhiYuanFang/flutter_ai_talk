## MODIFIED Requirements

### Requirement: Card lastAt SHALL match real feeding history

On the smart prediction page, for each hot (non-demo-skeleton) prediction event card, when a「上一次」line is shown, its instant (`SmartPredictionRow.lastAt`) MUST equal the latest real feeding occurrence under that catalog root resolved from home and/or prediction-range history (same semantics as the edit-sheet record lookup, excluding recall-seed synthetics), or—when that union yields no occurrence—the device-scoped event-last-at cache tip for that root. When neither window nor cache provides a real occurrence, `lastAt` MUST be null and the client MUST NOT render the「上一次…」row (MUST NOT show「暂无」or equivalent empty last-occurrence copy). After a real record is created, updated, or deleted such that home history already reflects the change, the next rows rebuild that watches home (and the last-at cache) MUST update the card label accordingly without waiting solely on recall-seed state. Cache-only `lastAt` MUST still count as non-null for forecast-on「补充上一次」/ card-tap supplement gating. When `lastAt` is null and existing forecast-on supplement gates pass, the client MUST still show the「补充上一次」CTA so cold-start users can add a first occurrence. Opening the history edit sheet from the label MUST still require a resolvable real `HistoryRecord` in home∪range.

热态预测卡若展示「上一次」行，时刻 MUST 与 home∪range 真喂养最新发生一致；窗口未命中时 MUST 回退 tip 缓存。窗与缓存皆无时 `lastAt` MUST 为 null，且 **MUST NOT** 渲染「上一次」行（**不得**「暂无」）。真记录变化后下一帧 MUST 更新。仅缓存命中仍视为有 lastAt（不得误出「补充上一次」）。`lastAt` 为空且满足既有开推演补记门闩时 **MUST** 仍展示「补充上一次」。点文案进编辑仍须窗内真记录。

#### Scenario: 改时间后文案对齐

- **WHEN** 用户经「上一次」编辑 Sheet 修改真记录发生时刻并保存成功，且 home 列表已含更新后的记录
- **THEN** 该卡「上一次」文案 MUST 显示与该真记录一致的本地可读时刻
- **AND** MUST NOT 继续显示仅由回忆种子决定的旧时刻

#### Scenario: 删除后文案对齐

- **WHEN** 用户删除该根下一条真记录且 home 已去掉该 id，且该根仍有其它真记录
- **THEN** 「上一次」MUST 变为剩余真记录中的最新发生时刻

#### Scenario: 无 lastAt 时隐藏上一次行

- **WHEN** 热态卡 `lastAt` 为 null（窗与 tip 皆无）
- **THEN** 该卡 MUST NOT 渲染「上一次…」行
- **AND** MUST NOT 展示「暂无」作为上一次文案

#### Scenario: 无 lastAt 时仍可补充上一次

- **WHEN** 热态卡开推演、`lastAt` 为 null，且既有「补充上一次」门闩满足（非计时中、非预约仅下次等排除条件按现网）
- **THEN** 该卡 MUST 仍展示「补充上一次」入口

#### Scenario: 删 tip 且窗内无该根

- **WHEN** 用户删除该根缓存 tip 对应真记录，乐观同步后 home∪range 该根无真发生，且事件最近发生缓存已按 tip 失效移除该根
- **THEN** 该卡 `lastAt` MUST 为 null，MUST NOT 渲染「上一次」行
- **AND** 该卡 MUST NOT 展示由回忆种子撑起的 countdown / nextAt
- **AND** 客户端 MUST 清除该根 `PredictionRecallSeed`（若存在）

#### Scenario: 窗外曾见过则展示真实时刻

- **WHEN** 热态某根在 home∪range 无真记录，但事件最近发生缓存有该根时刻 T
- **THEN** 该卡 `lastAt` MUST 为 T，MUST 展示「上一次」可读时刻（MUST NOT 为「暂无」）
- **AND** 开推演时 MUST NOT 仅因窗口为空而展示「补充上一次」
