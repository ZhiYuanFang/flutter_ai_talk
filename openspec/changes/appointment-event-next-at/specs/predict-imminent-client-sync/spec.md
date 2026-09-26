## ADDED Requirements

### Requirement: Cleared appointment events MUST be omitted from pending sync

The client MUST omit an appointment root `eventId` from the full `PUT /device/api/predict/imminent/pending` `events` array when that appointment has no next trigger (`nextAt=0`) or was cleared. The client MUST NOT rely on pending items with `nextAt=0` to cancel prior schedules. When `nextAt>0` (including overdue), pending MUST include that eventId with that nextAt in seconds. Existing full-replace pending sync for other events SHALL remain. 无约定或已清空的预约根事件 **必须** 从 pending `events` 中省略；**不得** 依赖 pending 的 `nextAt=0` 取消旧日程；正 nextAt（含过期）**必须** 纳入。

#### Scenario: Cleared appointment omitted from pending

- **WHEN** 用户在编辑页清空某预约事件下次时间并触发 pending 同步
- **THEN** 请求体 events MUST NOT 包含该根 eventId

#### Scenario: Appointment with nextAt included

- **WHEN** 预约事件存在 `nextAt=T>0`（含 T 已过期）且纳入当前预测结果
- **THEN** pending events MUST 包含该根 eventId 且 nextAt 为 T（秒）

#### Scenario: Empty appointment omitted

- **WHEN** 预约事件 `nextAt=0` 且触发 pending 同步
- **THEN** 请求体 events MUST NOT 包含该根 eventId
