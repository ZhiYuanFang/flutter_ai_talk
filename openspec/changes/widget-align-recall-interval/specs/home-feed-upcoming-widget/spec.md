## ADDED Requirements

### Requirement: Widget prediction inputs SHALL include recall interval fallback

When the Flutter client builds home-widget predictions (native payload sync, in-app large preview, or settings widget preview), it MUST use the same real feeding history union and `recallIntervalsByRoot` map as the smart prediction page (`resolveWidgetPredictionInputs` or equivalent). Calls to `predictAllUpcoming` for these surfaces MUST pass `recallIntervalsByRoot` so sparse roots with a valid recall seed interval produce the same `nextAt = lastAt + interval` results as on-page cards. The client MUST NOT omit the recall interval map on in-app previews while native sync includes it.

构建桌面小组件预测（native sync、应用内大尺寸预览、设置页预览）时，客户端 MUST 使用与智能预测页相同的真喂养并集与 `recallIntervalsByRoot`；对这些表面的 `predictAllUpcoming` MUST 传入该 map，使稀疏根在有效回忆间隔下与页内卡一致。MUST NOT 在页内预览漏传间隔而仅在 native sync 携带。

#### Scenario: 大尺寸预览带间隔旁路

- **WHEN** 某根真样本不足但存在有效回忆种子间隔与真 `lastAt`，且用户打开桌面小组件展示页大尺寸预览
- **THEN** 预览 MUST 展示与预测页一致的可预测 hero/行（同源公式）
- **AND** MUST NOT 仅因漏传 `recallIntervalsByRoot` 显示无预测

#### Scenario: 设置页预览同源

- **WHEN** 用户在设置页查看小组件预览且存在回忆间隔旁路可预测事件
- **THEN** 预览预测 MUST 与 `resolveWidgetPredictionInputs` 语义一致
- **AND** MUST NOT 仅用无种子的 home 分页历史推演

### Requirement: Recall seed writes SHALL schedule home widget sync

After a successful `PredictionRecallSeed` upsert or clear of seed root ids, the client MUST schedule a home-widget sync (`scheduleHomeWidgetSync` or equivalent) so the native widget payload reflects the updated recall interval fallback without requiring an unrelated history edit. Manual「刷新小组件数据」MUST remain able to rebuild the same aligned payload.

成功 upsert 或清除回忆种子后，客户端 MUST 调度桌面小组件 sync，使 native payload 反映更新后的间隔旁路，不得仅依赖无关历史改动才更新。手动「刷新小组件数据」MUST 仍能重建同一对齐 payload。

#### Scenario: 确认间隔后桌面可更新

- **WHEN** 用户在预测卡确认「大概多久一次」并成功 upsert 种子
- **THEN** 客户端 MUST 调度 home-widget sync
- **AND** 随后 native 小组件（或紧接的手动刷新）MUST 能展示该根基于 `lastAt + seed.interval` 的预测（在推演开启等既有门闸下）
