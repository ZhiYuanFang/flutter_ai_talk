## ADDED Requirements

### Requirement: Feeding day-summary chart open MUST report usage asynchronously

When the user taps a feeding home per-day summary chip and the client opens the single-day `TrendDayDetailChart` sheet, the client SHALL report a stable usage event (recommended `featureId=feeding_day_summary_chart_open`) with a Chinese `description` that indicates opening the day summary chart (MAY include the event display name; MUST NOT contain `|`). The report MUST be fire-and-forget and MUST NOT block sheet open; failures MUST be silent per existing client-usage rules. Unauthenticated sessions MUST NOT report.

用户点击喂养主页按日汇总 chip 并打开单日汇总图 Sheet 时，客户端 MUST 异步上报稳定 `featureId`（建议 `feeding_day_summary_chart_open`）与表明「打开当日汇总图」的中文 `description`；MUST NOT 阻塞 Sheet；失败静默；未登录不得报。

#### Scenario: 打开当日汇总图上报

- **WHEN** 已登录用户点击按日汇总 chip 并打开 `TrendDayDetailChart` Sheet
- **THEN** 客户端 MUST 调用 `POST /device/app/api/client-usage/report`（经既有 reporter），且 MUST NOT `await` 该调用作为打开 Sheet 的前置条件

#### Scenario: 未打开 Sheet 不报本事件

- **WHEN** 用户交互未导致打开该单日汇总图 Sheet
- **THEN** 客户端 MUST NOT 上报本条 `feeding_day_summary_chart_open`（或等价）事件
