## ADDED Requirements

### Requirement: Prediction card-area pull refresh SHALL schedule accuracy alignment

When the user completes pull-to-refresh on the smart prediction page card area (`RefreshIndicator` / `onCardsPullRefresh` or equivalent), the client MUST continue to refresh the unified-pool rolling history window and silently refresh appointment next/last as today. After a **successful** rolling-history refresh, the client MUST schedule the existing predict post-mutation silent pipeline (`schedulePredictPostHistoryMutation` or documented equivalent) so expect-batch / accuracy-eligible samples can catch up. The pull gesture MUST NOT be required to await the full expect-batch HTTP completion before dismissing the refresh indicator. If rolling history refresh fails, the client MUST NOT be required to schedule the pipeline solely for this pull, and MUST keep existing failure Toast behavior.

预测页卡片区下拉：滚动历史成功后 MUST 调度静默 expect/准确率对齐管线；MUST NOT 为等 batch 完成而拖死下拉指示器；历史刷新失败时本路径不必调度。

#### Scenario: Successful pull schedules post-mutation

- **WHEN** 用户下拉且 `refreshRollingWindow` 成功
- **THEN** 客户端 MUST 已调度 `schedulePredictPostHistoryMutation`（或等价）
- **AND** 预约 next/last 静默刷新 MUST 仍执行

#### Scenario: Failed rolling history skips mandatory schedule

- **WHEN** 下拉时滚动历史刷新失败并 Toast
- **THEN** 本需求 MUST NOT 要求仍强制调度静默管线

### Requirement: Next-three-hours card tap SHALL force-refresh feature catalog

When settle is not syncing and the user taps the「接下来3小时」card to open the predict capability tier wall, the client MUST invoke a **forced** feature catalog reload (`featureCatalog` `refresh` / `ensureLoaded(force: true)` or equivalent) for the current bound session. The wall MUST still open (failure MUST keep prior cached catalog items). The force refresh MAY run concurrently with opening the wall; the client MUST NOT block opening the wall on catalog HTTP success. Syncing state MUST remain non-tappable for opening the wall.

非 syncing 点三小时开墙时 MUST force 刷新功能包 catalog；失败保留旧 cache 仍可开墙；MUST NOT 阻塞开墙至 HTTP 成功。

#### Scenario: Tap opens wall and forces catalog

- **WHEN** 后缀非 syncing 且用户点击三小时卡
- **THEN** 客户端 MUST 发起 feature catalog force 刷新
- **AND** MUST 打开两档能力墙

#### Scenario: Catalog force failure still opens wall

- **WHEN** catalog force 刷新失败但本地仍有旧 items
- **THEN** 两档墙 MUST 仍可打开并展示旧 cache（或既有空/失败展示规则）
