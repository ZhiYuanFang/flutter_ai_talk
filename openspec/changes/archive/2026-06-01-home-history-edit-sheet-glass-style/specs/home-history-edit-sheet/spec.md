## MODIFIED Requirements

### Requirement: 主页点击历史行弹出编辑 Sheet

The client SHALL open a modal bottom sheet on the home screen when the user taps a history record row, and MUST NOT navigate to a full-screen history detail route. Sheet **必须**在主页上下文中直接展示编辑控件（无独立预览模式），且 **MUST** 采用 `home-history-edit-sheet-glass-visual` 中定义的玻璃拟态视觉（居中 Logo/标题、玻璃时间条、取消/保存底栏）。

#### Scenario: 点击已落库记录

- **WHEN** 用户点击一条非 `pending:*` 的历史记录
- **THEN** 客户端 MUST 在主页底部弹出玻璃风格编辑 Sheet，且 MUST NOT 调用 `push('/history/:id')`

#### Scenario: 远程门禁未通过

- **WHEN** 用户点击历史行但 `_ensureRemoteGate` 等前置检查失败
- **THEN** 客户端 MUST 不打开 Sheet（与现网 `_openHistory` 门禁行为一致）

### Requirement: 滚轮时分且不可改日期

The client SHALL use Cupertino-style hour and minute wheel pickers for editable time fields in the history edit sheet, and MUST NOT allow the user to change the calendar date within the sheet. 可编辑时间的**日历日** MUST 锁定为记录原有 `startTime`/`endTime` 所在日期（分别锚定各字段）；界面 MUST NOT 展示可编辑的独立「日期：yyyy-MM-dd」行（日期仅作内部锚定）。

#### Scenario: eventNumber 为 0 编辑开始时间

- **WHEN** 用户调整开始时间滚轮并保存
- **THEN** 提交的 `startTime` MUST 为「原开始日期 + 新时分」的 Unix 秒，且界面 MUST NOT 提供日期选择器

#### Scenario: eventNumber 为 1 编辑结束时间

- **WHEN** 用户仅调整结束时间滚轮并保存
- **THEN** 客户端 MUST 按现网规则提交结束时间（及网关约定的开始时间同步语义），且 MUST NOT 展示可编辑开始时间滚轮

### Requirement: 按 eventNumber 展示可编辑字段

The client SHALL present editable fields according to `eventNumber` consistent with prior history detail rules: `0` → start/end (end clearable); `1` → end only; `>1` → end + usage wheel + remark. 事件名 MUST 只读；备注 MUST 可编辑（非 pending），备注输入区 MUST 与时间条视觉风格协调（玻璃/半透明边框）。

#### Scenario: 多次计数类用量滚轮

- **WHEN** `eventNumber > 1` 且记录非 pending
- **THEN** Sheet MUST 展示与 `home_number_event_sheet` 相同的用量滚轮档位（5–500，步进 5），且 MUST NOT 使用自由文本整数输入作为主交互

#### Scenario: 备注保存

- **WHEN** 用户修改备注并保存成功
- **THEN** 更新请求 MUST 携带新 `remark`，事件名 MUST 与记录一致

### Requirement: 计时中可在 Sheet 内停止

The client SHALL provide a stop action inside the edit sheet when `eventNumber == 0`, the record is actively timing (no valid end), and the record is not pending. 停止 MUST 调用与列表行停止等价的 update（写入 `endTime=now`），成功 MUST 更新本地列表并关闭 Sheet。

#### Scenario: Sheet 内停止计时

- **WHEN** 用户在计时中记录的 Sheet 内点击停止且网关成功
- **THEN** 客户端 MUST 更新该行的结束时间、MUST 关闭 Sheet，且 MUST NOT 要求用户先保存其他字段

#### Scenario: pending 计时记录无停止

- **WHEN** 记录 id 为 `pending:*` 且为计时类
- **THEN** Sheet MUST NOT 提供停止按钮（只读态）

### Requirement: pending 乐观记录只读

The client MUST treat records with `pending:*` ids as read-only in the history edit sheet. 滚轮、备注输入、保存、删除、停止 MUST 均不可用；MAY 展示「同步中」类提示。

#### Scenario: 打开 pending 行

- **WHEN** 用户点击 `pending:*` 记录
- **THEN** Sheet MAY 打开以展示当前字段，但 MUST NOT 允许提交 update/delete/stop

### Requirement: Sheet 内删除当前事件

The client SHALL provide delete for non-pending records in the sheet with confirmation, calling the gateway delete API; on success MUST remove the record from local history state and close the sheet.

#### Scenario: 确认删除成功

- **WHEN** 用户确认删除且网关成功
- **THEN** 客户端 MUST 从 `homeHistoryProvider` 移除该 id 并关闭 Sheet

#### Scenario: 取消删除

- **WHEN** 用户在确认对话框选择取消
- **THEN** 客户端 MUST NOT 发起删除请求

### Requirement: 保存校验与本地状态同步

The client SHALL validate edits before save (e.g. end before start, usage required) consistent with prior history detail behavior; on successful update MUST upsert local list state without requiring a full history reload.

#### Scenario: 结束早于开始

- **WHEN** `eventNumber == 0` 且结束时间早于开始时间并点击保存
- **THEN** 客户端 MUST 展示错误 Toast 且 MUST NOT 调用 update

#### Scenario: 保存成功

- **WHEN** 校验通过且 update 成功
- **THEN** 客户端 MUST `replaceRecord` 更新本地列表并关闭 Sheet

### Requirement: 移除全屏历史详情页

The client MUST remove `HistoryDetailScreen` and the `/history/:recordId` route; no code path SHALL depend on the full-screen history detail for edit/preview/delete.

#### Scenario: 路由不可用

- **WHEN** 用户尝试访问 `/history/:recordId` 深链
- **THEN** 应用 MUST NOT 渲染历史详情全屏页（路由已删除或重定向至 home）
