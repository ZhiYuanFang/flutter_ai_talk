## ADDED Requirements

### Requirement: 按本地自然日分块展示

The home history list SHALL group records by local calendar day and SHALL render a dedicated day section label row before each day's records (in scroll order appropriate for newest-at-bottom). 主页历史列表必须按**本地自然日**分组；每个自然日必须先展示**日期分块行**（如 `今天`、`昨天`、`3月5日`），再展示该日下的记录行；整体仍须满足**时间上最新记录在面板底部**的排序语义。

#### Scenario: 跨天记录

- **WHEN** 列表同时包含今天与昨天的记录
- **THEN** 用户必须能看到独立的「今天」「昨天」日期行，且各自下方仅显示属于该日的记录

#### Scenario: 最新仍在底部

- **WHEN** 主页完成加载且存在多条记录
- **THEN** 全局时间最新的一条记录必须仍锚定在历史区靠近主输入区的一侧（底部）

### Requirement: 记录行时间列仅显示时分

The system MUST show only `HH:mm` in the home history timeline row time column; day-relative text MUST NOT appear in that column. 主页历史**记录行**左侧时间列必须仅显示 **24 小时制 `HH:mm`**（如 `20:00`）；**不得**在该列出现 `昨天`、`3月5日` 等与日期合并的文案。

#### Scenario: 昨天记录

- **WHEN** 某条记录属于昨天且展示时刻为 20:00
- **THEN** 日期分块行必须显示「昨天」（或等价日标签），且该记录行时间列必须显示 `20:00` 而非 `昨天20:00`

### Requirement: 日期行吸顶

The system SHALL pin the current day section label at the top edge of the history scroll viewport while the user scrolls within that day’s records. 用户在历史区内滚动时，当前可见日期区块的**日期分块行**必须**吸顶**固定在历史列表可视区域上沿，直至滚入下一日期区块并由下一日期行接替。

#### Scenario: 向上滚动查看昨天

- **WHEN** 用户从底部向上滚动，使昨天区块的记录进入可视区
- **THEN** 「昨天」（或对应日标签）必须吸顶显示，且其下记录行时间列仍为 `HH:mm`

### Requirement: 日期标签文案规则

Day section labels SHALL follow the same calendar-day semantics as the existing home history instant formatter for the date portion. 日期分块行文案必须遵循与现有主页时间展示一致的本地自然日规则：`今天`、`昨天`、同年 `M月D日`、跨年 `Y年M月D日`；不得包含时分。

#### Scenario: 今日区块

- **WHEN** 记录属于当前本地自然日
- **THEN** 日期分块行必须显示「今天」
