## MODIFIED Requirements

### Requirement: Prediction row lastAt MUST fall back to cache on window miss

When building hot smart-prediction rows, `SmartPredictionRow.lastAt` MUST be `latestOccurrenceAtForRecords(windowRecords) ?? cache[root]`. A non-null value from either source MUST count as real `lastAt` for「上一次」copy and for forecast-on CTA / card-tap branches that gate on `lastAt == null`. The client MUST NOT treat cache miss + window miss as proof the event never occurred beyond showing「暂无」/supplement affordances already specified. 组行 `lastAt` MUST 为窗口最新 ?? 缓存；任一非空 MUST 视为真 lastAt 供文案与有无 lastAt 分支；两者皆无时保持既有「暂无」/补充流。

For **non-appointment** roots: when card `lastAt` comes only from tip/cache and `home∪range` cannot resolve a real `HistoryRecord`, the last-occurrence label MUST NOT open `showHomeHistoryEditSheet`. For **appointment** roots: last-occurrence tap edit MUST follow `appointment-event-client`（点按再不限窗 filter 后开 sheet），and MUST NOT be blocked solely because the record is absent from the near window. 非预约：仅缓存且近窗无真 record 时 MUST NOT 开编辑 sheet。预约：MUST 按预约能力点按再拉，不得仅因近窗缺失而禁止点按编辑。

#### Scenario: 窗口未命中用缓存展示

- **WHEN** 热态某根在 home∪range 无真记录，但该 `deviceNo` 缓存有该根时刻 T
- **THEN** 该卡 `lastAt` MUST 为 T，「上一次」MUST 展示 T 的本地可读文案（不得为「暂无」）

#### Scenario: 窗口命中优先于更旧缓存

- **WHEN** 窗口最新真发生为 T2，缓存为更早的 T1
- **THEN** 该卡 `lastAt` MUST 为 T2

#### Scenario: 非预约仅缓存时不开放编辑 Sheet

- **WHEN** 非预约卡上 `lastAt` 仅来自缓存且 home∪range 无法解析该根真 `HistoryRecord`
- **THEN** 「上一次」文案 MUST NOT 打开 `showHomeHistoryEditSheet`

#### Scenario: 预约仅近窗缺失仍可点按再拉编辑

- **WHEN** 预约卡展示上次发生且 home∪range 无法解析该根真 `HistoryRecord`
- **THEN** 客户端 MUST 仍允许点按上次行并按 `appointment-event-client` 再 filter 后尝试打开编辑 sheet
- **AND** MUST NOT 仅因近窗缺失而禁用点按
