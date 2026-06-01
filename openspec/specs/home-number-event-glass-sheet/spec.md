## ADDED Requirements

### Requirement: Number event add sheet uses glassmorphism shell

The system SHALL present the number-type event add bottom sheet with a glassmorphism container consistent with history edit and trend sheets.

当用户从主页触发 **number / 用量类** 事件新增时，弹层 MUST 使用透明 modal 背景与内层玻璃面板（磨砂、圆角、事件色渐变 tint、右上关闭）。面板 MUST NOT 使用默认 Material 纯色 `surface` 作为唯一容器。

#### Scenario: Open add sheet from home

- **WHEN** 用户在主页点击某 number 类型事件（如奶量）
- **THEN** 系统 MUST 展示带玻璃拟态面板的底部 Sheet，且 MUST 显示事件 Logo 与事件名

#### Scenario: Dismiss without save

- **WHEN** 用户点击玻璃面板右上角关闭
- **THEN** 系统 MUST 关闭 Sheet 且 MUST NOT 提交历史记录

### Requirement: Glass sheet preserves number event form capabilities

The system SHALL keep existing number event form behavior inside the glass shell.

玻璃样式变更 MUST NOT 改变以下能力：日期/时间选择、5–500 步进 5 的用量滚轮、可选备注、确认后返回 `HomeNumberEventResult`（含 `startTime`、`eventNumber`、`remark`）。

#### Scenario: Confirm add with usage memory

- **WHEN** 用户调整滚轮并点击「确认记录」
- **THEN** 系统 MUST 关闭 Sheet 并返回与变更前相同结构的结果对象，且 MUST 在无 `initialUsage` 时持久化上次用量记忆

#### Scenario: Initial picker position

- **WHEN** 用户打开新增 Sheet 且存在该事件的上次记忆用量
- **THEN** 滚轮 MUST 定位到该记忆档位（或最近合法档位）

### Requirement: Glass form controls use light foreground on tinted panel

The system SHALL render labels, time controls, remark field, and picker text with readable light foreground on the glass panel.

日期/时间控件、备注输入、用量滚轮选中项 MUST 在玻璃底上使用固定浅色前景（与 `HistoryEditGlassPanel` 一致），不得因浅色 shell 主题导致文字不可读。

#### Scenario: Remark field visible

- **WHEN** 玻璃 Sheet 展示备注输入框
- **THEN** 输入框 MUST 使用玻璃风格边框与标签色，且用户 MUST 能输入备注

#### Scenario: Primary confirm action

- **WHEN** 玻璃 Sheet 展示主操作
- **THEN** 系统 MUST 提供醒目的「确认记录」主按钮（实心、圆角），且点击后 MUST 触发与变更前相同的确认逻辑
