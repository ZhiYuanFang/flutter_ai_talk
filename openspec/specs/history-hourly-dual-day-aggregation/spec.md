## ADDED Requirements

### Requirement: 先本地聚合后 API 刷新

The system MUST render hourly series from local history first, then refresh from the piece API when available. 系统 MUST **先**使用 `homeHistoryProvider`（或等价）已加载的 `HistoryRecord` 列表聚合今/昨 24 桶并立即绘图，**再**异步请求 `GET /device/history/api/piece`（昨日 0:00 至今日 23:59:59 本地）刷新两条序列。

#### Scenario: 打开 Sheet 即时本地曲线

- **WHEN** 用户打开趋势 Sheet 且本地已有部分历史
- **THEN** 系统 MUST 在不等待网络的情况下先展示基于本地的折线

#### Scenario: API 成功后更新

- **WHEN** piece 请求成功返回
- **THEN** 系统 MUST 用 API 映射结果替换或更新今/昨序列并重绘图表

#### Scenario: API 失败保留本地

- **WHEN** piece 请求失败
- **THEN** 系统 MUST 保留本地曲线并 MUST NOT 清空已为本地数据绘制的图表

### Requirement: 未结束计时不计入小时桶

The system MUST exclude active timing records from hourly aggregation using the same rule as today totals. 进行中计时（`eventNumber==0` 且 `endTime` 按 `historyInstantUnset` 未设置）MUST NOT 计入小时分桶，规则 MUST 与 `countsTowardTodayTotal` 一致。

#### Scenario: 进行中计时被排除

- **WHEN** 某事件存在未结束计时记录
- **THEN** 该记录 MUST NOT 增加任何小时桶的数值

### Requirement: 24 整点桶与趋势中心度量一致

The system SHALL produce 24 hourly buckets per local calendar day using the same metric semantics as the trends center. 每个本地自然日 MUST 输出 **24** 个整点桶（0–23 时）。桶内数值 MUST 使用 `historyRecordMetric`（计时→小时，计数→次数）；分桶键 MUST 为记录 `startTime` 所在整点，同小时多条 MUST **相加**（与 `fillTrendBucketsHourlyToday` 语义一致）。

#### Scenario: 固定 24 桶含未来小时

- **WHEN** 聚合「今日」且当前时间为 15:30
- **THEN** 系统 MUST 仍输出 0–23 时共 24 桶，16–23 时无记录则为 0

#### Scenario: 昨日完整 24 桶

- **WHEN** 聚合「昨日」
- **THEN** 系统 MUST 输出昨日 0:00–23:00 共 24 桶

### Requirement: piece 映射与事件过滤

The system SHALL map piece API records to trend points and filter by event id before bucketing. 从 piece 返回的每条记录 MUST 经 `trendPointFromPieceJson`（或等价）映射；MUST 仅保留与所选 `eventId` 匹配的记录后再分日、分桶。

#### Scenario: 单次请求覆盖两日

- **WHEN** 客户端请求 piece 且 `startTime`/`endTime` 覆盖昨日 0:00 至今日 23:59:59
- **THEN** 客户端 MUST 能在一次响应中拆分出今、昨两日序列而无需强制两次请求（实现允许两次请求，但规格推荐单次）
