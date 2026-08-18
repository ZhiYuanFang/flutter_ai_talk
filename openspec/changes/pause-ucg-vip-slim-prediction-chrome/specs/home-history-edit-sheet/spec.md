## MODIFIED Requirements

### Requirement: 按 eventNumber 展示可编辑字段

The client SHALL present editable fields according to `eventNumber` consistent with prior history detail rules: `0` → start/end (end clearable); `1` → end only; `>1` → end + usage wheel + remark. Event name MUST be read-only; remark MUST be editable (non-pending). For all non-pending records, the sheet MUST show the multimedia strip per `history-event-media`. The「同步广场」toggle MUST follow `history-event-square-sync` (including the temporary pause gate: when the gate is active, the toggle MUST NOT appear even with media).

事件名 MUST 只读；备注 MUST 可编辑（非 pending）。对全部非 pending 记录，Sheet MUST 展示多媒体横向条带；「同步广场」开关 MUST 遵循 `history-event-square-sync`（含暂停闸门：开启时有媒体也不得展示）。

#### Scenario: 多次计数类用量滚轮

- **WHEN** `eventNumber > 1` 且记录非 pending
- **THEN** Sheet MUST 展示与 `home_number_event_sheet` 相同的用量滚轮档位（5–500，步进 5），且 MUST NOT 使用自由文本整数输入作为主交互

#### Scenario: 暂停闸门下有媒体无同步开关

- **WHEN** 同步广场暂停闸门开启、记录非 pending 且已选媒体
- **THEN** Sheet MUST 仍展示媒体条带
- **AND** MUST NOT 展示「同步广场」开关

### Requirement: 保存栏布局 MUST 容纳同步开关

The save action row SHALL place the square-sync toggle immediately left of the save button, vertically centered, with label below the switch, **when** the square-sync pause gate is inactive and media is present (per `history-event-square-sync`). When the pause gate is active, the row MUST NOT include the square-sync toggle and MUST still provide the save button.

暂停闸门关闭且有媒体时，保存操作行 MUST 在保存按钮左侧、垂直居中放置「同步广场」开关；暂停闸门开启时 MUST NOT 包含该开关，仍 MUST 提供保存按钮。

#### Scenario: 暂停期仅保存按钮

- **WHEN** 同步广场暂停闸门开启且用户打开可保存的编辑 Sheet
- **THEN** 底部操作区 MUST NOT 出现「同步广场」开关
- **AND** MUST 仍提供保存按钮

#### Scenario: 闸门关闭且有媒体时保存栏含开关

- **WHEN** 暂停闸门关闭、记录非 pending 且已选媒体
- **THEN** 底部操作区 MUST 从左到右呈现「同步广场」开关（含下方标签）与保存按钮
