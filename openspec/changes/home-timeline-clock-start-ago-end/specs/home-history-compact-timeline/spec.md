## MODIFIED Requirements

### Requirement: 记录行时间列仅显示时分

The system MUST show only `HH:mm` in the home history timeline row time column; day-relative text MUST NOT appear in that column. The clock instant for that column SHALL be the record’s **start** instant (same missing-start fallback as the home day key, e.g. `createdAt`), and MUST NOT use a finished timing record’s `endTime` solely for this column. 主页历史**记录行**左侧时间列必须仅显示 **24 小时制 `HH:mm`**（如 `20:00`）；**不得**在该列出现 `昨天`、`3月5日` 等与日期合并的文案；该列时刻 MUST 取开始时刻（与日键同源），已结束计时 MUST NOT 因结束时刻而改写左列钟点。

#### Scenario: 昨天记录

- **WHEN** 某条记录按开始时刻属于昨天且开始时分为 20:00
- **THEN** 日期分块行必须显示「昨天」（或等价日标签），且该记录行时间列必须显示 `20:00` 而非 `昨天20:00`

#### Scenario: 已结束计时左列用开始时刻

- **WHEN** 一条 `eventNumber == 0` 且已设置 `endTime` 的记录，`startTime` 本地为 `22:10`、`endTime` 本地为次日 `07:05`
- **THEN** 该行左列 MUST 显示 `22:10`，MUST NOT 显示 `07:05`

## ADDED Requirements

### Requirement: 左列钟点与 display instant 解耦

The home timeline left-column clock instant SHALL be resolved independently from `historyHomeDisplayInstant`. Changing the left-column clock MUST NOT by itself change relative-ago anchoring or within-day sort keys that continue to use `historyHomeDisplayInstant`. 左列时钟 MUST 与 `historyHomeDisplayInstant` 解耦；仅改左列 MUST NOT 连带改变仍依赖 display instant 的相对 ago 与日内排序语义。

#### Scenario: 实现拆分

- **WHEN** 客户端渲染主页历史时间轴行
- **THEN** `timeLabel` MUST 来自开始时刻 helper（或与日键等价），且 `historyHomeDisplayInstant` MUST 仍可供 ago / 排序使用且对已结束计时保持 end 语义
