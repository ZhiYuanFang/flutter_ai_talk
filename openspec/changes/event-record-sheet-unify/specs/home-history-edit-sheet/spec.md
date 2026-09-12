## MODIFIED Requirements

### Requirement: 滚轮日期与时分可编辑

The client SHALL use Cupertino-style wheel pickers for editable date and time fields in the history edit flow (unified event record sheet, edit intent). Calendar day and time-of-day MUST be editable separately for each displayed instant (start and/or end per `eventNumber`). Date and time MUST be presented via the centered segmented time line (`{日}·{时}` / range with `~` / `进行中`) without「开始时间」/「结束时间」labels beside the controls; tapping day opens the date wheel sheet and tapping time (or「进行中」) opens the hour/minute wheel sheet. The selectable date range MUST be from the baby's birth date through today inclusive. For `eventNumber == 0`, when the user changes the start calendar day and an end time is set, if the new start day is after the end day, the client MUST set the end day to the start day while preserving the end's time-of-day; when the user changes the start time-of-day and the new start instant is after the end instant, the client MUST set the end to the new start instant. The edit sheet title MUST be the event display name only (MUST NOT use an `编辑·` prefix). The client MUST NOT provide a「清除结束时间」control; an unset end remains only until the user sets an end or deletes the record. Saved `startTime` / `endTime` MUST remain Unix second timestamps. Non-quantity create flows (`time`/`one` instant add) MUST remain without this sheet; number create MUST use the unified sheet with cross-day time (see `event-record-sheet` / `home-number-event-glass-sheet`).

历史编辑（统一 Sheet · edit）必须用居中分段时间行分别编辑自然日与时分；不得再并排「标签+两格」作为唯一样式；标题必须仅为事件名（不得「编辑·」前缀）；不得提供清除结束。日期范围仍为生日→今日；`eventNumber==0` 的开始/结束对齐规则保持。非量新建仍可不经此 Sheet；number 新建走统一 Sheet 跨日时间。

#### Scenario: eventNumber 为 0 修改开始日期

- **WHEN** 用户打开非 pending 的 `eventNumber == 0` 记录，点击开始侧日段并选择新自然日后保存
- **THEN** 提交的 `startTime` MUST 为「新自然日 + 当前编辑时分」的 Unix 秒，且界面 MUST 以居中分段时间行展示

#### Scenario: eventNumber 为 0 跨天开始与结束

- **WHEN** 用户将开始日期设为昨天、结束日期设为今天且结束时刻晚于开始时刻，并保存
- **THEN** 客户端 MUST 接受并分别提交对应的 `startTime` 与 `endTime` Unix 秒

#### Scenario: eventNumber 为 0 开始日晚于结束日仅对齐日期

- **WHEN** 用户在 `eventNumber == 0` 编辑中修改开始**日期**，且已设置结束时间，且新开始自然日晚于当前结束自然日
- **THEN** 客户端 MUST 将结束的日历日同步为开始日，且 MUST 保留结束的时/分不变

#### Scenario: eventNumber 为 0 开始时刻晚于结束时刻对齐时间

- **WHEN** 用户在 `eventNumber == 0` 编辑中修改开始**时分**，且已设置结束时间，且新开始时刻整体晚于当前结束时刻
- **THEN** 客户端 MUST 将结束时刻同步为新开始时刻

#### Scenario: eventNumber 为 1 修改结束日期

- **WHEN** 用户仅修改结束侧日期或时分并保存
- **THEN** 客户端 MUST 按现网规则将 `startTime` 与 `endTime` 同步为同一时刻的 Unix 秒，且 MUST NOT 展示可编辑的独立「仅开始」行（单点时间行即可）

#### Scenario: eventNumber 大于 1 修改结束日期

- **WHEN** 用户修改结束侧日期并保存
- **THEN** 提交的结束时刻 Unix 秒 MUST 反映新自然日与原编辑时分，且用量滚轮与备注行为 MUST 不变

#### Scenario: 日期超出可选范围

- **WHEN** 用户在日期滚轮 Sheet 中操作
- **THEN** 客户端 MUST NOT 允许选择早于宝宝生日或晚于今天的自然日

#### Scenario: pending 记录只读

- **WHEN** 用户打开 `pending:*` 记录
- **THEN** 日期与时间控件 MUST 不可编辑（与现网只读一致）

#### Scenario: 无清除结束

- **WHEN** 用户打开 `eventNumber == 0` 且结束已设置的编辑 Sheet
- **THEN** MUST NOT 展示「清除结束时间」或等价一键清回进行中的控件
