## ADDED Requirements

### Requirement: Background hero skip SHALL rebuild from prediction result snapshot not home pagination

When the user activates「跳过」on the desktop widget and the Flutter background interactivity callback runs, the client MUST rebuild the widget payload from the persisted prediction-result snapshot (plus `WidgetHeroSkipStore` S1 rules), and MUST NOT use feeding-home pagination disk cache (`HomeHistoryStore` / equivalent first-page history) as the default successful path to re-run `predictAllUpcoming`. Hero MUST exclude still-skipped ids and promote the next non-skipped prediction when available; `recentLast` MUST still be allowed to include skipped event ids. This path MUST be shared by Android and iOS (same Dart callback).

用户在桌面激活「跳过」且后台回调执行时，客户端 **必须** 基于已持久化的预测结果快照（叠加 S1 skip）重建 payload；**不得** 将喂养分页磁盘历史作为默认成功路径整包重算预测。hero **必须** 排除仍 skip 的 id 并在可用时提升下一条；`recentLast` **必须** 仍可含已 skip id。Android 与 iOS **必须** 共用同一 Dart 回调。

#### Scenario: 有快照时跳过不读喂养分页主路径

- **WHEN** 本地已存在前台 sync 写出的预测结果快照
- **AND** 用户在 Android 或 iOS 桌面 large/small 小组件点击「跳过」
- **THEN** 后台重建 MUST 使用该快照生成新 hero / `recentLast`
- **AND** MUST NOT 以 `HomeHistoryStore.loadSnapshot`（或等价分页缓存）作为本次成功重建的主历史输入

#### Scenario: large 跳过后仍保持 large 预算深度

- **WHEN** 跳过前 large 小组件展示的 `recentLast` 长度为 6（或第二行已可见）
- **AND** 快照中可重建的候选不少于跳过前深度
- **AND** 用户点击「跳过」
- **THEN** 新 payload 的 `recentLast` 长度 MUST 仍达到 large 预算（最多 6，在候选充足时）
- **AND** native large 渲染 MUST 仍可展示两行后续留意（不得无故塌成仅 3 槽可视）

#### Scenario: 双端同一 Dart 路径

- **WHEN** 分别在 Android 与 iOS 上对 large 小组件执行「跳过」
- **THEN** 两端 MUST 均进入同一 `homeWidgetInteractiveCallback` / `applyWidgetHeroSkipAndRefresh`（或等价共享实现）
- **AND** 槽位深度与 hero 晋升语义 MUST 一致（不依赖单端 native 特例逻辑）

### Requirement: Snapshot-missing skip SHALL degrade without shallow full repredict as success

When the prediction-result snapshot is missing or unreadable, background skip MUST still record the S1 skip, MUST prefer rebuilding from the last pushed widget payload (promote next from `recentLast` when possible) so large slot count does not collapse solely due to missing snapshot, and MUST log the degradation via `AppDebugLog.homeWidget`. The client MUST NOT treat a full `predictAllUpcoming` run seeded only by feeding-home pagination cache as the preferred successful recovery.

快照缺失或不可读时，后台跳过 **必须** 仍写入 S1 skip，**必须** 优先基于上一份已推送 payload 重建（在可能时从 `recentLast` 晋升），避免仅因缺快照导致 large 槽位塌缩，并 **必须** 经 `AppDebugLog.homeWidget` 记录降级。客户端 **不得** 将仅以喂养分页缓存为输入的整包 `predictAllUpcoming` 当作首选成功恢复路径。

#### Scenario: 无快照时用上一 payload 晋升

- **WHEN** 预测结果快照为空或损坏
- **AND** 上一份 ready payload 含 hero A 与非空 `recentLast`
- **AND** 用户点击「跳过」
- **THEN** 客户端 MUST 记录 A 的 skip
- **AND** 新 hero MUST 为 `recentLast` 中下一条可用预测（若存在）
- **AND** MUST 打 `AppDebugLog.homeWidget` 降级日志
- **AND** MUST NOT 将「仅 HomeHistoryStore + predictAllUpcoming」作为该次首选成功路径
