## MODIFIED Requirements

### Requirement: 按 eventNumber 展示可编辑字段

The client SHALL present editable fields according to `eventNumber` consistent with prior history detail rules: `0` → start/end (end clearable); `1` → end only; `>1` → end + usage wheel + remark. Event name MUST be read-only; remark MUST be editable (non-pending). For all non-pending records, the sheet MUST also show multimedia strip and square-sync toggle per capabilities `history-event-media` and `history-event-square-sync`.

事件名 MUST 只读；备注 MUST 可编辑（非 pending）。对全部非 pending 记录，Sheet MUST  additionally 展示多媒体横向条带与「同步广场」开关（见 `history-event-media`、`history-event-square-sync`）。

#### Scenario: 多次计数类用量滚轮

- **WHEN** `eventNumber > 1` 且记录非 pending
- **THEN** Sheet MUST 展示与 `home_number_event_sheet` 相同的用量滚轮档位（5–500，步进 5），且 MUST NOT 使用自由文本整数输入作为主交互

#### Scenario: 备注保存

- **WHEN** 用户修改备注并保存成功
- **THEN** 更新请求 MUST 携带新 `remark`，事件名 MUST 与记录一致

#### Scenario: 非喂养事件亦可附媒体

- **WHEN** `eventNumber` 为 0 或 1 且记录非 pending
- **THEN** Sheet MUST 仍展示备注旁「+」与媒体条带（不得仅限 `eventNumber > 1`）

### Requirement: 保存校验与本地状态同步

The client SHALL validate edits before save (e.g. end before start, usage required, image count ≤9, image/video mutual exclusion) consistent with prior history detail behavior; on successful update MUST upsert local list state without requiring a full history reload. Save MUST also execute square-sync or local-media side effects per `history-event-square-sync` and `event-media-local-cache`.

保存前 MUST 校验结束早于开始、用量必填、图片≤9、图视互斥等；update 成功后 MUST `replaceRecord` 并关闭 Sheet。保存 MUST  additionally 执行同步广场或本地媒体副作用（见 `history-event-square-sync`、`event-media-local-cache`）。

#### Scenario: 结束早于开始

- **WHEN** `eventNumber == 0` 且结束时间早于开始时间并点击保存
- **THEN** 客户端 MUST 展示错误 Toast 且 MUST NOT 调用 update

#### Scenario: 保存成功

- **WHEN** 校验通过且 update 成功
- **THEN** 客户端 MUST `replaceRecord` 更新本地列表并关闭 Sheet

#### Scenario: 保存含同步发帖

- **WHEN** 校验通过、同步开启、`sub≠0`、含媒体且 update 成功
- **THEN** 客户端 MUST 在关闭 Sheet 前或之后完成 UCG create/update，并将 `postId` 合并进本地记录

## ADDED Requirements

### Requirement: 保存栏布局 MUST 容纳同步开关

The save action row SHALL place the square-sync toggle immediately left of the save button, vertically centered, with label below the switch.

保存操作行 MUST 在保存按钮左侧、垂直居中放置「同步广场」开关，开关下方展示小字标签。

#### Scenario: 保存栏展示

- **WHEN** 用户打开非 pending 历史编辑 Sheet
- **THEN** 底部操作区 MUST 从左到右呈现「同步广场」开关（含下方标签）与保存按钮
