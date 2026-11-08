## MODIFIED Requirements

### Requirement: iOS client SHALL present Timing Live Activity separately and only from push

For in-progress timing on iOS, content MUST appear as `kind=timing` rows inside the unified `BabyLiveActivityAttributes` Live Activity defined by `unified-live-activity`, and MUST NOT use a separate `PredictTimingAttributes` ActivityConfiguration or per-historyId multi-slot Live Activities on the product path. When a timing item is rendered on the lock screen, the row MUST reuse the existing Timing row chrome: leading event logo from local `eventId` visuals, primary title equal to `eventName` without a「计时中」suffix (empty MUST fall back to a short label such as「事件」), optional subtitle「预计 HH:mm 结束」when `expectEndAt` is positive, and trailing system-driven elapsed timer from `startTime` via `Text(timerInterval:)` with `countsDown: false` (finite ~99h bound; seconds allowed). Push MUST NOT be required to carry logo/color. The product path MUST NOT locally `Activity.request` Timing; start/update/end MUST wait for twin unified Refresh. Multiple open timings MUST appear as multiple rows in one activity, not multiple activities.

iOS 进行中计时 MUST 作为统一 LA 的 `kind=timing` 行展示，MUST NOT 再使用独立 Timing Attributes 或多槽 Activity。锁屏行 MUST 复用既有 Timing 行样式（事件名、可选预计结束副行、右侧已计时）。MUST NOT 本地 request；多条进行中 MUST 同屏多行而非多条 Activity。

#### Scenario: Timing as list row

- **WHEN** 统一 ContentState `items` 含 `kind=timing` 且事件名为「睡眠」、有正 `startTime`
- **THEN** 锁屏 MUST 在列表中渲染该行：标题「睡眠」、右侧系统已计时，MUST NOT 拉起独立 Timing Activity

#### Scenario: Expect end subtitle preserved

- **WHEN** timing 项含有效正 `expectEndAt`（例如本地 14:30）
- **THEN** 该行标题下 MUST 仍展示「预计 14:30 结束」（无「约」、无超时后缀）

#### Scenario: No multi-slot activities

- **WHEN** 同时存在两条未闭合计时
- **THEN** 客户端 MUST 在同一统一 LA 的 `items` 中展示两行，MUST NOT 为每个 historyId 再请求/解码独立 Timing Live Activity

### Requirement: Timing lock screen SHALL show optional expect-end subtitle under the event name

When a timing list row is shown on the lock screen and the item provides a positive `expectEndAt` unix-seconds value, the client MUST show a secondary line directly under the event-name title with「预计 HH:mm 结束」. The client MUST NOT append「约」or overdue suffixes. When `expectEndAt` is missing/zero, the client MUST omit the subtitle and MUST NOT reserve empty vertical space. The trailing elapsed timer MUST remain on the right of that row. Dynamic Island MUST only show this timing chrome when the item is `items.first`. Decoding MUST tolerate older pushes that omit `expectEndAt`.

timing 列表行有正 `expectEndAt` 时 MUST 在标题下展示「预计 HH:mm 结束」；缺失 MUST 省略副行；已计时 MUST 留在该行右侧；仅当该条为 `items.first` 时 Island 才展示 Timing chrome。

#### Scenario: Subtitle on lock row

- **WHEN** timing 行 ContentState 含有效正 `expectEndAt`（本地 14:30）
- **THEN** 该行 MUST 显示「预计 14:30 结束」且右侧保留已计时

#### Scenario: Island only if first

- **WHEN** timing 项不是 `items.first`
- **THEN** Dynamic Island MUST NOT 被要求展示该条的预计结束副行或已计时
