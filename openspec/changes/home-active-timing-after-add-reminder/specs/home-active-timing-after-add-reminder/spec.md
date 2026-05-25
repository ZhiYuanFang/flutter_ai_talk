## ADDED Requirements

### Requirement: 新增成功后检测其它进行中计时

The system SHALL, after a history record is successfully added, scan persisted history for active timing records other than the newly added record and prompt the user when at least one exists. 系统必须在**一条历史记录新增成功之后**，扫描当前历史列表中除**刚新增记录**外的其它记录；若存在至少一条进行中计时（`isActiveTimingRecord`），则 MUST 向用户展示提醒对话框。刚新增记录的 id 必须排除在候选之外。`isPendingHistoryId` 的记录不得作为可停止候选。

#### Scenario: 按钮新增后存在其它计时

- **WHEN** 用户通过事件按钮成功新增一条记录，且列表中另有至少一条其它进行中计时
- **THEN** 系统必须在适当时机（fly 动画结束后或若无动画则新增成功后的下一帧）展示提醒对话框

#### Scenario: 语音或文字新增后存在其它计时

- **WHEN** 用户通过语音或文字发送指令，且 WebSocket 推送一条**新**历史记录，且列表中另有至少一条其它进行中计时
- **THEN** 系统必须展示提醒对话框，且不得因同一次新增的重复 upsert 重复弹窗

#### Scenario: 无其它进行中计时

- **WHEN** 新增成功后，除刚新增记录外不存在其它进行中计时
- **THEN** 系统不得展示本提醒对话框

#### Scenario: 新增未成功

- **WHEN** 按钮新增 API 失败或语音/文字未产生新历史记录
- **THEN** 系统不得展示本提醒对话框

### Requirement: 不得阻断新增流程

The system MUST NOT block or cancel a successful add operation when showing the active timing reminder. 系统 MUST NOT 因本提醒而阻止、撤销或延迟已成功完成的新增操作；提醒为事后非阻断 nudge。

#### Scenario: 用户选择暂不

- **WHEN** 用户在提醒对话框点击「暂不」、关闭或点击 barrier  dismiss
- **THEN** 刚新增的记录必须保持可见，其它未选中的进行中计时必须继续计时

### Requirement: 居中玻璃风提醒对话框

The system SHALL present the reminder as a centered modal dialog whose visual style aligns with the history edit glass panel (`HistoryEditGlassPanel` and related tokens). 系统必须以**屏幕居中**模态对话框展示提醒；视觉风格 MUST 对齐历史编辑 Sheet 的玻璃拟态（磨砂、渐变、描边、圆角、`AppVisualTokens` / `onShell` 文字色），与底部 Sheet **风格一致**但**位置为居中**而非 bottom sheet。

#### Scenario: 对话框结构

- **WHEN** 提醒对话框展示
- **THEN** 必须包含标题、简短说明、未结束事件列表区域，以及底栏「暂不」与主操作按钮；主操作按钮 MUST 为实心 pill 样式，与编辑 Sheet 保存按钮风格一致

#### Scenario: 主题适配

- **WHEN** 用户在浅色或深色 shell 主题下打开提醒对话框
- **THEN** 玻璃面板与文字对比度 MUST 与历史编辑 Sheet 同等可读

### Requirement: 展示具体未结束事件

The system SHALL list each other active timing record with identifiable event name and live elapsed duration. 对话框内 MUST **逐条列出**每条其它进行中计时，使用户能看清具体是哪些事件未结束。每行至少包含：事件名称、实时已计时长（不足 1 小时 `MM:SS`，满 1 小时及以上 `HH:MM:SS`，与 `active-event-timer` 一致）。若事件目录可解析，SHOULD 展示事件 accent 色或图标以辅助识别。

#### Scenario: 单条其它计时

- **WHEN** 仅有一条其它进行中计时
- **THEN** 对话框必须展示该事件名称与实时已计时长，且该条视为待结束目标

#### Scenario: 对话框内时长刷新

- **WHEN** 提醒对话框处于打开状态且仍有进行中候选
- **THEN** 各行已计时长 MUST 至少每秒更新一次

### Requirement: 多条时可选部分结束

The system SHALL allow the user to select a subset of other active timing records to stop when more than one candidate exists. 当存在**多条**其它进行中计时时，系统 MUST 提供多选能力（如 Checkbox），使用户可**选择部分**结束；主操作「结束所选」仅 MUST 对当前选中记录调用停止逻辑。默认 MUST 全选所有候选。未选中任何一条时，主操作 MUST 为 disabled。

#### Scenario: 部分结束

- **WHEN** 存在 3 条其它进行中计时，用户仅勾选其中 2 条并确认结束
- **THEN** 系统必须仅停止勾选的 2 条，未勾选的 1 条必须保持进行中

#### Scenario: 全部不选

- **WHEN** 存在多条候选且用户取消全部勾选
- **THEN** 「结束所选」必须不可点击，直至至少勾选一条

### Requirement: 结束所选沿用既有停止 API

The system SHALL stop selected active timing records via the existing history update API without an additional confirmation per record. 用户确认结束所选后，系统 MUST 对每条选中记录调用与列表/详情「停止」相同的更新逻辑（`updateHistoryRecord` 设置 `endTime` 为当前时刻），**不得**对每条记录再弹二次确认。单条失败 MUST 提示错误并保持该条进行中；已成功停止的记录 MUST 立即反映在 UI。

#### Scenario: 全部停止成功

- **WHEN** 用户对所选记录确认结束且全部请求成功
- **THEN** 对话框必须关闭，对应记录变为已结束状态

#### Scenario: 部分停止失败

- **WHEN** 批量停止中部分请求失败
- **THEN** 系统必须 Toast 提示失败，已成功项必须已结束，失败项仍可留在对话框或关闭后保持进行中（实现二选一，但不得误报已成功）

### Requirement: 与同 eventId 新增前 Toast 并存

The system MUST preserve the existing rule that blocks starting a second active timer for the same eventId via the time button before add. 本变更 MUST NOT 移除或替换「同 eventId 的 time 按钮已在计时中则 Toast 拒绝再次开始」的既有行为；该路径不会触发「新增成功」，故不触发本提醒。

#### Scenario: 同 eventId 重复开始

- **WHEN** 用户点击某 time 事件按钮且该 eventId 已在计时中
- **THEN** 系统必须仍 Toast 提示且不得新增，且不得展示本事后提醒对话框
