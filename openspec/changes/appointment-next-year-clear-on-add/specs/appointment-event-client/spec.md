## MODIFIED Requirements

### Requirement: Post-write prompt MUST use dedicated next-appointment sheet when empty or overdue

After a successful **「补充上一次」** for an appointment root, the client MUST NOT alter the existing add UI. When the root nextAt is missing/`0` or overdue, the client MUST present the dedicated next-appointment sheet; when nextAt is in the future, the client MUST NOT present that sheet. After a successful **normal add** (`EventRecordIntent.add`) for an appointment root, the client MUST first clear the root nextAt via `PUT nextAt=0` (and pending omit semantics). If that clear fails, the client MUST show an error affordance and MUST NOT present the dedicated sheet. If clear succeeds, the client MUST present the dedicated next-appointment sheet so the user sets the next appointment. The client MUST NOT clear nextAt on supplement, prediction-card edit, or countdown-edit paths. 预约事件「补充上一次」成功后仍仅空/过期弹专用 sheet、已是未来则不弹、不清空。正常新增成功后 **必须** 先 PUT `nextAt=0`；清空失败 **必须** 提示且 **不得** 弹 sheet；清空成功 **必须** 弹专用 sheet。补充/预测卡改约/倒计时改约路径 **不得** 先清空。

#### Scenario: Add succeeds then clear then prompt

- **WHEN** 用户按现网流程新增预约事件记录成功
- **THEN** 客户端 MUST 先对该根 PUT `nextAt=0`
- **AND** 清空成功后 MUST 弹出专用下一次预约 sheet
- **AND** MUST NOT 为嵌入 nextAt 而修改原新增页

#### Scenario: Add clear fails does not prompt

- **WHEN** 用户新增预约记录成功但清空 nextAt 的 PUT 失败
- **THEN** 客户端 MUST 提示失败
- **AND** MUST NOT 弹出专用下一次预约 sheet

#### Scenario: Add clears even when future nextAt existed

- **WHEN** 用户新增成功且该根原先已有未来 `nextAt`
- **THEN** 客户端 MUST 仍先清空再弹专用 sheet（不得因未来约定而跳过）

#### Scenario: Supplement succeeds when overdue

- **WHEN** 「补充上一次」成功且该根 `nextAt` 已过期
- **THEN** 客户端 MUST 弹出专用下一次预约 sheet
- **AND** MUST NOT 因补充而先 PUT `nextAt=0`

#### Scenario: Supplement with future nextAt does not prompt

- **WHEN** 「补充上一次」成功且该根已有未来 `nextAt`
- **THEN** 客户端 MUST NOT 弹出专用下一次预约 sheet
- **AND** MUST NOT 清空该 nextAt

### Requirement: Dedicated next-appointment sheet MUST use logo title and datetime wheels

The dedicated sheet MUST use a top-bottom layout: top copy `{event logo}下一次{event name}预约时间`; directly below the title, a **tappable year row** showing the selected year; then **four scroll columns** for month, day, hour, and minute (not a `dateAndTime` combined picker that omits a discoverable year control, and not five columns in one row). Activating the year row MUST open a year picker (e.g. glass single-wheel) covering the allowed year range. Day column MUST clamp to the valid days of the selected year/month. Confirm MUST PUT a positive nextAt and trigger pending sync. 专用 sheet **必须** 上语文案含 logo 与事件名；标题下 **必须** 有可点年份行；主区为**月/日/时/分四列**滚轮（不得用无年控件的合列 dateAndTime，也不得五列挤一行）；点年份 **必须** 可另选年；日列 **必须** 随年月合法收束；确认 **必须** PUT 正 nextAt 并触发 pending 同步。

#### Scenario: Confirm writes nextAt

- **WHEN** 用户在专用 sheet 确认所选日期时间
- **THEN** 客户端 MUST 对根 eventId PUT 对应正 nextAt，并 MUST 触发 pending 整表同步使该事件以该时间出现在 events 中

#### Scenario: Year row opens year picker

- **WHEN** 用户打开专用下一次预约 sheet 并点按标题下方的年份行
- **THEN** 客户端 MUST 打开年份选择器，使用户可选择不同年份
- **AND** 主区 MUST 为月/日/时/分四列（不得与年份挤在同一行五列）

## ADDED Requirements

### Requirement: Appointment card countdown MUST open next-appointment sheet

When a hot (non-demo) appointment prediction card shows a countdown (or overdue countdown copy) for a stored nextAt, activating the countdown block (caption and time digits) MUST open the dedicated next-appointment sheet with the current nextAt as initial value, and MUST NOT trigger the card's add-feeding path. The same behavior MUST apply in portrait and landscape layouts. 热态预约卡展示 countdown（含逾期）时，点按倒计时块 **必须** 打开专用改约 sheet（以当前 nextAt 为初值），**不得** 走加喂养；竖屏与横屏 **必须** 一致。

#### Scenario: Portrait countdown edits nextAt

- **WHEN** 竖屏热态预约卡展示 countdown，用户点按倒计时块
- **THEN** 客户端 MUST 打开专用下一次预约 sheet
- **AND** MUST NOT 因此调用加喂养 `handleEventGridTap`

#### Scenario: Landscape countdown edits nextAt

- **WHEN** 横屏热态预约卡对预约根展示 countdown，用户点按倒计时块
- **THEN** 客户端 MUST 打开专用下一次预约 sheet
- **AND** MUST NOT 因此调用加喂养

#### Scenario: Card body outside countdown still adds

- **WHEN** 热态预约卡有 countdown，用户点按倒计时块以外的卡片主体（非开关/上一次/CTA）
- **THEN** 客户端 MAY/MUST 仍按既有卡点规则走加喂养（本需求不取消整卡新增）
