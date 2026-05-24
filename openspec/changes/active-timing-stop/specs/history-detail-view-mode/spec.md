## MODIFIED Requirements

### Requirement: 预览模式结构化展示

The system SHALL display structured read-only fields in preview mode aligned with eventNumber semantics (times, usage, duration, remark). 预览模式必须按 `eventNumber` 语义结构化展示只读字段（起止/结束时间、用量、用时、备注等），时间格式必须完整可读（如 `yyyy-MM-dd HH:mm:ss` 级别）。

#### Scenario: 计时类记录预览已结束

- **WHEN** 记录 `eventNumber == 0` 且已设置有效结束时间
- **THEN** 预览必须包含开始时间、结束时间、用时文案、备注（若有）

#### Scenario: 计时类记录预览进行中

- **WHEN** 记录 `eventNumber == 0` 且结束时间未设置
- **THEN** 预览必须包含开始时间（完整可读格式）
- **THEN** 必须展示**已计时长**行，每秒按 `active-event-timer` 规则刷新（`MM:SS` 或 `HH:MM:SS`）
- **THEN** 必须提供「停止」操作，一点即停且无二次确认；停止成功后必须刷新为已结束预览或通知列表刷新
- **THEN** 不得仅依赖静态「计时中」文案作为唯一进行中反馈（可与已计时长并存或合并为一行）
