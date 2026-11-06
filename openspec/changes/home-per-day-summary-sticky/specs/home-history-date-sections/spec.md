## MODIFIED Requirements

### Requirement: 按本地自然日分块展示

The home history list SHALL group records by local calendar day keyed by each record’s **`startTime`** (falling back with the same missing-start rules already used for start display, e.g. `createdAt`), and SHALL render a dedicated day section label row before each day's records (in scroll order appropriate for newest-at-bottom). 主页历史列表必须按**本地自然日**分组；**日分块键 MUST 为记录 `startTime` 所在本地自然日**（`startTime` 缺失时用既有开始时刻回退，不得用已结束计时的 `endTime` 作为分组日键）。每个自然日必须先展示**日期分块行**（如 `今天`、`昨天`、`3月5日`），再展示该日下的记录行；整体仍须满足**时间上最新记录在面板底部**的排序语义。本 Requirement **仅**约束喂养主页历史分组；MUST NOT 改变预测算法或其它 surface 对 `historyHomeDisplayInstant` / end 分桶的既有语义。

#### Scenario: 跨天记录

- **WHEN** 列表同时包含今天与昨天的记录（按 start 日键）
- **THEN** 用户必须能看到独立的「今天」「昨天」日期行，且各自下方仅显示属于该日的记录

#### Scenario: 最新仍在底部

- **WHEN** 主页完成加载且存在多条记录
- **THEN** 全局时间最新的一条记录必须仍锚定在历史区靠近主输入区的一侧（底部）

#### Scenario: 跨午夜已结束计时归开始日

- **WHEN** 一条 `eventNumber == 0` 且已设置 `endTime` 的记录，`startTime` 落在本地昨天、`endTime` 落在本地今天
- **THEN** 该记录 MUST 出现在「昨天」日块下，MUST NOT 仅因 end 在今天而分到「今天」

### Requirement: 日期行吸顶

The system SHALL pin the current day section header (day label and, when present, that day’s per-day summary chips) at the top edge of the history scroll viewport while the user scrolls within that day’s records, and the pinned header height SHALL follow the content height of that header. 用户在历史区内滚动时，当前可见日期区块的**日期分块头**（日期文案；若该日有按日汇总 chip 则含 chip）必须**吸顶**固定在历史列表可视区域上沿，直至滚入下一日期区块并由下一日头接替；吸顶高度 MUST 随该日头内容高度变化（见 `home-per-day-summary-sticky`），MUST NOT 在有多行 chip 时用旧固定单行日期高度裁切。

#### Scenario: 向上滚动查看昨天

- **WHEN** 用户从底部向上滚动，使昨天区块的记录进入可视区
- **THEN** 「昨天」（或对应日标签）必须吸顶显示，且其下记录行时间列仍为 `HH:mm`

#### Scenario: 昨天有汇总 chip 时吸顶含 chip

- **WHEN** 昨天分块吸顶且该日有有效汇总 chip
- **THEN** 吸顶区域 MUST 同时可见昨天日期文案与该日 chip（高度足以容纳）
