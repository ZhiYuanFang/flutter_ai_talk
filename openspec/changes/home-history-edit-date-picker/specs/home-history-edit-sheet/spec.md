## REMOVED Requirements

### Requirement: 滚轮时分且不可改日期

**Reason**: 用户需要在历史编辑时修正日历日（如补录昨天记录）；锁定原记录日期无法满足该场景。

**Migration**: 由新需求「滚轮日期与时分可编辑」取代；时分滚轮保留，并新增可点击的日期文字与日期滚轮 Sheet。

## ADDED Requirements

### Requirement: 滚轮日期与时分可编辑

The client SHALL use Cupertino-style wheel pickers for editable date and time fields in the history edit sheet. Calendar day and time-of-day MUST be editable separately for each displayed instant (start and/or end per `eventNumber`). Date MUST be shown as text by default using the same day-label rules as home history day section headers (`今天`, `昨天`, `M月D日`, `Y年M月D日` via `formatHistoryDaySectionLabel`). Tapping the date MUST open a bottom sheet with a Cupertino date wheel; tapping the time MUST open the existing hour/minute wheel sheet. Date and time controls for the same label MUST appear side-by-side in one row. The selectable date range MUST be from the baby's birth date (local calendar day, from `settingsBabyProvider`) through today (local calendar day), inclusive. For `eventNumber == 0`, when the user changes the start **calendar day** and an end time is set, if the new start day is after the end day, the client MUST set the end day to the start day while preserving the end's time-of-day. When the user changes the start **time-of-day** and the new start instant is after the end instant, the client MUST set the end to the new start instant. Saved `startTime` / `endTime` MUST remain Unix second timestamps. The client MUST NOT change create flows (`showHomeNumberEventSheet`, instant time/one submit).

历史编辑 Sheet 必须分别提供可编辑的**自然日**与**时分**滚轮；日期默认以与列表日期分块一致的文案展示；点击日期弹出日期滚轮 Sheet，点击时间弹出时分滚轮 Sheet；同一时刻标签下日期与时间必须并排。可选日期范围必须为宝宝生日（自然日）至今天（自然日）。`eventNumber == 0` 且已设结束时间时：用户仅改开始**自然日**且新开始日晚于结束日时，必须只把结束的日历日同步为开始日并**保留**原结束时/分；用户改开始**时分**且新开始时刻整体晚于结束时，必须把结束同步为新开始时刻。保存仍必须为 Unix 秒级时间戳。不得改动新建事件流程与 number 二级页 Sheet。

#### Scenario: eventNumber 为 0 修改开始日期

- **WHEN** 用户打开非 pending 的 `eventNumber == 0` 记录，点击开始时间的日期并选择新自然日后保存
- **THEN** 提交的 `startTime` MUST 为「新自然日 + 当前编辑时分」的 Unix 秒，且界面 MUST 并排展示开始日期与开始时分

#### Scenario: eventNumber 为 0 跨天开始与结束

- **WHEN** 用户将开始日期设为昨天、结束日期设为今天且结束时刻晚于开始时刻，并保存
- **THEN** 客户端 MUST 接受并分别提交对应的 `startTime` 与 `endTime` Unix 秒

#### Scenario: eventNumber 为 0 开始日晚于结束日仅对齐日期

- **WHEN** 用户在 `eventNumber == 0` 编辑 Sheet 中修改开始**日期**，且已设置结束时间，且新开始自然日晚于当前结束自然日
- **THEN** 客户端 MUST 将结束的日历日同步为开始日，且 MUST 保留结束的时/分不变

#### Scenario: eventNumber 为 0 开始时刻晚于结束时刻对齐时间

- **WHEN** 用户在 `eventNumber == 0` 编辑 Sheet 中修改开始**时分**，且已设置结束时间，且新开始时刻整体晚于当前结束时刻
- **THEN** 客户端 MUST 将结束时刻同步为新开始时刻

#### Scenario: eventNumber 为 1 修改结束日期

- **WHEN** 用户仅修改结束时间的日期或时分并保存
- **THEN** 客户端 MUST 按现网规则将 `startTime` 与 `endTime` 同步为同一时刻的 Unix 秒，且 MUST NOT 展示可编辑开始时间行

#### Scenario: eventNumber 大于 1 修改结束日期

- **WHEN** 用户修改结束时间的日期并保存
- **THEN** 提交的结束时刻 Unix 秒 MUST 反映新自然日与原编辑时分，且用量滚轮与备注行为 MUST 不变

#### Scenario: 日期超出可选范围

- **WHEN** 用户在日期滚轮 Sheet 中操作
- **THEN** 客户端 MUST NOT 允许选择早于宝宝生日或晚于今天的自然日

#### Scenario: pending 记录只读

- **WHEN** 用户打开 `pending:*` 记录
- **THEN** 日期与时间控件 MUST 不可编辑（与现网只读一致）
