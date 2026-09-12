## ADDED Requirements

### Requirement: Card lastAt SHALL match real feeding history

On the smart prediction page, for each hot (non-demo-skeleton) prediction event card, the displayed「上一次{eventName}：{time}」instant (`SmartPredictionRow.lastAt`) MUST equal the latest real feeding occurrence under that catalog root resolved from home and/or prediction-range history (same semantics as the edit-sheet record lookup, excluding recall-seed synthetics). When no real occurrence exists, `lastAt` MUST be null and the label MUST show「暂无」(or equivalent). After a real record is created, updated, or deleted such that home history already reflects the change, the next rows rebuild that watches home MUST update the card label accordingly without waiting solely on recall-seed state.

热态预测卡「上一次」展示时刻 MUST 与 home∪range 真喂养最新发生一致（与编辑 Sheet 解析同源，排除回忆种子）；无真发生时 `lastAt` MUST 为 null 并显示「暂无」。真记录增删改且 home 已反映后，下一帧依赖 home 的行重建 MUST 更新卡文案，不得仅依赖回忆种子状态。

#### Scenario: 改时间后文案对齐

- **WHEN** 用户经「上一次」编辑 Sheet 修改真记录发生时刻并保存成功，且 home 列表已含更新后的记录
- **THEN** 该卡「上一次」文案 MUST 显示与该真记录一致的本地可读时刻
- **AND** MUST NOT 继续显示仅由回忆种子决定的旧时刻

#### Scenario: 删除后文案对齐

- **WHEN** 用户删除该根下一条真记录且 home 已去掉该 id，且该根仍有其它真记录
- **THEN** 「上一次」MUST 变为剩余真记录中的最新发生时刻

#### Scenario: 删光后无记录态

- **WHEN** 用户删除该根下全部真喂养记录（home∪range 乐观同步后该根无真发生）
- **THEN** 该卡 `lastAt` MUST 为 null，「上一次」MUST 为「暂无」
- **AND** 该卡 MUST NOT 展示由回忆种子撑起的 countdown / nextAt
- **AND** 客户端 MUST 清除该根 `PredictionRecallSeed`（若存在）

### Requirement: Range history snapshot SHALL drop deleted ids eagerly

When home history removes a record id (successful delete), the client MUST also remove that id from the in-memory prediction-range history snapshot before or as part of the same user-visible update cycle, and MAY still schedule a debounced range refetch. The client MUST NOT leave a deleted id solely in range such that `latestReal…(home∪range)` still resolves it after home has removed it.

home 成功删除某记录 id 后，客户端 MUST 同步从预测 range 内存快照去掉该 id（仍可 debounce 重拉）；MUST NOT 在 home 已无该 id 时仍仅因 range 残留而使真 `lastAt` 解析到已删记录。

#### Scenario: 删除后并集不再命中旧 id

- **WHEN** home `removeRecord(id)` 完成且 range 尚未完成网络刷新
- **THEN** 以 home∪range 解析的该根最新真记录 MUST NOT 仍为已删除的 id
