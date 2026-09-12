## MODIFIED Requirements

### Requirement: Number event add sheet uses glassmorphism shell

The system SHALL present the number-type event add bottom sheet via the unified event-record glass sheet consistent with history edit and trend sheets.

当用户从主页触发 **number / 用量类** 事件新增时，弹层 MUST 使用统一记录 Sheet 的透明 modal 背景与内层玻璃面板（磨砂、圆角、事件色渐变 tint、右上关闭）。面板 MUST NOT 使用默认 Material 纯色 `surface` 作为唯一容器。标题 MUST 仅为事件名（不得加「新增·」前缀）。

#### Scenario: Open add sheet from home

- **WHEN** 用户在主页点击某 number 类型事件（如奶量）
- **THEN** 系统 MUST 展示统一玻璃记录 Sheet，且 MUST 显示事件 Logo 与事件名（无操作类型前缀）

#### Scenario: Dismiss without save

- **WHEN** 用户点击玻璃面板右上角关闭
- **THEN** 系统 MUST 关闭 Sheet 且 MUST NOT 提交历史记录

### Requirement: Glass sheet preserves number event form capabilities

The system SHALL keep number event form capabilities inside the unified glass shell, with cross-day occurrence time.

玻璃样式与统一入口 MUST NOT 去掉以下能力：跨日发生时刻（生日→今日，初值今日·当下）、5–500 步进 5 的用量滚轮、可选备注、确认后提交与既有 `HomeNumberEventResult` 等价字段（`startTime`、`eventNumber`、`remark`）。时间区 MUST 使用居中分段「日·时」行，MUST NOT 再限制为仅当天时分。

#### Scenario: Confirm add with usage memory

- **WHEN** 用户调整滚轮并点击确认类主按钮
- **THEN** 系统 MUST 关闭 Sheet 并提交含所选跨日 `startTime`、用量与备注的记录，且 MUST 在无 `initialUsage` 时持久化上次用量记忆

#### Scenario: Initial picker position

- **WHEN** 用户打开新增 Sheet 且存在该事件的上次记忆用量
- **THEN** 滚轮 MUST 定位到该记忆档位（或最近合法档位）

#### Scenario: 跨日新增

- **WHEN** 用户将发生日改为昨天并确认
- **THEN** 提交的 start/end MUST 落在昨天所选时分
