## ADDED Requirements

### Requirement: Appointment card last-occurrence label MUST omit event-name prefix

On the smart prediction waterfall/compact card for an appointment root, when the last-occurrence row is shown, the client MUST render `{relative local time}[ · {history remark}]` and MUST NOT include the prefix `上一次{事件名}` (or equivalent that repeats the event name). Relative time formatting MUST match the existing prediction last-at helpers. Non-empty history remark MUST still be appended with ` · `. Non-appointment cards are out of scope for this requirement. 预约瀑布/compact 卡上次行 MUST 仅为相对时间与可选 ` · 备注`；MUST NOT 含「上一次{事件名}」前缀；非预约不在本需求范围。

#### Scenario: Appointment shows time without name prefix

- **WHEN** 热态预约卡展示上次发生且时间为「昨天 09:30」、remark 为空
- **THEN** 该行文案 MUST 为「昨天 09:30」
- **AND** MUST NOT 包含「上一次」或事件名

#### Scenario: Remark still appended

- **WHEN** 热态预约卡上次 history remark 为「带本子」
- **THEN** 文案 MUST 以 ` · 带本子` 追加在相对时间之后

### Requirement: Appointment last-occurrence tap MUST refetch then open edit sheet

When the user taps the last-occurrence row on a hot appointment prediction card that is showing last-occurrence data, the client MUST treat the tap as edit intent: it MUST fetch the latest real history record for that root via `GET /device/history/api/filter` with root-and-descendant `eventIds`, `limit=1`, and `ignoreTimeRange` true (same family as unbounded last display), and on success MUST open `showHomeHistoryEditSheet` with that record. The client MUST NOT require that the record already exist in the near-window `home∪range` sources. If the fetch returns empty or fails, the client MUST show an error affordance and MUST NOT open an empty edit sheet. Concurrent taps MUST be single-flight. 用户点按预约卡已展示的上次行时，客户端 MUST 再经不限窗 filter 取最近一条真记录并打开编辑 sheet；MUST NOT 要求近窗已有 record；失败 MUST 提示且 MUST NOT 开空 sheet；并发 MUST single-flight。

#### Scenario: Tap refetches outside near window

- **WHEN** 预约卡展示的上次来自不限窗 filter，且 home∪range 无该条
- **AND** 用户点按该上次行且 filter 成功返回一条 HistoryRecord
- **THEN** 客户端 MUST 打开 `showHomeHistoryEditSheet` 编辑该记录

#### Scenario: Tap fetch empty does not open sheet

- **WHEN** 用户点按预约卡上次行且 filter 返回空列表或失败
- **THEN** 客户端 MUST 提示失败或无可编辑记录
- **AND** MUST NOT 打开编辑 sheet
