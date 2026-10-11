## ADDED Requirements

### Requirement: Active timing cards SHALL show estimated end in list and grid

When the prediction surface shows an in-progress timing on a card (list or grid/compact), and an `expectEndAt` is available for that active record, the client SHALL show secondary copy using wall-clock time:「预计约 HH:mm 结束」. When `now` is after `expectEndAt`, the client MUST still show that original clock time and MUST append an overdue marker equivalent to「已超时」(copy form MAY use middle-dot separator). When no `expectEndAt` exists, the client MUST NOT reserve an empty ETA placeholder. Existing elapsed timer and stop control behavior SHALL remain.

列表与网格进行中卡在有 ETA 时 MUST 展示预计结束；超时 MUST 保留原时刻并标「已超时」；无 ETA MUST NOT 空占位；已过时长与停止控件不变。

#### Scenario: Grid card shows ETA

- **WHEN** 网格进行中卡存在 expectEndAt 且尚未超时
- **THEN** 卡上 MUST 出现含「预计约」与结束时刻的文案

#### Scenario: List card shows ETA

- **WHEN** 列表态进行中卡存在 expectEndAt
- **THEN** 卡上 MUST 同样展示预计结束文案（不得仅网格可见）

#### Scenario: Overdue keeps original estimate

- **WHEN** now 已晚于 expectEndAt
- **THEN** 文案 MUST 仍包含原预计时刻语义，且 MUST 含「已超时」

#### Scenario: No ETA no placeholder

- **WHEN** 进行中但无 expectEndAt
- **THEN** 卡 MUST NOT 展示空白预计结束行
